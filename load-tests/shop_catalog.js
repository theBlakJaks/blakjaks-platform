/**
 * Shop Catalog Load Test
 * Tests product listing, cart add, and cart cleanup at 300 VUs.
 * Shop is accessed by all users prior to checkout.
 *
 * Thresholds:
 *   p(95) < 200ms | error rate < 1%
 *
 * Required env vars:
 *   K6_BASE_URL, K6_TEST_EMAIL, K6_TEST_PASSWORD
 */
import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = __ENV.K6_BASE_URL || 'https://staging-api.blakjaks.com';

export const options = {
  stages: [
    { duration: '15s', target: 300 },
    { duration: '45s', target: 300 },
    { duration: '15s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<200'],
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
  check(res, { 'shop setup: login ok': (r) => r.status === 200 });
  const token = res.json('access_token');
  if (!token) throw new Error(`Shop setup login failed: ${res.status}`);
  return { token };
}

export default function (data) {
  const headers = {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${data.token}`,
  };

  // 1. Browse products
  const productsRes = http.get(
    `${BASE_URL}/products?category=nicotine&limit=20`,
    { headers }
  );
  check(productsRes, {
    'shop: products status 200': (r) => r.status === 200,
    'shop: products has items': (r) => {
      const body = r.json();
      return body && (body.items || body.products || []).length > 0;
    },
  });

  // Extract first product ID
  const body = productsRes.json();
  const products = body.items || body.products || [];
  if (products.length === 0) {
    console.warn('No products returned — skipping cart steps');
    sleep(2);
    return;
  }
  const productId = products[0].id;

  // 2. Add to cart
  const addRes = http.post(
    `${BASE_URL}/cart/items`,
    JSON.stringify({ product_id: productId, quantity: 1 }),
    { headers }
  );
  check(addRes, {
    'shop: add to cart 200 or 201': (r) => r.status === 200 || r.status === 201,
  });

  // 3. View cart
  const cartRes = http.get(`${BASE_URL}/cart`, { headers });
  check(cartRes, {
    'shop: cart status 200': (r) => r.status === 200,
    'shop: cart total > 0': (r) => {
      const cart = r.json();
      return cart && (cart.total || cart.subtotal || 0) > 0;
    },
  });

  // 4. Clean up — remove from cart
  http.del(
    `${BASE_URL}/cart/items/${productId}`,
    null,
    { headers }
  );

  sleep(2);
}
