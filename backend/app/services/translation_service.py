"""Google Cloud Translation service for social message internationalization.

Translates chat messages on-demand and caches results in the
social_message_translations table.  Falls back gracefully when the
Translation API is not configured.

Settings used:
  TRANSLATION_ENABLED              — global kill-switch
  TRANSLATION_GOOGLE_PROJECT_ID    — GCP project ID
  TRANSLATION_GOOGLE_CREDENTIALS_PATH — optional service-account JSON path
  TRANSLATION_SUPPORTED_LANGUAGES  — list of ISO 639-1 codes we will serve
"""

import logging
import uuid
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.social_message_translation import SocialMessageTranslation

logger = logging.getLogger(__name__)


def _get_translate_client():
    """Lazy-load Google Cloud Translate client.

    Returns the client or None if the library / credentials are unavailable.
    """
    try:
        from google.cloud import translate_v2 as translate  # type: ignore
        import os

        if settings.TRANSLATION_GOOGLE_CREDENTIALS_PATH:
            os.environ.setdefault(
                "GOOGLE_APPLICATION_CREDENTIALS",
                settings.TRANSLATION_GOOGLE_CREDENTIALS_PATH,
            )

        return translate.Client()
    except Exception as exc:
        logger.warning("Google Translate client unavailable: %s", exc)
        return None


async def detect_language(text: str) -> str:
    """Detect the language of a given text string.

    Returns the detected ISO 639-1 language code, or 'en' on failure.
    """
    if not settings.TRANSLATION_ENABLED:
        return "en"

    client = _get_translate_client()
    if client is None:
        return "en"

    try:
        result = client.detect_language(text)
        return result.get("language", "en")
    except Exception as exc:
        logger.warning("Language detection failed: %s", exc)
        return "en"


async def translate_message(
    db: AsyncSession,
    message_id: uuid.UUID,
    source_text: str,
    target_language: str,
) -> str | None:
    """Translate a social message to the requested language.

    Checks the DB cache first.  On miss, calls Google Translate and stores
    the result.

    Args:
        db: Async database session.
        message_id: UUID of the social Message row.
        source_text: Original message text to translate.
        target_language: ISO 639-1 target language code (e.g. "es", "fr").

    Returns:
        Translated text, or None if translation is disabled/unavailable.
    """
    if not settings.TRANSLATION_ENABLED:
        return None

    if target_language not in settings.TRANSLATION_SUPPORTED_LANGUAGES:
        logger.debug("Unsupported language requested: %s", target_language)
        return None

    # Check DB cache
    result = await db.execute(
        select(SocialMessageTranslation).where(
            SocialMessageTranslation.message_id == message_id,
            SocialMessageTranslation.language == target_language,
        )
    )
    cached = result.scalar_one_or_none()
    if cached:
        return cached.translated_text

    # Call Google Translate
    client = _get_translate_client()
    if client is None:
        return None

    try:
        response = client.translate(
            source_text,
            target_language=target_language,
            source_language="en",
        )
        translated = response["translatedText"]
    except Exception as exc:
        logger.error("Google Translate API error for message %s: %s", message_id, exc)
        return None

    # Persist to DB cache
    row = SocialMessageTranslation(
        message_id=message_id,
        language=target_language,
        translated_text=translated,
        translated_at=datetime.now(timezone.utc),
    )
    db.add(row)
    try:
        await db.commit()
        await db.refresh(row)
    except Exception as exc:
        logger.warning("Could not cache translation for message %s: %s", message_id, exc)
        await db.rollback()

    return translated


async def get_cached_translation(
    db: AsyncSession,
    message_id: uuid.UUID,
    language: str,
) -> str | None:
    """Return a cached translation without calling the external API.

    Args:
        db: Async database session.
        message_id: UUID of the social Message row.
        language: ISO 639-1 language code.

    Returns:
        Translated text if cached, else None.
    """
    result = await db.execute(
        select(SocialMessageTranslation).where(
            SocialMessageTranslation.message_id == message_id,
            SocialMessageTranslation.language == language,
        )
    )
    row = result.scalar_one_or_none()
    return row.translated_text if row else None


def is_supported_language(language: str) -> bool:
    """Return True if the language code is in our supported list."""
    return language in settings.TRANSLATION_SUPPORTED_LANGUAGES


def supported_languages() -> list[str]:
    """Return the list of supported language codes."""
    return list(settings.TRANSLATION_SUPPORTED_LANGUAGES)
