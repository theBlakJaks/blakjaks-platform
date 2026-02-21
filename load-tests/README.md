# BlakJaks Load Tests

k6-based load testing suite for the BlakJaks staging environment.

## Prerequisites

**macOS:**
```bash
brew install k6
```

**Docker:**
```bash
docker pull grafana/k6
```

**Ubuntu/Debian (CI):**
```bash
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg \
  --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" \
  | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update && sudo apt-get install k6
```

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `K6_BASE_URL` | No | `https://staging-api.blakjaks.com` | Staging API base URL (no trailing slash) |
| `K6_BASE_URL_WS` | No | `wss://staging-api.blakjaks.com` | Staging WebSocket URL |
| `K6_TEST_EMAIL` | Yes | — | Load test user email (seeded via seed script) |
| `K6_TEST_PASSWORD` | Yes | — | Load test user password |
| `K6_TEST_QR_CODE` | Yes (scan test) | — | Valid QR code value seeded in staging |
| `K6_TEST_COMP_ID` | Yes (withdrawal test) | — | `pending_choice` comp UUID seeded in staging |

## Seeding Test Data

Before running the scan burst or withdrawal safety tests, seed the required fixtures:

```bash
python scripts/seed_staging_loadtest.py \
  --url https://staging-api.blakjaks.com \
  --admin-token YOUR_ADMIN_JWT
```

This creates:
- Load test user `loadtest@blakjaks.com`
- A batch of test QR codes (copy the first code value → `K6_TEST_QR_CODE`)
- A `pending_choice` comp for the double-spend test (copy comp UUID → `K6_TEST_COMP_ID`)

## Running Tests

**Single test:**
```bash
k6 run \
  -e K6_BASE_URL=https://staging-api.blakjaks.com \
  -e K6_TEST_EMAIL=loadtest@blakjaks.com \
  -e K6_TEST_PASSWORD=LoadTest123! \
  -e K6_TEST_QR_CODE=BJ-TEST-QR-001 \
  load-tests/scan_burst.js
```

**All tests sequentially:**
```bash
export K6_BASE_URL=https://staging-api.blakjaks.com
export K6_TEST_EMAIL=loadtest@blakjaks.com
export K6_TEST_PASSWORD=LoadTest123!
export K6_TEST_QR_CODE=BJ-TEST-QR-001
export K6_TEST_COMP_ID=<comp-uuid-from-seed-script>

for f in load-tests/scan_burst.js load-tests/auth_flood.js load-tests/insights_api.js load-tests/shop_catalog.js load-tests/withdrawal_safety.js; do
  echo "=== Running $f ==="
  k6 run -e K6_BASE_URL=$K6_BASE_URL -e K6_TEST_EMAIL=$K6_TEST_EMAIL \
    -e K6_TEST_PASSWORD=$K6_TEST_PASSWORD -e K6_TEST_QR_CODE=$K6_TEST_QR_CODE \
    -e K6_TEST_COMP_ID=$K6_TEST_COMP_ID "$f"
done
```

**WebSocket test** (separate due to wss:// URL):
```bash
k6 run \
  -e K6_BASE_URL=https://staging-api.blakjaks.com \
  -e K6_BASE_URL_WS=wss://staging-api.blakjaks.com \
  -e K6_TEST_EMAIL=loadtest@blakjaks.com \
  -e K6_TEST_PASSWORD=LoadTest123! \
  load-tests/websocket_social.js
```

**With JSON output for Grafana:**
```bash
k6 run --out json=results/scan_burst.json load-tests/scan_burst.js
```

## Test Descriptions & Thresholds

| File | VUs | Duration | p(95) target | Pass criteria |
|------|-----|----------|-------------|---------------|
| `scan_burst.js` | 100 | 2 min | < 500ms | < 1% error, no negative comp_balance |
| `auth_flood.js` | 200 | 80s | < 800ms | < 5% error (429s are expected and correct) |
| `websocket_social.js` | 1,000 | 2.5 min | connect < 1s | Sessions stay open 60s+, messages received |
| `insights_api.js` | 500 | 80s | < 300ms | < 1% error |
| `withdrawal_safety.js` | 50 | instant burst | — | 0 double-spends, 0 5xx |
| `shop_catalog.js` | 300 | 75s | < 200ms | < 1% error |

## Interpreting Results

- ✅ **All thresholds green** — load test passes
- ⚠️ **`rate_limited_responses` counter firing** in `auth_flood` — this is **correct behavior**, not a failure. Confirms slowapi rate limiting is working.
- ❌ **`DOUBLE_SPEND_DETECTED`** in `withdrawal_safety` — critical bug in `wallet_service.py` locking. Block the deploy immediately.
- ❌ **Any `5xx` in `withdrawal_safety`** — the `http_req_failed: rate==0` threshold will hard-fail.

## CI Integration

`scan_burst.js` and `withdrawal_safety.js` run automatically after every `staging` branch deploy. See `.github/workflows/deploy.yml` → `load-test` job.

**GitHub Secrets required for CI:**

| Secret | Value |
|--------|-------|
| `STAGING_API_URL` | `https://staging-api.blakjaks.com` |
| `LOAD_TEST_EMAIL` | `loadtest@blakjaks.com` |
| `LOAD_TEST_PASSWORD` | `LoadTest123!` |
| `LOAD_TEST_QR_CODE` | QR code value from seed script |
| `LOAD_TEST_COMP_ID` | Comp UUID from seed script |
