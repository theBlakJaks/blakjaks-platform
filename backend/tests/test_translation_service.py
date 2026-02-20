"""Tests for translation_service.py — mocks Google Translate, no real API calls."""

import uuid
import pytest
from decimal import Decimal
from unittest.mock import AsyncMock, MagicMock, patch


@pytest.mark.asyncio
async def test_translate_message_returns_none_when_disabled():
    from app.services.translation_service import translate_message
    from app.core.config import settings

    mock_db = AsyncMock()
    with patch.object(settings, "TRANSLATION_ENABLED", False):
        result = await translate_message(mock_db, uuid.uuid4(), "Hello", "es")

    assert result is None


@pytest.mark.asyncio
async def test_translate_message_returns_none_for_unsupported_language():
    from app.services.translation_service import translate_message
    from app.core.config import settings

    mock_db = AsyncMock()
    with patch.object(settings, "TRANSLATION_ENABLED", True), \
         patch.object(settings, "TRANSLATION_SUPPORTED_LANGUAGES", ["en", "es"]):
        result = await translate_message(mock_db, uuid.uuid4(), "Hello", "kl")  # not supported

    assert result is None


@pytest.mark.asyncio
async def test_translate_message_returns_cached_if_exists():
    from app.services.translation_service import translate_message
    from app.core.config import settings
    from app.models.social_message_translation import SocialMessageTranslation

    mock_cached = MagicMock(spec=SocialMessageTranslation)
    mock_cached.translated_text = "Hola"

    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = mock_cached

    mock_db = AsyncMock()
    mock_db.execute = AsyncMock(return_value=mock_result)

    with patch.object(settings, "TRANSLATION_ENABLED", True), \
         patch.object(settings, "TRANSLATION_SUPPORTED_LANGUAGES", ["es"]):
        result = await translate_message(mock_db, uuid.uuid4(), "Hello", "es")

    assert result == "Hola"


@pytest.mark.asyncio
async def test_translate_message_calls_google_on_cache_miss():
    from app.services.translation_service import translate_message
    from app.core.config import settings

    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = None

    mock_db = AsyncMock()
    mock_db.execute = AsyncMock(return_value=mock_result)
    mock_db.add = MagicMock()
    mock_db.commit = AsyncMock()
    mock_db.refresh = AsyncMock()

    mock_client = MagicMock()
    mock_client.translate.return_value = {"translatedText": "Hola mundo"}

    with patch.object(settings, "TRANSLATION_ENABLED", True), \
         patch.object(settings, "TRANSLATION_SUPPORTED_LANGUAGES", ["es"]), \
         patch("app.services.translation_service._get_translate_client", return_value=mock_client):
        result = await translate_message(mock_db, uuid.uuid4(), "Hello world", "es")

    assert result == "Hola mundo"
    mock_db.add.assert_called_once()
    mock_db.commit.assert_called_once()


@pytest.mark.asyncio
async def test_translate_message_returns_none_when_client_unavailable():
    from app.services.translation_service import translate_message
    from app.core.config import settings

    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = None

    mock_db = AsyncMock()
    mock_db.execute = AsyncMock(return_value=mock_result)

    with patch.object(settings, "TRANSLATION_ENABLED", True), \
         patch.object(settings, "TRANSLATION_SUPPORTED_LANGUAGES", ["es"]), \
         patch("app.services.translation_service._get_translate_client", return_value=None):
        result = await translate_message(mock_db, uuid.uuid4(), "Hello", "es")

    assert result is None


@pytest.mark.asyncio
async def test_get_cached_translation_returns_none_when_missing():
    from app.services.translation_service import get_cached_translation

    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = None

    mock_db = AsyncMock()
    mock_db.execute = AsyncMock(return_value=mock_result)

    result = await get_cached_translation(mock_db, uuid.uuid4(), "fr")
    assert result is None


def test_is_supported_language():
    from app.services.translation_service import is_supported_language
    from app.core.config import settings

    with patch.object(settings, "TRANSLATION_SUPPORTED_LANGUAGES", ["en", "es", "fr"]):
        assert is_supported_language("en") is True
        assert is_supported_language("kl") is False


def test_supported_languages_returns_list():
    from app.services.translation_service import supported_languages
    from app.core.config import settings

    with patch.object(settings, "TRANSLATION_SUPPORTED_LANGUAGES", ["en", "es"]):
        langs = supported_languages()

    assert isinstance(langs, list)
    assert "en" in langs
    assert "es" in langs


@pytest.mark.asyncio
async def test_detect_language_returns_en_when_disabled():
    from app.services.translation_service import detect_language
    from app.core.config import settings

    with patch.object(settings, "TRANSLATION_ENABLED", False):
        result = await detect_language("Bonjour")

    assert result == "en"


@pytest.mark.asyncio
async def test_detect_language_returns_en_on_client_failure():
    from app.services.translation_service import detect_language
    from app.core.config import settings

    with patch.object(settings, "TRANSLATION_ENABLED", True), \
         patch("app.services.translation_service._get_translate_client", return_value=None):
        result = await detect_language("Bonjour")

    assert result == "en"
