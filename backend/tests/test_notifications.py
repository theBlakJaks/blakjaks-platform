import uuid
import logging
from unittest.mock import AsyncMock, patch

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.notification import Notification
from app.services.email_service import (
    send_comp_award,
    send_order_confirmation,
    send_tier_advancement,
    send_welcome_email,
)
from app.services.notification_service import create_notification, get_unread_count, mark_as_read
from app.services.push_service import register_device_token, unregister_device_token
from tests.conftest import SIGNUP_PAYLOAD

pytestmark = pytest.mark.asyncio


# ── Helper ────────────────────────────────────────────────────────────


async def _create_user(db: AsyncSession, email: str):
    from app.core.security import hash_password
    from app.models.user import User
    from app.services.wallet_service import create_user_wallet

    user = User(
        email=email,
        password_hash=hash_password("password123"),
        first_name="Test",
        last_name="User",
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    await create_user_wallet(db, user.id, email=email)
    return user


# ── Email service (placeholder logging) ──────────────────────────────


async def test_send_welcome_email_logs(caplog):
    with caplog.at_level(logging.INFO, logger="app.services.email_service"):
        await send_welcome_email("test@example.com", "Alice")
    assert "welcome" in caplog.text
    assert "test@example.com" in caplog.text
    assert "Alice" in caplog.text


async def test_send_comp_award_logs(caplog):
    with caplog.at_level(logging.INFO, logger="app.services.email_service"):
        await send_comp_award("user@example.com", "Bob", "100", "crypto_milestone")
    assert "comp_award" in caplog.text
    assert "user@example.com" in caplog.text
    assert "100" in caplog.text
    assert "crypto_milestone" in caplog.text


async def test_send_tier_advancement_logs(caplog):
    with caplog.at_level(logging.INFO, logger="app.services.email_service"):
        await send_tier_advancement("vip@example.com", "Charlie", "VIP")
    assert "tier_advancement" in caplog.text
    assert "VIP" in caplog.text
    assert "Charlie" in caplog.text


async def test_send_order_confirmation_logs(caplog):
    order = {"id": "abc-123", "subtotal": "25.00", "shipping": "2.99", "tax": "1.81", "total": "29.80", "item_count": 5}
    with caplog.at_level(logging.INFO, logger="app.services.email_service"):
        await send_order_confirmation("buyer@example.com", order)
    assert "order_confirmation" in caplog.text
    assert "buyer@example.com" in caplog.text


# ── Notification service ─────────────────────────────────────────────


async def test_create_notification(db: AsyncSession):
    user = await _create_user(db, "notif@example.com")
    notif = await create_notification(db, user.id, "comp_award", "You got $100!", "Crypto comp milestone")
    assert notif.id is not None
    assert notif.type == "comp_award"
    assert notif.title == "You got $100!"
    assert notif.body == "Crypto comp milestone"
    assert notif.is_read is False


async def test_get_unread_count(db: AsyncSession):
    user = await _create_user(db, "unread@example.com")

    # Initially 0
    count = await get_unread_count(db, user.id)
    assert count == 0

    # Create 3 notifications
    for i in range(3):
        await create_notification(db, user.id, "system", f"Notif {i}")

    count = await get_unread_count(db, user.id)
    assert count == 3


async def test_mark_as_read_decrements(db: AsyncSession):
    user = await _create_user(db, "markread@example.com")
    n1 = await create_notification(db, user.id, "system", "First")
    await create_notification(db, user.id, "system", "Second")

    assert await get_unread_count(db, user.id) == 2

    result = await mark_as_read(db, n1.id, user.id)
    assert result is True
    assert await get_unread_count(db, user.id) == 1


# ── Push service (device tokens) ─────────────────────────────────────


async def test_register_device_token(db: AsyncSession):
    user = await _create_user(db, "push@example.com")
    dt = await register_device_token(db, user.id, "apns-token-abc123", "ios")
    assert dt.token == "apns-token-abc123"
    assert dt.platform == "ios"
    assert dt.user_id == user.id


async def test_register_same_token_no_duplicate(db: AsyncSession):
    user = await _create_user(db, "dup@example.com")
    dt1 = await register_device_token(db, user.id, "same-token-xyz", "ios")
    dt2 = await register_device_token(db, user.id, "same-token-xyz", "ios")
    assert dt1.id == dt2.id  # Same record returned, no duplicate


async def test_unregister_device_token(db: AsyncSession):
    user = await _create_user(db, "unreg@example.com")
    await register_device_token(db, user.id, "token-to-remove", "android")

    removed = await unregister_device_token(db, user.id, "token-to-remove")
    assert removed is True

    # Second removal should return False
    removed = await unregister_device_token(db, user.id, "token-to-remove")
    assert removed is False


# ── API endpoints ─────────────────────────────────────────────────────


async def test_register_device_token_api(client: AsyncClient, auth_headers):
    resp = await client.post(
        "/api/notifications/device-token",
        headers=auth_headers,
        json={"token": "api-test-token-123", "platform": "ios"},
    )
    assert resp.status_code == 201
    assert "id" in resp.json()


async def test_unregister_device_token_api(client: AsyncClient, auth_headers):
    # Register first
    await client.post(
        "/api/notifications/device-token",
        headers=auth_headers,
        json={"token": "api-delete-token", "platform": "android"},
    )
    # Delete
    resp = await client.request(
        "DELETE",
        "/api/notifications/device-token",
        headers=auth_headers,
        json={"token": "api-delete-token"},
    )
    assert resp.status_code == 200
    assert resp.json()["message"] == "Device token removed"


async def test_unread_count_api(client: AsyncClient, auth_headers, registered_user, db: AsyncSession):
    # Initially 0
    resp = await client.get("/api/notifications/unread-count", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["unread_count"] == 0

    # Create a notification directly
    user_id = uuid.UUID(registered_user["user"]["id"])
    await create_notification(db, user_id, "system", "Test notification")

    resp = await client.get("/api/notifications/unread-count", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["unread_count"] == 1


# ── Intercom service (graceful failure) ──────────────────────────────


async def test_intercom_handles_api_failure():
    """Intercom service should not raise exceptions on API failure."""
    from app.services.intercom_service import create_or_update_contact, track_event

    # Patch settings to have a fake API key so the code actually tries the HTTP call
    with patch("app.services.intercom_service.settings") as mock_settings:
        mock_settings.INTERCOM_API_KEY = "fake-key"

        # Mock httpx.AsyncClient to simulate a connection error
        with patch("app.services.intercom_service.httpx.AsyncClient") as MockClient:
            mock_client = AsyncMock()
            mock_client.post = AsyncMock(side_effect=Exception("Connection refused"))
            mock_client.__aenter__ = AsyncMock(return_value=mock_client)
            mock_client.__aexit__ = AsyncMock(return_value=False)
            MockClient.return_value = mock_client

            # These should NOT raise, just return None
            result = await create_or_update_contact(
                uuid.uuid4(), "fail@example.com", "Test User"
            )
            assert result is None

            result = await track_event(uuid.uuid4(), "test_event", {"key": "value"})
            assert result is None
