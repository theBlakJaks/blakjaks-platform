"""Translation service — placeholder for Google Cloud Translation API."""

import logging

logger = logging.getLogger(__name__)

# In-memory translation cache (message_id:target_lang -> translated_text)
_translation_cache: dict[str, str] = {}


async def detect_language(text: str) -> str:
    """Detect the language of a message. PLACEHOLDER: always returns 'en'."""
    # TODO: Integrate Google Cloud Translation API detect endpoint
    return "en"


async def translate_message(text: str, source_lang: str, target_lang: str, message_id: str | None = None) -> str:
    """Translate text between languages. PLACEHOLDER: returns original text."""
    if source_lang == target_lang:
        return text

    # Check cache
    if message_id:
        cache_key = f"{message_id}:{target_lang}"
        if cache_key in _translation_cache:
            return _translation_cache[cache_key]

    # TODO: Integrate Google Cloud Translation API
    # For now, return original text with a note
    logger.info("translation_placeholder: %s -> %s for text: %.50s", source_lang, target_lang, text)
    translated = text  # Placeholder — returns original

    # Cache result
    if message_id:
        _translation_cache[f"{message_id}:{target_lang}"] = translated

    return translated
