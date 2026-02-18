import uuid

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.product import Product
from app.models.qr_code import QRCode
from app.models.user import User
from tests.conftest import seed_tiers

pytestmark = pytest.mark.asyncio


# ── Helpers ──────────────────────────────────────────────────────────


async def create_product(db: AsyncSession) -> Product:
    product = Product(name="TestPack", price=5.00, stock=100)
    db.add(product)
    await db.commit()
    await db.refresh(product)
    return product


async def create_qr(db: AsyncSession, product: Product, code_suffix: str = None) -> QRCode:
    suffix = code_suffix or uuid.uuid4().hex[:12].upper()
    qr = QRCode(
        product_code="TESTPACK",
        unique_id=f"BLAKJAKS-TESTPACK-{suffix}",
        product_id=product.id,
    )
    db.add(qr)
    await db.commit()
    await db.refresh(qr)
    return qr


async def make_admin(db: AsyncSession, user_id: str) -> str:
    """Promote user to admin and return new access token."""
    from sqlalchemy import select, update

    await db.execute(
        update(User).where(User.id == uuid.UUID(user_id)).values(is_admin=True)
    )
    await db.commit()
    return create_access_token(uuid.UUID(user_id))


# ── POST /scans/submit ──────────────────────────────────────────────


async def test_submit_valid_qr(client: AsyncClient, auth_headers, registered_user, db: AsyncSession):
    await seed_tiers(db)
    product = await create_product(db)
    qr = await create_qr(db, product, "ABC123DEF456")

    resp = await client.post(
        "/api/scans/submit",
        headers=auth_headers,
        json={"qr_code": "BLAKJAKS-TESTPACK-ABC123DEF456"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["success"] is True
    assert data["product_name"] == "TestPack"
    assert data["chip_earned"] is True
    assert data["quarterly_scan_count"] == 1
    assert data["tier_name"] == "Standard"


async def test_submit_already_scanned(client: AsyncClient, auth_headers, registered_user, db: AsyncSession):
    await seed_tiers(db)
    product = await create_product(db)
    qr = await create_qr(db, product, "USED111USED22")

    # First scan succeeds
    resp = await client.post(
        "/api/scans/submit",
        headers=auth_headers,
        json={"qr_code": "BLAKJAKS-TESTPACK-USED111USED22"},
    )
    assert resp.status_code == 200

    # Second scan of same code should fail
    resp = await client.post(
        "/api/scans/submit",
        headers=auth_headers,
        json={"qr_code": "BLAKJAKS-TESTPACK-USED111USED22"},
    )
    assert resp.status_code == 409
    assert "already" in resp.json()["detail"].lower()


async def test_submit_invalid_format(client: AsyncClient, auth_headers):
    resp = await client.post(
        "/api/scans/submit",
        headers=auth_headers,
        json={"qr_code": "INVALID-FORMAT"},
    )
    assert resp.status_code == 400
    assert "format" in resp.json()["detail"].lower()


async def test_submit_nonexistent_qr(client: AsyncClient, auth_headers):
    resp = await client.post(
        "/api/scans/submit",
        headers=auth_headers,
        json={"qr_code": "BLAKJAKS-FAKEPROD-DOESNOTEXIST"},
    )
    assert resp.status_code == 404


# ── GET /scans/recent ───────────────────────────────────────────────


async def test_recent_scans(client: AsyncClient, auth_headers, registered_user, db: AsyncSession):
    await seed_tiers(db)
    product = await create_product(db)

    # Create and scan 3 QR codes
    for i in range(3):
        qr = await create_qr(db, product, f"RECENT{i:08d}")
        await client.post(
            "/api/scans/submit",
            headers=auth_headers,
            json={"qr_code": f"BLAKJAKS-TESTPACK-RECENT{i:08d}"},
        )

    resp = await client.get("/api/scans/recent", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) == 3
    assert data[0]["product_name"] == "TestPack"


async def test_recent_scans_empty(client: AsyncClient, auth_headers):
    resp = await client.get("/api/scans/recent", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json() == []


# ── GET /scans/history ──────────────────────────────────────────────


async def test_scan_history_paginated(client: AsyncClient, auth_headers, registered_user, db: AsyncSession):
    await seed_tiers(db)
    product = await create_product(db)

    # Create and scan 5 QR codes
    for i in range(5):
        qr = await create_qr(db, product, f"HIST{i:09d}")
        await client.post(
            "/api/scans/submit",
            headers=auth_headers,
            json={"qr_code": f"BLAKJAKS-TESTPACK-HIST{i:09d}"},
        )

    # Page 1, 2 per page
    resp = await client.get("/api/scans/history?page=1&per_page=2", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert len(data["items"]) == 2
    assert data["total"] == 5
    assert data["page"] == 1
    assert data["per_page"] == 2

    # Page 3 should have 1 item
    resp = await client.get("/api/scans/history?page=3&per_page=2", headers=auth_headers)
    data = resp.json()
    assert len(data["items"]) == 1


# ── POST /admin/qr-codes/generate ───────────────────────────────────


async def test_admin_generate_qr_codes(client: AsyncClient, registered_user, db: AsyncSession):
    product = await create_product(db)
    admin_token = await make_admin(db, registered_user["user"]["id"])
    headers = {"Authorization": f"Bearer {admin_token}"}

    resp = await client.post(
        "/api/admin/qr-codes/generate",
        headers=headers,
        json={"product_id": str(product.id), "quantity": 5},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["generated"] == 5
    assert len(data["codes"]) == 5
    assert all(c.startswith("BLAKJAKS-") for c in data["codes"])


async def test_non_admin_cannot_generate(client: AsyncClient, auth_headers, registered_user, db: AsyncSession):
    product = await create_product(db)

    resp = await client.post(
        "/api/admin/qr-codes/generate",
        headers=auth_headers,
        json={"product_id": str(product.id), "quantity": 5},
    )
    assert resp.status_code == 403
    assert "admin" in resp.json()["detail"].lower()
