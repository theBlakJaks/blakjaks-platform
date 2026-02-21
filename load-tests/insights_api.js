/**
 * Insights API Load Test
 * Simulates app polling behavior — the dashboard refreshes every 5s per Platform spec.
 * Tests all 5 insights endpoints concurrently at 500 VUs.
 *
 * Thresholds:
 *   p(95) < 300ms | error rate < 1%
 *
 * Required env vars:
 *   K6_BASE_URL, K6_TEST_EMAIL, K6_TEST_PASSWORD
 */
import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = __ENV.K6_BASE_URL || 'https://staging-api.blakjaks.com';

const ENDPOINTS = [
  '/insights/overview',
  '/insights/treasury',
  '/insights/systems',
  '/insights/comps',
  '/insights/partners',
];

export const options = {
  stages: [
    { duration: '10s', target: 500 },
    { duration: '50s', target: 500 },
    { duration: '20s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<300'],
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
  check(res, { 'insights setup: login ok': (r) => r.status === 200 });
  const token = res.json('access_token');
  if (!token) throw new Error(`Insights setup login failed: ${res.status}`);
  return { token };
}

export default function (data) {
  const headers = { Authorization: `Bearer ${data.token}` };

  for (const endpoint of ENDPOINTS) {
    const res = http.get(`${BASE_URL}${endpoint}`, { headers });
    check(res, {
      [`${endpoint}: status 200`]: (r) => r.status === 200,
      [`${endpoint}: non-empty body`]: (r) => r.body && r.body.length > 2,
    });
  }

  // Mimic app 5-second polling interval
  sleep(5);
}
