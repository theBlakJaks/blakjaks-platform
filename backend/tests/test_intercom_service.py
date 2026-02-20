"""Tests for intercom_service.py — mocks httpx, no real Intercom calls."""

import uuid
import pytest
from unittest.mock import AsyncMock, MagicMock, patch


def test_generate_identity_hash_returns_none_when_not_configured():
    from app.services.intercom_service import generate_identity_hash
    from app.core.config import settings

    with patch.object(settings, "INTERCOM_IDENTITY_VERIFICATION_SECRET", ""):
        result = generate_identity_hash(uuid.uuid4())

    assert result is None


def test_generate_identity_hash_returns_hex_string():
    from app.services.intercom_service import generate_identity_hash
    from app.core.config import settings

    uid = uuid.uuid4()
    with patch.object(settings, "INTERCOM_IDENTITY_VERIFICATION_SECRET", "test-secret"):
        result = generate_identity_hash(uid)

    assert isinstance(result, str)
    assert len(result) == 64  # SHA-256 hex = 64 chars
    # Verify it's hex
    int(result, 16)


def test_generate_identity_hash_is_deterministic():
    from app.services.intercom_service import generate_identity_hash
    from app.core.config import settings

    uid = uuid.uuid4()
    with patch.object(settings, "INTERCOM_IDENTITY_VERIFICATION_SECRET", "secret"):
        h1 = generate_identity_hash(uid)
        h2 = generate_identity_hash(uid)

    assert h1 == h2


def test_generate_identity_hash_differs_per_user():
    from app.services.intercom_service import generate_identity_hash
    from app.core.config import settings

    with patch.object(settings, "INTERCOM_IDENTITY_VERIFICATION_SECRET", "secret"):
        h1 = generate_identity_hash(uuid.uuid4())
        h2 = generate_identity_hash(uuid.uuid4())

    assert h1 != h2


def test_get_widget_config_includes_required_fields():
    from app.services.intercom_service import get_widget_config
    from app.core.config import settings

    uid = uuid.uuid4()
    with patch.object(settings, "INTERCOM_APP_ID", "app123"), \
         patch.object(settings, "INTERCOM_IDENTITY_VERIFICATION_SECRET", "secret"), \
         patch.object(settings, "INTERCOM_IOS_API_KEY", "ios-key"), \
         patch.object(settings, "INTERCOM_ANDROID_API_KEY", "and-key"):
        config = get_widget_config(uid, "user@test.com", name="Test User")

    assert config["app_id"] == "app123"
    assert config["user_id"] == str(uid)
    assert config["email"] == "user@test.com"
    assert config["name"] == "Test User"
    assert config["user_hash"] is not None  # secret is set
    assert config["ios_api_key"] == "ios-key"
    assert config["android_api_key"] == "and-key"


@pytest.mark.asyncio
async def test_create_or_update_contact_returns_none_when_not_configured():
    from app.services.intercom_service import create_or_update_contact
    from app.core.config import settings

    with patch.object(settings, "INTERCOM_API_KEY", ""):
        result = await create_or_update_contact(uuid.uuid4(), "test@test.com", "Test")

    assert result is None


@pytest.mark.asyncio
async def test_create_or_update_contact_success():
    from app.services.intercom_service import create_or_update_contact
    from app.core.config import settings

    uid = uuid.uuid4()
    mock_resp = MagicMock()
    mock_resp.raise_for_status = MagicMock()
    mock_resp.json.return_value = {"id": "intercom_contact_001", "email": "test@test.com"}

    mock_client = AsyncMock()
    mock_client.__aenter__ = AsyncMock(return_value=mock_client)
    mock_client.__aexit__ = AsyncMock(return_value=False)
    mock_client.post = AsyncMock(return_value=mock_resp)

    with patch.object(settings, "INTERCOM_API_KEY", "test-key"), \
         patch("app.services.intercom_service.httpx.AsyncClient", return_value=mock_client):
        result = await create_or_update_contact(uid, "test@test.com", "Test User")

    assert result is not None
    assert result["id"] == "intercom_contact_001"


@pytest.mark.asyncio
async def test_create_or_update_contact_returns_none_on_error():
    from app.services.intercom_service import create_or_update_contact
    from app.core.config import settings

    mock_client = AsyncMock()
    mock_client.__aenter__ = AsyncMock(return_value=mock_client)
    mock_client.__aexit__ = AsyncMock(return_value=False)
    mock_client.post = AsyncMock(side_effect=Exception("connection error"))

    with patch.object(settings, "INTERCOM_API_KEY", "test-key"), \
         patch("app.services.intercom_service.httpx.AsyncClient", return_value=mock_client):
        result = await create_or_update_contact(uuid.uuid4(), "x@test.com", "X")

    assert result is None


@pytest.mark.asyncio
async def test_track_event_returns_none_when_not_configured():
    from app.services.intercom_service import track_event
    from app.core.config import settings

    with patch.object(settings, "INTERCOM_API_KEY", ""):
        result = await track_event(uuid.uuid4(), "scan_completed")

    assert result is None
