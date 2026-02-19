"""Username validation, profanity filter, and suggestion generation."""

import random
import re
import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

# Username format: starts with letter or underscore, then letters/numbers/underscores, 4-25 chars
USERNAME_REGEX = re.compile(r'^[a-zA-Z_][a-zA-Z0-9_]{3,24}$')

# Leetspeak normalization map
_LEET_MAP = str.maketrans({
    '0': 'o', '1': 'i', '3': 'e', '4': 'a', '5': 's',
    '7': 't', '@': 'a', '$': 's', '!': 'i', '+': 't',
})

# Common profane terms (lowercase). This list is checked after leetspeak normalization.
_PROFANE_WORDS: set[str] = {
    "fuck", "shit", "ass", "bitch", "dick", "cock", "pussy", "cunt",
    "damn", "bastard", "whore", "slut", "piss", "tits", "boob",
    "penis", "vagina", "anus", "dildo", "fag", "homo",
    "wank", "jizz", "cum", "semen", "blowjob", "handjob",
    "motherfucker", "asshole", "bullshit", "horseshit", "dumbass",
    "jackass", "dipshit", "shithead", "fuckface", "dickhead",
    "twat", "prick", "douche", "skank", "tramp",
}

# Severe terms checked as substrings (even within longer words)
_SEVERE_SUBSTRINGS: list[str] = [
    "nigger", "nigga", "faggot", "retard", "nazi", "hitler",
    "kkk", "jihad", "rape", "molest", "pedo", "necro",
]

# Reserved usernames
_RESERVED: set[str] = {
    "admin", "administrator", "moderator", "mod",
    "blakjaks", "blakjak", "blackjack", "blackjacks",
    "system", "support", "help", "official",
    "staff", "team", "ceo", "founder",
    "null", "undefined", "deleted", "anonymous",
    "root", "superuser", "bot", "daemon",
    "everyone", "here", "channel",
}


def validate_username_format(username: str) -> dict:
    """Validate username format. Returns {valid: bool, error?: str}."""
    if len(username) < 4:
        return {"valid": False, "error": "Must be at least 4 characters"}
    if len(username) > 25:
        return {"valid": False, "error": "Must be 25 characters or less"}
    if username[0].isdigit():
        return {"valid": False, "error": "Cannot start with a number"}
    if not re.match(r'^[a-zA-Z0-9_]+$', username):
        return {"valid": False, "error": "Only letters, numbers, and underscores allowed"}
    if not USERNAME_REGEX.match(username):
        return {"valid": False, "error": "Invalid username format"}
    return {"valid": True}


def _normalize_leetspeak(text: str) -> str:
    """Convert leetspeak to regular letters for profanity checking."""
    return text.translate(_LEET_MAP)


def is_profane(username: str) -> bool:
    """Check if username contains profanity. Returns True if should be REJECTED."""
    lower = username.lower()
    # Strip underscores to catch p_r_o_f_a_n_e
    stripped = re.sub(r'[_]', '', lower)
    # Normalize leetspeak
    normalized = _normalize_leetspeak(stripped)

    # Check all three forms against word list
    for form in (lower, stripped, normalized):
        if form in _PROFANE_WORDS:
            return True
        # Also check if any profane word is a substring
        for word in _PROFANE_WORDS:
            if len(word) >= 4 and word in form:
                return True

    # Check severe substrings against all forms
    for term in _SEVERE_SUBSTRINGS:
        for form in (lower, stripped, normalized):
            if term in form:
                return True

    return False


def is_reserved(username: str) -> bool:
    """Check if username is reserved."""
    return username.lower() in _RESERVED


async def generate_suggestions(base: str, db: AsyncSession) -> list[str]:
    """Generate up to 3 available username suggestions based on the given base."""
    from app.models.user import User

    suggestions: list[str] = []
    attempts = 0
    max_attempts = 20

    while len(suggestions) < 3 and attempts < max_attempts:
        attempts += 1
        suffix = random.randint(1, 99)
        candidate = f"{base}_{suffix}" if random.random() > 0.5 else f"{base}{suffix}"

        # Must still be valid length
        if len(candidate) > 25:
            candidate = f"{base[:20]}{suffix}"

        # Check DB
        result = await db.execute(
            select(User.id).where(User.username_lower == candidate.lower()).limit(1)
        )
        if result.scalar_one_or_none() is None:
            suggestions.append(candidate)

    return suggestions
