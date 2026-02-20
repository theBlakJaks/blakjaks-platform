"""Push notification service for iOS (APNs) and Android (FCM).

APNs uses HTTP/2 with JWT authentication (ES256, .p8 key).
FCM uses the legacy HTTP v1 server-key API.
"""

import json
import logging
import os
import uuid
from base64 import urlsafe_b64encode
from time import time

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.device_token import DeviceToken

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# APNs constants
# ---------------------------------------------------------------------------
APNS_PRODUCTION_URL = "https://api.push.apple.com/3/device/{token}"
APNS_SANDBOX_URL = "https://api.sandbox.push.apple.com/3/device/{token}"


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------


def _b64url(data: bytes) -> str:
    """Return URL-safe base64 without padding — as required by JWT."""
    return urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def _build_apns_jwt() -> str | None:
    """Build and sign an APNs JWT token using the .p8 private key.

    Returns the signed JWT string, or None if prerequisites are missing.
    """
    if not settings.APNS_CERT_PATH:
        logger.warning("PUSH [APNs] APNS_CERT_PATH is not configured — skipping APNs delivery")
        return None

    if not os.path.isfile(settings.APNS_CERT_PATH):
        logger.warning(
            "PUSH [APNs] .p8 key file not found at %s — skipping APNs delivery",
            settings.APNS_CERT_PATH,
        )
        return None

    if not settings.APNS_KEY_ID:
        logger.warning("PUSH [APNs] APNS_KEY_ID is not configured — skipping APNs delivery")
        return None

    if not settings.APNS_TEAM_ID:
        logger.warning("PUSH [APNs] APNS_TEAM_ID is not configured — skipping APNs delivery")
        return None

    try:
        from cryptography.hazmat.primitives import hashes, serialization
        from cryptography.hazmat.primitives.asymmetric import ec

        with open(settings.APNS_CERT_PATH, "rb") as fh:
            private_key = serialization.load_pem_private_key(fh.read(), password=None)

        header = _b64url(
            json.dumps({"alg": "ES256", "kid": settings.APNS_KEY_ID}).encode()
        )
        payload = _b64url(
            json.dumps({"iss": settings.APNS_TEAM_ID, "iat": int(time())}).encode()
        )
        signing_input = f"{header}.{payload}".encode()

        signature = private_key.sign(signing_input, ec.ECDSA(hashes.SHA256()))
        return f"{header}.{payload}.{_b64url(signature)}"

    except Exception as exc:
        logger.error("PUSH [APNs] Failed to build JWT: %s", exc)
        return None


async def _send_apns(token: str, title: str, body: str, data: dict | None) -> bool:
    """Send a single APNs push notification.

    Returns True on success, False on failure.
    Raises no exceptions — all errors are caught and logged.
    """
    jwt_token = _build_apns_jwt()
    if jwt_token is None:
        return False

    if not settings.APNS_BUNDLE_ID:
        logger.warning("PUSH [APNs] APNS_BUNDLE_ID is not configured — skipping")
        return False

    # Use production endpoint; switch to sandbox URL for development if needed.
    url = APNS_PRODUCTION_URL.format(token=token)

    payload: dict = {"aps": {"alert": {"title": title, "body": body}, "sound": "default"}}
    if data:
        payload.update(data)

    headers = {
        "authorization": f"bearer {jwt_token}",
        "apns-topic": settings.APNS_BUNDLE_ID,
        "content-type": "application/json",
    }

    try:
        async with httpx.AsyncClient(http2=True) as client:
            resp = await client.post(url, json=payload, headers=headers)

        if resp.status_code == 200:
            logger.debug("PUSH [APNs] Delivered to token=%s", token)
            return True

        logger.error(
            "PUSH [APNs] Delivery failed token=%s status=%s body=%s",
            token,
            resp.status_code,
            resp.text,
        )
        return False

    except Exception as exc:
        logger.error("PUSH [APNs] Exception delivering to token=%s: %s", token, exc)
        return False


