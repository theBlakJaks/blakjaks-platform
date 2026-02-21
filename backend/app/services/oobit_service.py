"""Oobit widget integration — JWT token generation for the on-ramp/off-ramp widget.

Oobit is used to allow users to buy/sell crypto directly from the BlakJaks wallet tab.
Docs: https://docs.oobit.com/widget
"""
import time
import uuid

from jose import jwt

from app.core.config import settings


def generate_widget_token(user_id: uuid.UUID, email: str) -> str:
    """Generate a signed JWT for the Oobit widget.

    Args:
        user_id: The user's UUID (becomes the JWT `sub` claim).
        email:   The user's email address.

    Returns:
        A signed JWT string (HS256).

    Raises:
        RuntimeError: If OOBIT_SECRET_KEY is not configured.
    """
    if not settings.OOBIT_SECRET_KEY:
        raise RuntimeError("OOBIT_SECRET_KEY is not configured")

    now = int(time.time())
    payload = {
        "sub": str(user_id),
        "email": email,
        "apiKey": settings.OOBIT_API_KEY,
        "iat": now,
        "exp": now + 15 * 60,  # 15 minutes
    }
    return jwt.encode(payload, settings.OOBIT_SECRET_KEY, algorithm="HS256")


def get_widget_url(user_id: uuid.UUID, email: str) -> str:
    """Return the full Oobit widget URL with embedded auth token.

    Args:
        user_id: The user's UUID.
        email:   The user's email address.

    Returns:
        A URL string like `https://widget.oobit.com?token=<jwt>`.
    """
    token = generate_widget_token(user_id, email)
    base_url = settings.OOBIT_WIDGET_URL.rstrip("/")
    return f"{base_url}?token={token}"
