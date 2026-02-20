"""Intercom integration for in-app live chat support.

Uses the Intercom REST API for contact management and event tracking.
Failures are logged but never raised — Intercom issues must not break app functionality.

Identity verification uses HMAC-SHA256 over user_id with
INTERCOM_IDENTITY_VERIFICATION_SECRET, per Intercom's security model.
"""

import hashlib
import hmac
import logging
import uuid

import httpx

from app.core.config import settings

logger = logging.getLogger(__name__)

INTERCOM_BASE_URL = "https://api.intercom.io"


def _headers() -> dict:
    return {
        "Authorization": f"Bearer {settings.INTERCOM_API_KEY}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }


async def create_or_update_contact(
    user_id: uuid.UUID, email: str, name: str, tier: str | None = None
) -> dict | None:
    """Create or update a user in Intercom on signup and tier changes.

    Uses Intercom Contacts API (POST /contacts).
    """
    if not settings.INTERCOM_API_KEY:
        logger.debug("Intercom API key not configured, skipping contact sync")
        return None

    payload = {
        "role": "user",
        "external_id": str(user_id),
        "email": email,
        "name": name,
        "custom_attributes": {},
    }
    if tier:
        payload["custom_attributes"]["tier"] = tier

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.post(
                f"{INTERCOM_BASE_URL}/contacts",
                headers=_headers(),
                json=payload,
            )
            resp.raise_for_status()
            return resp.json()
    except Exception:
        logger.exception("Intercom create_or_update_contact failed for user=%s", user_id)
        return None


async def track_event(
    user_id: uuid.UUID, event_name: str, metadata: dict | None = None
) -> dict | None:
    """Track events like scan_completed, order_placed, comp_received.

    Uses Intercom Events API (POST /events).
    """
    if not settings.INTERCOM_API_KEY:
        logger.debug("Intercom API key not configured, skipping event tracking")
        return None

    import time

    payload = {
        "event_name": event_name,
        "created_at": int(time.time()),
        "user_id": str(user_id),
    }
    if metadata:
        payload["metadata"] = metadata

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.post(
                f"{INTERCOM_BASE_URL}/events",
                headers=_headers(),
                json=payload,
            )
            resp.raise_for_status()
            # Events API returns 202 with no body on success
            return {"status": "accepted"}
    except Exception:
        logger.exception("Intercom track_event failed for user=%s event=%s", user_id, event_name)
        return None


def generate_identity_hash(user_id: uuid.UUID) -> str | None:
    """Generate the Intercom identity verification HMAC for a user.

    Computed over str(user_id) with INTERCOM_IDENTITY_VERIFICATION_SECRET.

    Returns:
        Hex-encoded HMAC-SHA256 string, or None if not configured.
    """
    secret = settings.INTERCOM_IDENTITY_VERIFICATION_SECRET
    if not secret:
        return None
    return hmac.new(
        secret.encode(),
        str(user_id).encode(),
        hashlib.sha256,
    ).hexdigest()


def get_widget_config(user_id: uuid.UUID, email: str, name: str | None = None) -> dict:
    """Return the Intercom widget boot config for a user.

    Embed this in mobile responses so the client can boot the Intercom SDK.

    Returns:
        Dict with app_id, user_id, email, user_hash, and platform API keys.
    """
    return {
        "app_id": settings.INTERCOM_APP_ID,
        "user_id": str(user_id),
        "email": email,
        "name": name,
        "user_hash": generate_identity_hash(user_id),
        "ios_api_key": settings.INTERCOM_IOS_API_KEY or None,
        "android_api_key": settings.INTERCOM_ANDROID_API_KEY or None,
    }
