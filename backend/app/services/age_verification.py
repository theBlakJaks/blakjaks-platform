"""Age verification via AgeChecker.net — placeholder for now.

Real integration will happen when we build the iOS checkout flow.
"""


async def verify_age(verification_id: str) -> bool:
    """Validate an age verification ID from AgeChecker.net.

    Placeholder: accepts any non-empty string.
    """
    return bool(verification_id and verification_id.strip())
