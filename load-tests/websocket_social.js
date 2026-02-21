/**
 * WebSocket Social Hub Load Test
 * Simulates 1,000 concurrent WebSocket connections to the social hub.
 * Platform spec requires 250K concurrent at scale — 1K on staging validates
 * the connection handling pattern.
 *
 * Thresholds:
 *   ws_connecting p(95) < 1000ms | sessions stay open 60s+ | messages received
 *
 * Required env vars:
 *   K6_BASE_URL, K6_BASE_URL_WS, K6_TEST_EMAIL, K6_TEST_PASSWORD
 */
import http from 'k6/http';
import ws from 'k6/ws';
import { check, sleep } from 'k6';
import { Counter, Trend } from 'k6/metrics';

const BASE_URL = __ENV.K6_BASE_URL || 'https://staging-api.blakjaks.com';
const BASE_URL_WS = __ENV.K6_BASE_URL_WS || 'wss://staging-api.blakjaks.com';

const wsMessagesReceived = new Counter('ws_msgs_received');
const wsConnectErrors = new Counter('ws_connect_errors');
const wsSessionDuration = new Trend('ws_session_duration', true);

export const options = {
  stages: [
    { duration: '30s', target: 1000 },
    { duration: '90s', target: 1000 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    ws_connecting_duration: ['p(95)<1000'],
    ws_msgs_received: ['count>0'],
    ws_session_duration: ['p(95)>60000'],
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

  check(res, { 'ws setup: login ok': (r) => r.status === 200 });
  const token = res.json('access_token');
  if (!token) throw new Error(`WS setup login failed: ${res.status}`);
  return { token };
}

export default function (data) {
  const url = `${BASE_URL_WS}/social`;
  const params = {
    headers: { Authorization: `Bearer ${data.token}` },
  };

  const sessionStart = Date.now();

  const res = ws.connect(url, params, function (socket) {
    socket.on('open', () => {
      socket.send(JSON.stringify({ event: 'subscribe', channel: 'general' }));
    });

    socket.on('message', (msg) => {
      wsMessagesReceived.add(1);
      try {
        const parsed = JSON.parse(msg);
        check(parsed, {
          'ws: message has type field': (m) => m.type !== undefined,
        });
      } catch (_) {
        // Non-JSON message — ignore
      }
    });

    socket.on('error', (e) => {
      wsConnectErrors.add(1);
      console.error(`WS error: ${e.error()}`);
    });

    socket.on('close', (code) => {
      check({ code }, {
        'ws: normal closure (1000)': (c) => c.code === 1000,
      });
    });

    // Hold connection open for 90 seconds
    socket.setTimeout(() => socket.close(), 90000);
  });

  const duration = Date.now() - sessionStart;
  wsSessionDuration.add(duration);

  check(res, {
    'ws: connection established': (r) => r && r.status === 101,
  });
}
