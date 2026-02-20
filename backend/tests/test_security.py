"""Tests for Task A1 — Security Corrections.

Verifies:
- Argon2id is used for new hashes (prefix $argon2id$)
- Correct password verifies successfully
- Wrong password is rejected
- Existing bcrypt hashes migrate transparently via passlib deprecated="auto"
- JWT expiry values match spec (access=15min, refresh=30days)
"""

import time
import uuid
from datetime import datetime, timezone

import pytest
from jose import jwt

from app.core.config import settings
from app.core.security import (
    create_access_token,
    create_refresh_token,
    hash_password,
    verify_password,
)


def test_hash_uses_argon2id():
    hashed = hash_password("hunter2")
    assert hashed.startswith("$argon2id$"), (
        f"Expected Argon2id hash prefix, got: {hashed[:20]}"
    )


def test_correct_password_verifies():
    password = "correct-horse-battery-staple"
    hashed = hash_password(password)
    assert verify_password(password, hashed) is True


def test_wrong_password_rejected():
    hashed = hash_password("correct-password")
    assert verify_password("wrong-password", hashed) is False


def test_bcrypt_hash_migrates():
    """Existing bcrypt hashes must still verify (deprecated='auto' in passlib)."""
    import bcrypt

    password = "legacy-bcrypt-password"
    bcrypt_hash = bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()
    # passlib with deprecated=["bcrypt"] should still verify old bcrypt hashes
    assert verify_password(password, bcrypt_hash) is True


def test_access_token_expiry_is_15_minutes():
    assert settings.ACCESS_TOKEN_EXPIRE_MINUTES == 15, (
        f"Expected 15 minutes, got {settings.ACCESS_TOKEN_EXPIRE_MINUTES}"
    )


def test_refresh_token_expiry_is_30_days():
    assert settings.REFRESH_TOKEN_EXPIRE_DAYS == 30, (
        f"Expected 30 days, got {settings.REFRESH_TOKEN_EXPIRE_DAYS}"
    )


def test_access_token_decode():
    user_id = uuid.uuid4()
    token = create_access_token(user_id)
    payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
    assert payload["sub"] == str(user_id)
    assert payload["type"] == "access"
    # exp should be ~15 minutes from now (within 5 second window)
    expected_exp = datetime.now(timezone.utc).timestamp() + 15 * 60
    assert abs(payload["exp"] - expected_exp) < 5


def test_refresh_token_decode():
    user_id = uuid.uuid4()
    token = create_refresh_token(user_id)
    payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
    assert payload["sub"] == str(user_id)
    assert payload["type"] == "refresh"
    # exp should be ~30 days from now (within 5 second window)
    expected_exp = datetime.now(timezone.utc).timestamp() + 30 * 24 * 3600
    assert abs(payload["exp"] - expected_exp) < 5