async def _send_fcm(token: str, title: str, body: str, data: dict | None) -> bool:
    """Send a single FCM push notification.

    Returns True on success, False on failure.
    Raises no exceptions — all errors are caught and logged.
    """
    if not settings.FCM_SERVER_KEY:
        logger.warning("PUSH [FCM] FCM_SERVER_KEY is not configured — skipping FCM delivery")
        return False

    url = "https://fcm.googleapis.com/fcm/send"
    headers = {
        "Authorization": f"key={settings.FCM_SERVER_KEY}",
        "Content-Type": "application/json",
    }
    fcm_payload = {
        "to": token,
        "notification": {"title": title, "body": body},
        "data": data or {},
    }

    try:
        async with httpx.AsyncClient() as client:
            resp = await client.post(url, json=fcm_payload, headers=headers)

        if resp.status_code == 200:
            logger.debug("PUSH [FCM] Delivered to token=%s", token)
            return True

        logger.error(
            "PUSH [FCM] Delivery failed token=%s status=%s body=%s",
            token,
            resp.status_code,
            resp.text,
        )
        return False

    except Exception as exc:
        logger.error("PUSH [FCM] Exception delivering to token=%s: %s", token, exc)
        return False


async def _dispatch(dt: DeviceToken, title: str, body: str, data: dict | None) -> bool:
    """Route a DeviceToken to the correct push backend."""
    if dt.platform == "ios":
        return await _send_apns(dt.token, title, body, data)
    elif dt.platform == "android":
        return await _send_fcm(dt.token, title, body, data)
    else:
        logger.warning(
            "PUSH Unknown platform=%s for token=%s — skipping",
            dt.platform,
            dt.token,
        )
        return False


# ---------------------------------------------------------------------------
# Public API — signatures unchanged from the placeholder
# ---------------------------------------------------------------------------


async def register_device_token(
    db: AsyncSession, user_id: uuid.UUID, token: str, platform: str
) -> DeviceToken:
    """Store a device token for push notifications.

    If the token already exists for this user, return the existing record.
    """
    result = await db.execute(
        select(DeviceToken).where(
            DeviceToken.user_id == user_id,
            DeviceToken.token == token,
        )
    )
    existing = result.scalar_one_or_none()
    if existing:
        return existing

    device_token = DeviceToken(
        user_id=user_id,
        token=token,
        platform=platform,
    )
    db.add(device_token)
    await db.commit()
    await db.refresh(device_token)
    return device_token


async def unregister_device_token(
    db: AsyncSession, user_id: uuid.UUID, token: str
) -> bool:
    """Remove a device token on logout. Returns True if a token was removed."""
    result = await db.execute(
        select(DeviceToken).where(
            DeviceToken.user_id == user_id,
            DeviceToken.token == token,
        )
    )
    device_token = result.scalar_one_or_none()
    if device_token is None:
        return False

    await db.delete(device_token)
    await db.commit()
    return True


async def send_push_notification(
    db: AsyncSession, user_id: uuid.UUID, title: str, body: str, data: dict | None = None
) -> int:
    """Send a push notification to all of a specific user's registered devices.

    Returns the number of devices for which delivery was attempted.
    Never raises — individual delivery failures are caught and logged.
    """
    result = await db.execute(
        select(DeviceToken).where(DeviceToken.user_id == user_id)
    )
    tokens = list(result.scalars().all())

    count = 0
    for dt in tokens:
        try:
            await _dispatch(dt, title, body, data)
        except Exception as exc:
            logger.error(
                "PUSH Unhandled exception for user=%s token=%s: %s", user_id, dt.token, exc
            )
        count += 1

    return count


async def send_push_to_segment(
    db: AsyncSession, tier_name: str, title: str, body: str, data: dict | None = None
) -> int:
    """Send a push notification to all users belonging to a specific membership tier.

    Returns the number of devices for which delivery was attempted.
    Never raises — individual delivery failures are caught and logged.
    """
    from app.models.tier import Tier
    from app.models.user import User

    result = await db.execute(
        select(DeviceToken)
        .join(User, DeviceToken.user_id == User.id)
        .join(Tier, User.tier_id == Tier.id)
        .where(Tier.name == tier_name)
    )
    tokens = list(result.scalars().all())

    count = 0
    for dt in tokens:
        try:
            await _dispatch(dt, title, body, data)
        except Exception as exc:
            logger.error(
                "PUSH Unhandled exception for segment=%s token=%s: %s", tier_name, dt.token, exc
            )
        count += 1

    return count


async def send_push_to_all(
    db: AsyncSession, title: str, body: str, data: dict | None = None
) -> int:
    """Broadcast a push notification to every device with a registered token.

    Returns the number of devices for which delivery was attempted.
    Never raises — individual delivery failures are caught and logged.
    """
    result = await db.execute(select(DeviceToken))
    tokens = list(result.scalars().all())

    count = 0
    for dt in tokens:
        try:
            await _dispatch(dt, title, body, data)
        except Exception as exc:
            logger.error(
                "PUSH Unhandled exception for broadcast token=%s: %s", dt.token, exc
            )
        count += 1

    return count
