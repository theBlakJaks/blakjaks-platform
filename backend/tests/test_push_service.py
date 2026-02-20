"""Tests for the real APNs / FCM push notification service.

All HTTP calls are mocked — no real network traffic is made.

Coverage:
- iOS tokens route exclusively to the APNs endpoint
- Android tokens route exclusively to the FCM endpoint
- Unknown platform tokens are skipped (no HTTP call, no exception)
- Individual delivery failures (HTTP error / network exception) are caught;
  the send function still returns a count and does not raise
- Missing APNS_CERT_PATH / missing key file: returns 0, does not crash
- Missing FCM_SERVER_KEY: returns 0, does not crash
- register_device_token / unregister_device_token happy paths (kept from
  existing coverage, re-verified here as self-contained unit tests)
"""

import os
import tempfile
import uuid
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from sqlalchemy.ext.asyncio import AsyncSession

from app.services.push_service import (
    _send_apns,
    _send_fcm,
    register_device_token,
    send_push_notification,
    send_push_to_all,
    send_push_to_segment,
    unregister_device_token,
)

pytestmark = pytest.mark.asyncio

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

APNS_URL_PREFIX = "https://api.push.apple.com/3/device/"
FCM_URL = "https://fcm.googleapis.com/fcm/send"


def _make_httpx_response(status_code: int = 200, text: str = "") -> MagicMock:
    """Return a minimal fake httpx.Response."""
    resp = MagicMock()
    resp.status_code = status_code
    resp.text = text
    return resp


def _mock_async_client(response: MagicMock) -> MagicMock:
    """Return an AsyncMock context-manager that yields a client whose .post()
    returns *response*."""
    mock_client = AsyncMock()
    mock_client.post = AsyncMock(return_value=response)
    mock_client.__aenter__ = AsyncMock(return_value=mock_client)
    mock_client.__aexit__ = AsyncMock(return_value=False)
    cm = MagicMock()
    cm.return_value = mock_client
    return cm, mock_client


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


def _make_p8_key_file() -> str:
    """Write a real EC P-256 private key in PEM format to a temp file and
    return the path.  The key is ephemeral and used only to verify the JWT
    construction code path.
    """
    from cryptography.hazmat.primitives import serialization
    from cryptography.hazmat.primitives.asymmetric import ec

    key = ec.generate_private_key(ec.SECP256R1())
    pem = key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption(),
    )
    tmp = tempfile.NamedTemporaryFile(suffix=".p8", delete=False)
    tmp.write(pem)
    tmp.flush()
    tmp.close()
    return tmp.name


# ---------------------------------------------------------------------------
# _send_apns — low-level unit tests
# ---------------------------------------------------------------------------


async def test_apns_success_calls_correct_url():
    """A successful APNs delivery POSTs to the correct APNs endpoint."""
    p8_path = _make_p8_key_file()
    try:
        mock_cm, mock_client = _mock_async_client(_make_httpx_response(200))

        with (
            patch("app.services.push_service.settings") as mock_settings,
            patch("app.services.push_service.httpx.AsyncClient", mock_cm),
        ):
            mock_settings.APNS_CERT_PATH = p8_path
            mock_settings.APNS_KEY_ID = "TESTKEYID"
            mock_settings.APNS_TEAM_ID = "TESTTEAMID"
            mock_settings.APNS_BUNDLE_ID = "com.blakjaks.app"

            result = await _send_apns("device-token-abc", "Hello", "World", None)

        assert result is True
        mock_client.post.assert_awaited_once()
        call_url = mock_client.post.call_args[0][0]
        assert call_url == f"{APNS_URL_PREFIX}device-token-abc"

        call_headers = mock_client.post.call_args[1]["headers"]
        assert call_headers["apns-topic"] == "com.blakjaks.app"
        assert call_headers["authorization"].startswith("bearer ")
        assert call_headers["content-type"] == "application/json"

    finally:
        os.unlink(p8_path)


