/**
 * Scan Burst Load Test
 * Simulates high-volume QR scan submissions — triggers comp awards, milestone checks,
 * affiliate matching, and WebSocket broadcasts in a single call.
 *
 * Thresholds:
 *   p(95) < 500ms | p(99) < 1000ms | error rate < 1%
 *
 * Required env vars:
 *   K6_BASE_URL, K6_TEST_EMAIL, K6_TEST_PASSWORD, K6_TEST_QR_CODE
 */
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Trend } from 'k6/metrics';

const BASE_URL = __ENV.K6_BASE_URL || 'https://staging-api.blakjaks.com';

const rateLimitedCount = new Counter('rate_limited_scan_responses');
const scanSuccessCount = new Counter('scan_success_responses');

export const options = {
  stages: [
    { duration: '30s', target: 100 },
    { duration: '60s', target: 100 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'],
    http_req_failed: ['rate<0.01'],
  },
};

export function setup() {
  const res = http.post(
    `${BASE_URL}/auth/login`,
    JSON.stringify({
      email: __ENV.K6_TEST_EMAIL,
      password: __ENV.K6_TEST_PASSWORD,
    }),
    { headers: { 'Content-Type': 'application/json' } }
  );

  check(res, { 'login successful': (r) => r.status === 200 });

  const token = res.json('access_token');
  if (!token) {
    throw new Error(`Setup failed: login returned ${res.status} — ${res.body}`);
  }
  return { token };
}

export default function (data) {
  const headers = {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${data.token}`,
  };

  const res = http.post(
    `${BASE_URL}/scan/submit`,
    JSON.stringify({ qr_code: __ENV.K6_TEST_QR_CODE }),
    { headers }
  );

  const ok = check(res, {
    'scan: status 200 or 429': (r) => r.status === 200 || r.status === 429,
    'scan: no 5xx': (r) => r.status < 500,
  });

  if (res.status === 200) {
    check(res, {
      'scan: has scan_id': (r) => r.json('scan_id') !== undefined,
      'scan: has comp_earned': (r) => r.json('comp_earned') !== undefined,
      'scan: has tier': (r) => r.json('tier') !== undefined,
    });
    scanSuccessCount.add(1);
  } else if (res.status === 429) {
    rateLimitedCount.add(1);
  }

  sleep(0.5);
}

export function teardown(data) {
  // Double-spend safety check: verify comp_balance is non-negative
  const headers = {
    Authorization: `Bearer ${data.token}`,
  };
  const res = http.get(`${BASE_URL}/users/me/wallet`, { headers });
  const passed = check(res, {
    'double-spend check: wallet reachable': (r) => r.status === 200,
    'double-spend check: comp_balance non-negative': (r) => {
      const balance = r.json('comp_balance');
      if (balance < 0) {
        console.error(`DOUBLE_SPEND_DETECTED: comp_balance = ${balance}`);
      }
      return balance >= 0;
    },
  });
  if (!passed) {
    console.error('CRITICAL: Double-spend safety check failed — review wallet_service.py locking');
  } else {
    console.log(`Double-spend check passed. comp_balance = ${res.json('comp_balance')}`);
  }
}
