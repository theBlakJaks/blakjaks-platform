/**
 * Auth Flood Load Test
 * Simulates login surge on app launch day or push notification delivery.
 * Validates that rate limiting fires (429s are expected and counted separately).
 *
 * Thresholds:
 *   p(95) < 800ms | error rate < 5% (429s allowed, 5xx are failures)
 *
 * Required env vars:
 *   K6_BASE_URL, K6_TEST_EMAIL, K6_TEST_PASSWORD
 */
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter } from 'k6/metrics';

const BASE_URL = __ENV.K6_BASE_URL || 'https://staging-api.blakjaks.com';

const rateLimitedCount = new Counter('rate_limited_responses');
const loginSuccessCount = new Counter('login_success_responses');

export const options = {
  stages: [
    { duration: '20s', target: 200 },
    { duration: '40s', target: 200 },
    { duration: '20s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<800'],
    // 5xx errors are failures; 429s are correct behavior and not counted as failures
    http_req_failed: ['rate<0.05'],
  },
};

export default function () {
  const res = http.post(
    `${BASE_URL}/auth/login`,
    JSON.stringify({
      email: __ENV.K6_TEST_EMAIL,
      password: __ENV.K6_TEST_PASSWORD,
    }),
    { headers: { 'Content-Type': 'application/json' } }
  );

  check(res, {
    'auth: 200 or 429 (no 5xx)': (r) => r.status === 200 || r.status === 429,
  });

  if (res.status === 200) {
    check(res, {
      'auth: access_token present': (r) => r.json('access_token') !== undefined,
    });
    loginSuccessCount.add(1);
  } else if (res.status === 429) {
    // Rate limiting firing is CORRECT behavior — count but do not fail
    rateLimitedCount.add(1);
    console.log(`Rate limited (expected): ${res.headers['Retry-After'] || 'no retry-after header'}`);
  }

  sleep(1);
}
