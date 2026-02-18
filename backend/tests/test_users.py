import uuid
from datetime import datetime, timezone

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.notification import Notification
from app.models.scan import Scan
from app.models.qr_code import QRCode
from app.models.product import Product
from tests.conftest import SIGNUP_PAYLOAD, seed_tiers

pytestmark = pytest.mark.asyncio


# ── GET /users/me ────────────────────────────────────────────────────


async def test_get_me(client: AsyncClient, auth_headers):
    resp = await client.get("/api/users/me", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["email"] == SIGNUP_PAYLOAD["email"]
    assert data["first_name"] == SIGNUP_PAYLOAD["first_name"]
    assert data["tier"] is None  # no tier assigned yet


async def test_get_me_unauthenticated(client: AsyncClient):
    resp = await client.get("/api/users/me")
    assert resp.status_code == 401


# ── PUT /users/me ────────────────────────────────────────────────────


async def test_update_me(client: AsyncClient, auth_headers):
    resp = await client.put(
        "/api/users/me",
        headers=auth_headers,
        json={"first_name": "Updated", "phone": "+15551234567"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["first_name"] == "Updated"
    assert data["phone"] == "+15551234567"
    # Last name unchanged
    assert data["last_name"] == SIGNUP_PAYLOAD["last_name"]


async def test_update_me_partial(client: AsyncClient, auth_headers):
    resp = await client.put(
        "/api/users/me",
        headers=auth_headers,
        json={"avatar_url": "https://example.com/avatar.png"},
    )
    assert resp.status_code == 200
    assert resp.json()["avatar_url"] == "https://example.com/avatar.png"


# ── GET /users/me/stats ─────────────────────────────────────────────


async def test_get_stats_no_tiers(client: AsyncClient, auth_headers):
    """Without seeded tiers, stats should return gracefully."""
    resp = await client.get("/api/users/me/stats", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["quarterly_scans"] == 0
    assert data["tier_name"] is None


async def test_get_stats_with_tiers(client: AsyncClient, auth_headers, registered_user, db: AsyncSession):
    await seed_tiers(db)

    resp = await client.get("/api/users/me/stats", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["tier_name"] == "Standard"
    assert data["discount_pct"] == 0
    assert data["quarterly_scans"] == 0
    assert data["scans_to_next_tier"] == 7  # 7 scans to VIP


async def test_stats_tier_promotion(client: AsyncClient, auth_headers, registered_user, db: AsyncSession):
    await seed_tiers(db)

    user_id = uuid.UUID(registered_user["user"]["id"])

    # Create a product and QR codes to simulate scans
    product = Product(name="Test Pack", price=5.00, stock=100)
    db.add(product)
    await db.flush()

    for i in range(8):
        qr = QRCode(product_code="TP001", unique_id=f"qr-{uuid.uuid4()}", product_id=product.id)
        db.add(qr)
        await db.flush()
        scan = Scan(user_id=user_id, qr_code_id=qr.id, usdt_earned=1, streak_day=i + 1)
        db.add(scan)

    await db.commit()

    resp = await client.get("/api/users/me/stats", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["tier_name"] == "VIP"
    assert data["discount_pct"] == 10
    assert data["quarterly_scans"] == 8
    assert data["scans_to_next_tier"] == 7  # 15 - 8 = 7 to High Roller


# ── GET /users/me/notifications ──────────────────────────────────────


async def test_get_notifications_empty(client: AsyncClient, auth_headers):
    resp = await client.get("/api/users/me/notifications", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["items"] == []
    assert data["total"] == 0
    assert data["page"] == 1


async def test_get_notifications_paginated(
    client: AsyncClient, auth_headers, registered_user, db: AsyncSession,
):
    user_id = uuid.UUID(registered_user["user"]["id"])

    # Insert 5 notifications
    for i in range(5):
        db.add(Notification(
            user_id=user_id,
            type="test",
            title=f"Notification {i}",
            body=f"Body {i}",
        ))
    await db.commit()

    # Page 1, size 2
    resp = await client.get(
        "/api/users/me/notifications?page=1&page_size=2", headers=auth_headers
    )
    assert resp.status_code == 200
    data = resp.json()
    assert len(data["items"]) == 2
    assert data["total"] == 5
    assert data["page"] == 1

    # Page 3 should have 1 item
    resp = await client.get(
        "/api/users/me/notifications?page=3&page_size=2", headers=auth_headers
    )
    data = resp.json()
    assert len(data["items"]) == 1


# ── PUT /users/me/notifications/{id}/read ────────────────────────────


async def test_mark_notification_read(
    client: AsyncClient, auth_headers, registered_user, db: AsyncSession,
):
    user_id = uuid.UUID(registered_user["user"]["id"])
    notif = Notification(user_id=user_id, type="scan", title="New scan!", body="You earned 1 USDT")
    db.add(notif)
    await db.commit()
    await db.refresh(notif)

    resp = await client.put(
        f"/api/users/me/notifications/{notif.id}/read", headers=auth_headers
    )
    assert resp.status_code == 200

    # Verify it's marked read
    resp = await client.get("/api/users/me/notifications", headers=auth_headers)
    assert resp.json()["items"][0]["is_read"] is True


async def test_mark_notification_read_not_found(client: AsyncClient, auth_headers):
    fake_id = uuid.uuid4()
    resp = await client.put(
        f"/api/users/me/notifications/{fake_id}/read", headers=auth_headers
    )
    assert resp.status_code == 404
