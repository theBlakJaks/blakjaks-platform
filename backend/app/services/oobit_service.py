"""Oobit crypto payment widget token service.

Generates signed JWT session tokens that authorize users to open the
Oobit payment widget embedded in the BlakJaks app.

Oobit uses HMAC-SHA256 signed JWTs.  The payload carries:
  - sub: external user identifier
  - email: user's email address
  - exp: expiry (15 minutes from now)
  - iat: issued-at timestamp
  - apiKey: the Oobit public API key

The token is embedded in the widget URL as a query param:
  {OOBIT_WIDGET_URL}?token={jwt}
"""

import logging
import time
from uuid import UUID

import hmac
import hashlib
import base64
import json

from app.core.config import settings

logger = logging.getLogger(__name__)

_TOKEN_TTL = 900  # 15 minutes


def _b64url_encode(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def _generate_jwt(payload: dict, secret: str) -> str:
    """Build a compact HMAC-SHA256 JWT (no third-party library required)."""
    header = {"alg": "HS256", "typ": "JWT"}
    header_enc = _b64url_encode(json.dumps(header, separators=(",", ":")).encode())
    payload_enc = _b64url_encode(json.dumps(payload, separators=(",", ":")).encode())
    signing_input = f"{header_enc}.{payload_enc}"
    sig = hmac.new(
        secret.encode(),
        signing_input.encode(),
        hashlib.sha256,
    ).digest()
    return f"{signing_input}.{_b64url_encode(sig)}"


def generate_widget_token(user_id: UUID, email: str) -> str:
    """Generate a short-lived Oobit widget JWT for a user.

    Args:
        user_id: The internal BlakJaks user UUID.
        email: The user's email address.

    Returns:
        Signed JWT string.

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
        "exp": now + _TOKEN_TTL,
    }
    return _generate_jwt(payload, settings.OOBIT_SECRET_KEY)


def get_widget_url(user_id: UUID, email: str) -> str:
    """Return the full Oobit widget URL with a signed token.

    Args:
        user_id: The internal BlakJaks user UUID.
        email: The user's email address.

    Returns:
        Full URL string including ?token= parameter.
    """
    token = generate_widget_token(user_id, email)
    return f"{settings.OOBIT_WIDGET_URL}?token={token}"
