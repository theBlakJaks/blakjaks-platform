/**
 * Withdrawal Safety / Double-Spend Test
 * NOT a load test — a correctness test. Fires 50 concurrent withdrawal requests
 * for the same user to verify SELECT FOR UPDATE prevents double-crediting.
 *
 * Thresholds:
 *   no 5xx errors | 98%+ of balance checks pass
 *
 * Required env vars:
 *   K6_BASE_URL, K6_TEST_EMAIL, K6_TEST_PASSWORD, K6_TEST_COMP_ID
 */
import http from 'k6/http';
import { check } from 'k6';
import { Counter } from 'k6/metrics';

const BASE_URL = __ENV.K6_BASE_URL || 'https://staging-api.blakjaks.com';

const doubleSpendDetected = new Counter('double_spend_detected');

export const options = {
  // Spike all 50 VUs instantly — no ramp, maximum concurrency
  stages: [
    { duration: '1s', target: 50 },
    { duration: '30s', target: 50 },
    { duration: '1s', target: 0 },
  ],
  iterations: 50,
  vus: 50,
  thresholds: {
    http_req_failed: ['rate==0'],
    checks: ['rate>0.98'],
    double_spend_detected: ['count==0'],
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
  check(res, { 'withdrawal setup: login ok': (r) => r.status === 200 });
  const token = res.json('access_token');
  if (!token) throw new Error(`Withdrawal setup login failed: ${res.status}`);

  // Record balance before test
  const walletRes = http.get(`${BASE_URL}/users/me/wallet`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  const balanceBefore = walletRes.json('comp_balance');
  console.log(`Balance before concurrent requests: ${balanceBefore}`);

  return { token, balanceBefore };
}

export default function (data) {
  const headers = {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${data.token}`,
  };

  // All 50 VUs fire this simultaneously
  const res = http.post(
    `${BASE_URL}/wallet/comp-payout-choice`,
    JSON.stringify({
      comp_id: __ENV.K6_TEST_COMP_ID,
      method: 'later',
    }),
    { headers }
  );

  check(res, {
    'withdrawal: no 5xx': (r) => r.status < 500,
    'withdrawal: 200 or 409 (conflict acceptable)': (r) =>
      r.status === 200 || r.status === 409,
  });
}

export function teardown(data) {
  const headers = { Authorization: `Bearer ${data.token}` };

  // Single-VU verification: wallet should reflect exactly one credit, not 50
  const walletRes = http.get(`${BASE_URL}/users/me/wallet`, { headers });

  check(walletRes, {
    'double-spend: wallet reachable': (r) => r.status === 200,
  });

  const balanceAfter = walletRes.json('comp_balance');
  const balanceBefore = data.balanceBefore;

  console.log(`Balance before: ${balanceBefore} | Balance after: ${balanceAfter}`);

  // comp_balance should not have increased by more than one comp worth
  // (exact amount depends on comp value — check it's not 50x)
  const delta = balanceAfter - balanceBefore;
  const suspiciousThreshold = 5.0; // if delta > $5 from one comp, something is wrong

  const passed = check({ delta }, {
    'double-spend: balance delta is sane (not 50x credited)': (d) => {
      if (d.delta > suspiciousThreshold) {
        console.error(
          `DOUBLE_SPEND_DETECTED: balance increased by ${d.delta} — expected < ${suspiciousThreshold}`
        );
        doubleSpendDetected.add(1);
        return false;
      }
      return true;
    },
  });

  if (passed) {
    console.log('Withdrawal safety check PASSED — no double-spend detected.');
  }
}
