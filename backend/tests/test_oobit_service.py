"""Tests for oobit_service.py — Oobit widget JWT generation."""

import json
import time
import uuid
import base64
import pytest
from unittest.mock import patch


def _decode_jwt_payload(token: str) -> dict:
    """Decode a JWT payload without verifying the signature."""
    parts = token.split(".")
    payload_b64 = parts[1] + "=="  # add padding
    return json.loads(base64.urlsafe_b64decode(payload_b64))


def test_generate_widget_token_raises_without_secret():
    from app.services.oobit_service import generate_widget_token
    from app.core.config import settings

    with patch.object(settings, "OOBIT_SECRET_KEY", ""):
        with pytest.raises(RuntimeError, match="OOBIT_SECRET_KEY"):
            generate_widget_token(uuid.uuid4(), "test@example.com")


def test_generate_widget_token_returns_string():
    from app.services.oobit_service import generate_widget_token
    from app.core.config import settings

    with patch.object(settings, "OOBIT_SECRET_KEY", "test-secret"):
        token = generate_widget_token(uuid.uuid4(), "user@test.com")

    assert isinstance(token, str)
    assert len(token.split(".")) == 3  # header.payload.signature


def test_generate_widget_token_payload_contains_required_fields():
    from app.services.oobit_service import generate_widget_token
    from app.core.config import settings

    uid = uuid.uuid4()
    email = "hello@test.com"

    with patch.object(settings, "OOBIT_SECRET_KEY", "test-secret"), \
         patch.object(settings, "OOBIT_API_KEY", "test-api-key"):
        token = generate_widget_token(uid, email)

    payload = _decode_jwt_payload(token)
    assert payload["sub"] == str(uid)
    assert payload["email"] == email
    assert payload["apiKey"] == "test-api-key"
    assert "iat" in payload
    assert "exp" in payload


def test_generate_widget_token_expiry_is_15_minutes():
    from app.services.oobit_service import generate_widget_token
    from app.core.config import settings

    with patch.object(settings, "OOBIT_SECRET_KEY", "test-secret"):
        before = int(time.time())
        token = generate_widget_token(uuid.uuid4(), "x@test.com")
        after = int(time.time())

    payload = _decode_jwt_payload(token)
    ttl = payload["exp"] - payload["iat"]
    assert 895 <= ttl <= 905  # 15 minutes ± 5 seconds


def test_get_widget_url_includes_token():
    from app.services.oobit_service import get_widget_url
    from app.core.config import settings

    uid = uuid.uuid4()
    with patch.object(settings, "OOBIT_SECRET_KEY", "test-secret"), \
         patch.object(settings, "OOBIT_WIDGET_URL", "https://widget.oobit.com"):
        url = get_widget_url(uid, "test@test.com")

    assert url.startswith("https://widget.oobit.com")
    assert "?token=" in url


def test_generate_widget_token_different_users_produce_different_tokens():
    from app.services.oobit_service import generate_widget_token
    from app.core.config import settings

    with patch.object(settings, "OOBIT_SECRET_KEY", "test-secret"):
        t1 = generate_widget_token(uuid.uuid4(), "a@test.com")
        t2 = generate_widget_token(uuid.uuid4(), "b@test.com")

    assert t1 != t2