async def test_apns_payload_structure():
    """APNs POST body contains aps.alert with title/body and sound."""
    p8_path = _make_p8_key_file()
    try:
        mock_cm, mock_client = _mock_async_client(_make_httpx_response(200))

        with (
            patch("app.services.push_service.settings") as mock_settings,
            patch("app.services.push_service.httpx.AsyncClient", mock_cm),
        ):
            mock_settings.APNS_CERT_PATH = p8_path
            mock_settings.APNS_KEY_ID = "KID"
            mock_settings.APNS_TEAM_ID = "TEAM"
            mock_settings.APNS_BUNDLE_ID = "com.blakjaks.app"

            await _send_apns("tok", "My Title", "My Body", {"action": "open_game"})

        json_body = mock_client.post.call_args[1]["json"]
        assert json_body["aps"]["alert"]["title"] == "My Title"
        assert json_body["aps"]["alert"]["body"] == "My Body"
        assert json_body["aps"]["sound"] == "default"
        assert json_body["action"] == "open_game"

    finally:
        os.unlink(p8_path)


async def test_apns_http_error_returns_false():
    """A non-200 APNs response returns False but does not raise."""
    p8_path = _make_p8_key_file()
    try:
        mock_cm, mock_client = _mock_async_client(
            _make_httpx_response(400, '{"reason":"BadDeviceToken"}')
        )

        with (
            patch("app.services.push_service.settings") as mock_settings,
            patch("app.services.push_service.httpx.AsyncClient", mock_cm),
        ):
            mock_settings.APNS_CERT_PATH = p8_path
            mock_settings.APNS_KEY_ID = "KID"
            mock_settings.APNS_TEAM_ID = "TEAM"
            mock_settings.APNS_BUNDLE_ID = "com.blakjaks.app"

            result = await _send_apns("bad-token", "T", "B", None)

        assert result is False

    finally:
        os.unlink(p8_path)


async def test_apns_network_exception_returns_false():
    """A network exception during APNs delivery returns False and does not raise."""
    p8_path = _make_p8_key_file()
    try:
        mock_cm = MagicMock()
        mock_client = AsyncMock()
        mock_client.post = AsyncMock(side_effect=Exception("Connection refused"))
        mock_client.__aenter__ = AsyncMock(return_value=mock_client)
        mock_client.__aexit__ = AsyncMock(return_value=False)
        mock_cm.return_value = mock_client

        with (
            patch("app.services.push_service.settings") as mock_settings,
            patch("app.services.push_service.httpx.AsyncClient", mock_cm),
        ):
            mock_settings.APNS_CERT_PATH = p8_path
            mock_settings.APNS_KEY_ID = "KID"
            mock_settings.APNS_TEAM_ID = "TEAM"
            mock_settings.APNS_BUNDLE_ID = "com.blakjaks.app"

            result = await _send_apns("tok", "T", "B", None)

        assert result is False

    finally:
        os.unlink(p8_path)


async def test_apns_missing_cert_path_returns_false():
    """When APNS_CERT_PATH is empty, _send_apns returns False without crashing."""
    with patch("app.services.push_service.settings") as mock_settings:
        mock_settings.APNS_CERT_PATH = ""
        mock_settings.APNS_KEY_ID = "KID"
        mock_settings.APNS_TEAM_ID = "TEAM"
        mock_settings.APNS_BUNDLE_ID = "com.blakjaks.app"

        result = await _send_apns("tok", "T", "B", None)

    assert result is False


async def test_apns_cert_file_not_found_returns_false():
    """When the .p8 file does not exist, _send_apns returns False without crashing."""
    with patch("app.services.push_service.settings") as mock_settings:
        mock_settings.APNS_CERT_PATH = "/nonexistent/path/AuthKey.p8"
        mock_settings.APNS_KEY_ID = "KID"
        mock_settings.APNS_TEAM_ID = "TEAM"
        mock_settings.APNS_BUNDLE_ID = "com.blakjaks.app"

        result = await _send_apns("tok", "T", "B", None)

    assert result is False


# ---------------------------------------------------------------------------
# _send_fcm — low-level unit tests
# ---------------------------------------------------------------------------


