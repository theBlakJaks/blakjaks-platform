#!/usr/bin/env python3
"""
Seed staging environment with load test fixtures.

Run before executing k6 load tests to ensure required test data exists:
  - Load test user (loadtest@blakjaks.com)
  - A batch of test QR codes
  - A pending_choice comp for the double-spend test

Usage:
    python scripts/seed_staging_loadtest.py \\
        --url https://staging-api.blakjaks.com \\
        --admin-token YOUR_ADMIN_JWT
"""
import argparse
import sys

try:
    import httpx
except ImportError:
    print("Error: httpx not installed. Run: pip install httpx")
    sys.exit(1)


def main() -> None:
    parser = argparse.ArgumentParser(description="Seed staging load test fixtures")
    parser.add_argument("--url", default="https://staging-api.blakjaks.com",
                        help="Staging API base URL")
    parser.add_argument("--admin-token", required=True,
                        help="Admin JWT for seeding (obtain via admin login)")
    args = parser.parse_args()

    base = args.url.rstrip("/")
    admin_headers = {
        "Authorization": f"Bearer {args.admin_token}",
        "Content-Type": "application/json",
    }

    print(f"Seeding {base} …\n")

    # ── 1. Create load test user ──────────────────────────────────────────────
    print("1. Creating load test user …")
    r = httpx.post(
        f"{base}/auth/signup",
        json={
            "name": "Load Test User",
            "email": "loadtest@blakjaks.com",
            "password": "LoadTest123!",
            "date_of_birth": "1990-01-01",
        },
        timeout=30,
    )
    if r.status_code in (200, 201):
        print("   ✅ User created: loadtest@blakjaks.com")
    elif r.status_code == 409:
        print("   ℹ️  User already exists — skipping")
    else:
        print(f"   ⚠️  Unexpected status {r.status_code}: {r.text}")

    # ── 2. Login as load test user ────────────────────────────────────────────
    print("\n2. Logging in as load test user …")
    r = httpx.post(
        f"{base}/auth/login",
        json={"email": "loadtest@blakjaks.com", "password": "LoadTest123!"},
        timeout=30,
    )
    if r.status_code != 200:
        print(f"   ❌ Login failed ({r.status_code}): {r.text}")
        sys.exit(1)
    user_token = r.json()["access_token"]
    print("   ✅ Login successful")

    # ── 3. Create QR code batch via admin endpoint ────────────────────────────
    print("\n3. Creating test QR code batch …")
    r = httpx.post(
        f"{base}/admin/qr-codes/batch",
        headers=admin_headers,
        json={
            "batch_name": "load-test-batch",
            "quantity": 10,
            "product_name": "Load Test Product",
        },
        timeout=30,
    )
    if r.status_code in (200, 201):
        data = r.json()
        codes = data.get("codes", [])
        if codes:
            first_code = codes[0].get("code") or codes[0].get("unique_id") or codes[0]
            print(f"   ✅ QR batch created ({len(codes)} codes)")
            print(f"\n   ➡️  Set K6_TEST_QR_CODE={first_code}")
        else:
            print(f"   ⚠️  Batch created but no codes in response: {data}")
    elif r.status_code == 409:
        print("   ℹ️  Batch already exists — check existing QR codes")
    else:
        print(f"   ⚠️  QR batch status {r.status_code}: {r.text}")

    # ── 4. Seed pending_choice comp for withdrawal safety test ────────────────
    print("\n4. Seeding pending_choice comp for withdrawal safety test …")
    r = httpx.post(
        f"{base}/admin/users/seed-comp",
        headers=admin_headers,
        json={
            "email": "loadtest@blakjaks.com",
            "amount": 10.00,
            "status": "pending_choice",
        },
        timeout=30,
    )
    if r.status_code in (200, 201):
        data = r.json()
        comp_id = data.get("comp_id") or data.get("id")
        print(f"   ✅ Comp seeded (amount: $10.00, status: pending_choice)")
        if comp_id:
            print(f"\n   ➡️  Set K6_TEST_COMP_ID={comp_id}")
        else:
            print(f"   ⚠️  No comp_id in response: {data}")
    else:
        print(f"   ⚠️  Seed comp status {r.status_code}: {r.text}")

    # ── Summary ───────────────────────────────────────────────────────────────
    print("\n" + "─" * 60)
    print("Seeding complete. Before running k6, set:")
    print()
    print("  export K6_TEST_EMAIL=loadtest@blakjaks.com")
    print("  export K6_TEST_PASSWORD=LoadTest123!")
    print("  export K6_TEST_QR_CODE=<value from step 3 above>")
    print("  export K6_TEST_COMP_ID=<value from step 4 above>")
    print()
    print("Then run:")
    print("  k6 run -e K6_BASE_URL=https://staging-api.blakjaks.com \\")
    print("         -e K6_TEST_EMAIL=$K6_TEST_EMAIL \\")
    print("         -e K6_TEST_PASSWORD=$K6_TEST_PASSWORD \\")
    print("         -e K6_TEST_QR_CODE=$K6_TEST_QR_CODE \\")
    print("         load-tests/scan_burst.js")


if __name__ == "__main__":
    main()