async def test_fcm_success_calls_correct_url():
    """A successful FCM delivery POSTs to the FCM endpoint."""
    mock_cm, mock_client = _mock_async_client(_make_httpx_response(200))

    with (
        patch("app.services.push_service.settings") as mock_settings,
        patch("app.services.push_service.httpx.AsyncClient", mock_cm),
    ):
        mock_settings.FCM_SERVER_KEY = "AAAA:test-server-key"

        result = await _send_fcm("fcm-device-token", "Hi", "There", {"k": "v"})

    assert result is True
    mock_client.post.assert_awaited_once()
    call_url = mock_client.post.call_args[0][0]
    assert call_url == FCM_URL

    call_headers = mock_client.post.call_args[1]["headers"]
    assert call_headers["Authorization"] == "key=AAAA:test-server-key"

    json_body = mock_client.post.call_args[1]["json"]
    assert json_body["to"] == "fcm-device-token"
    assert json_body["notification"]["title"] == "Hi"
    assert json_body["notification"]["body"] == "There"
    assert json_body["data"] == {"k": "v"}


async def test_fcm_missing_server_key_returns_false():
    """When FCM_SERVER_KEY is empty, _send_fcm returns False without crashing."""
    with patch("app.services.push_service.settings") as mock_settings:
        mock_settings.FCM_SERVER_KEY = ""

        result = await _send_fcm("tok", "T", "B", None)

    assert result is False


async def test_fcm_http_error_returns_false():
    """A non-200 FCM response returns False but does not raise."""
    mock_cm, mock_client = _mock_async_client(_make_httpx_response(401, "Unauthorized"))

    with (
        patch("app.services.push_service.settings") as mock_settings,
        patch("app.services.push_service.httpx.AsyncClient", mock_cm),
    ):
        mock_settings.FCM_SERVER_KEY = "key"

        result = await _send_fcm("tok", "T", "B", None)

    assert result is False


async def test_fcm_network_exception_returns_false():
    """A network exception during FCM delivery returns False and does not raise."""
    mock_cm = MagicMock()
    mock_client = AsyncMock()
    mock_client.post = AsyncMock(side_effect=ConnectionError("refused"))
    mock_client.__aenter__ = AsyncMock(return_value=mock_client)
    mock_client.__aexit__ = AsyncMock(return_value=False)
    mock_cm.return_value = mock_client

    with (
        patch("app.services.push_service.settings") as mock_settings,
        patch("app.services.push_service.httpx.AsyncClient", mock_cm),
    ):
        mock_settings.FCM_SERVER_KEY = "key"

        result = await _send_fcm("tok", "T", "B", None)

    assert result is False


async def test_fcm_data_defaults_to_empty_dict():
    """When data=None, FCM payload uses an empty dict for the 'data' key."""
    mock_cm, mock_client = _mock_async_client(_make_httpx_response(200))

    with (
        patch("app.services.push_service.settings") as mock_settings,
        patch("app.services.push_service.httpx.AsyncClient", mock_cm),
    ):
        mock_settings.FCM_SERVER_KEY = "key"

        await _send_fcm("tok", "T", "B", None)

    json_body = mock_client.post.call_args[1]["json"]
    assert json_body["data"] == {}


# ---------------------------------------------------------------------------
# Platform routing through send_push_notification
# ---------------------------------------------------------------------------


async def test_ios_token_routes_to_apns(db: AsyncSession):
    """iOS device tokens call _send_apns, not _send_fcm."""
    user = await _create_user(db, "ios-route@example.com")
    await register_device_token(db, user.id, "ios-tok", "ios")

    with (
        patch("app.services.push_service._send_apns", new_callable=AsyncMock) as mock_apns,
        patch("app.services.push_service._send_fcm", new_callable=AsyncMock) as mock_fcm,
    ):
        mock_apns.return_value = True
        mock_fcm.return_value = True

        count = await send_push_notification(db, user.id, "Title", "Body")

    assert count == 1
    mock_apns.assert_awaited_once_with("ios-tok", "Title", "Body", None)
    mock_fcm.assert_not_awaited()


async def test_android_token_routes_to_fcm(db: AsyncSession):
    """Android device tokens call _send_fcm, not _send_apns."""
    user = await _create_user(db, "android-route@example.com")
    await register_device_token(db, user.id, "android-tok", "android")

    with (
        patch("app.services.push_service._send_apns", new_callable=AsyncMock) as mock_apns,
        patch("app.services.push_service._send_fcm", new_callable=AsyncMock) as mock_fcm,
    ):
        mock_apns.return_value = True
        mock_fcm.return_value = True

        count = await send_push_notification(db, user.id, "Title", "Body")

    assert count == 1
    mock_fcm.assert_awaited_once_with("android-tok", "Title", "Body", None)
    mock_apns.assert_not_awaited()


async def test_mixed_platforms_route_correctly(db: AsyncSession):
    """Multiple tokens with mixed platforms each go to the correct backend."""
    user = await _create_user(db, "mixed@example.com")
    await register_device_token(db, user.id, "ios-tok-1", "ios")
    await register_device_token(db, user.id, "android-tok-1", "android")

    with (
        patch("app.services.push_service._send_apns", new_callable=AsyncMock) as mock_apns,
        patch("app.services.push_service._send_fcm", new_callable=AsyncMock) as mock_fcm,
    ):
        mock_apns.return_value = True
        mock_fcm.return_value = True

        count = await send_push_notification(db, user.id, "T", "B", {"x": 1})

    assert count == 2
    mock_apns.assert_awaited_once_with("ios-tok-1", "T", "B", {"x": 1})
    mock_fcm.assert_awaited_once_with("android-tok-1", "T", "B", {"x": 1})


async def test_unknown_platform_skips_without_exception(db: AsyncSession):
    """An unknown platform string is skipped; no HTTP call is made, no exception raised."""
    user = await _create_user(db, "unknown-platform@example.com")
    await register_device_token(db, user.id, "unknown-tok", "web")

    with (
        patch("app.services.push_service._send_apns", new_callable=AsyncMock) as mock_apns,
        patch("app.services.push_service._send_fcm", new_callable=AsyncMock) as mock_fcm,
    ):
        count = await send_push_notification(db, user.id, "T", "B")

    assert count == 1  # token was found and attempted
    mock_apns.assert_not_awaited()
    mock_fcm.assert_not_awaited()


# ---------------------------------------------------------------------------
# Error handling: delivery failures must not propagate to callers
# ---------------------------------------------------------------------------


async def test_apns_failure_does_not_raise(db: AsyncSession):
    """Even when _send_apns raises internally, send_push_notification catches it."""
    user = await _create_user(db, "apns-fail@example.com")
    await register_device_token(db, user.id, "fail-ios-tok", "ios")

    with patch(
        "app.services.push_service._send_apns",
        new_callable=AsyncMock,
        side_effect=RuntimeError("unexpected crash"),
    ):
        # Must not raise — callers rely on push being best-effort
        count = await send_push_notification(db, user.id, "T", "B")

    # The token was found (count still reflects tokens attempted, not successes)
    assert count == 1


async def test_fcm_failure_does_not_raise(db: AsyncSession):
    """Even when _send_fcm raises internally, send_push_notification catches it."""
    user = await _create_user(db, "fcm-fail@example.com")
    await register_device_token(db, user.id, "fail-android-tok", "android")

    with patch(
        "app.services.push_service._send_fcm",
        new_callable=AsyncMock,
        side_effect=RuntimeError("unexpected crash"),
    ):
        count = await send_push_notification(db, user.id, "T", "B")

    assert count == 1


async def test_one_failure_does_not_stop_remaining_tokens(db: AsyncSession):
    """A failure on one token does not prevent the remaining tokens from being attempted."""
    user = await _create_user(db, "multi-fail@example.com")
    await register_device_token(db, user.id, "tok-1", "ios")
    await register_device_token(db, user.id, "tok-2", "ios")
    await register_device_token(db, user.id, "tok-3", "ios")

    call_count = 0

    async def flaky_apns(token, title, body, data):
        nonlocal call_count
        call_count += 1
        if token == "tok-2":
            raise RuntimeError("transient error")
        return True

    with patch("app.services.push_service._send_apns", side_effect=flaky_apns):
        count = await send_push_notification(db, user.id, "T", "B")

    assert count == 3         # all three tokens were attempted
    assert call_count == 3    # all three calls were made despite the middle failure


# ---------------------------------------------------------------------------
# send_push_to_all
# ---------------------------------------------------------------------------


async def test_send_push_to_all_reaches_every_token(db: AsyncSession):
    """send_push_to_all dispatches to every registered device across all users."""
    user_a = await _create_user(db, "all-a@example.com")
    user_b = await _create_user(db, "all-b@example.com")
    await register_device_token(db, user_a.id, "tok-a-ios", "ios")
    await register_device_token(db, user_b.id, "tok-b-android", "android")

    with (
        patch("app.services.push_service._send_apns", new_callable=AsyncMock) as mock_apns,
        patch("app.services.push_service._send_fcm", new_callable=AsyncMock) as mock_fcm,
    ):
        mock_apns.return_value = True
        mock_fcm.return_value = True

        count = await send_push_to_all(db, "Broadcast", "Message")

    assert count == 2
    mock_apns.assert_awaited_once_with("tok-a-ios", "Broadcast", "Message", None)
    mock_fcm.assert_awaited_once_with("tok-b-android", "Broadcast", "Message", None)


# ---------------------------------------------------------------------------
# send_push_to_segment
# ---------------------------------------------------------------------------


async def test_send_push_to_segment_filters_by_tier(db: AsyncSession):
    """send_push_to_segment only dispatches to users in the specified tier."""
    from app.models.tier import Tier
    from app.models.user import User

    # Create two tiers
    vip_tier = Tier(
        name="VIP",
        min_scans=7,
        color="#3B82F6",
        benefits_json={},
    )
    standard_tier = Tier(
        name="Standard",
        min_scans=0,
        color="#6B7280",
        benefits_json={},
    )
    db.add_all([vip_tier, standard_tier])
    await db.commit()
    await db.refresh(vip_tier)
    await db.refresh(standard_tier)

    # Create users in each tier
    from app.core.security import hash_password
    from app.services.wallet_service import create_user_wallet

    vip_user = User(
        email="seg-vip@example.com",
        password_hash=hash_password("pw"),
        first_name="VIP",
        last_name="User",
        tier_id=vip_tier.id,
    )
    std_user = User(
        email="seg-std@example.com",
        password_hash=hash_password("pw"),
        first_name="Std",
        last_name="User",
        tier_id=standard_tier.id,
    )
    db.add_all([vip_user, std_user])
    await db.commit()
    await db.refresh(vip_user)
    await db.refresh(std_user)

    await create_user_wallet(db, vip_user.id, email="seg-vip@example.com")
    await create_user_wallet(db, std_user.id, email="seg-std@example.com")

    await register_device_token(db, vip_user.id, "vip-ios-tok", "ios")
    await register_device_token(db, std_user.id, "std-android-tok", "android")

    with (
        patch("app.services.push_service._send_apns", new_callable=AsyncMock) as mock_apns,
        patch("app.services.push_service._send_fcm", new_callable=AsyncMock) as mock_fcm,
    ):
        mock_apns.return_value = True
        mock_fcm.return_value = True

        count = await send_push_to_segment(db, "VIP", "VIP Offer", "Exclusive deal")

    assert count == 1
    mock_apns.assert_awaited_once_with("vip-ios-tok", "VIP Offer", "Exclusive deal", None)
    mock_fcm.assert_not_awaited()


# ---------------------------------------------------------------------------
# register / unregister device token (self-contained unit re-verification)
# ---------------------------------------------------------------------------


async def test_register_device_token_stores_record(db: AsyncSession):
    user = await _create_user(db, "reg-push@example.com")
    dt = await register_device_token(db, user.id, "apns-xyz", "ios")
    assert dt.token == "apns-xyz"
    assert dt.platform == "ios"
    assert dt.user_id == user.id


async def test_register_same_token_is_idempotent(db: AsyncSession):
    user = await _create_user(db, "idem-push@example.com")
    dt1 = await register_device_token(db, user.id, "same-tok", "ios")
    dt2 = await register_device_token(db, user.id, "same-tok", "ios")
    assert dt1.id == dt2.id


async def test_unregister_device_token_returns_true_then_false(db: AsyncSession):
    user = await _create_user(db, "unreg-push@example.com")
    await register_device_token(db, user.id, "tok-del", "android")

    removed = await unregister_device_token(db, user.id, "tok-del")
    assert removed is True

    removed_again = await unregister_device_token(db, user.id, "tok-del")
    assert removed_again is False


async def test_send_push_notification_no_tokens_returns_zero(db: AsyncSession):
    """A user with no registered devices returns 0 without error."""
    user = await _create_user(db, "no-tokens@example.com")
    count = await send_push_notification(db, user.id, "T", "B")
    assert count == 0
