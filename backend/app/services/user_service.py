import sqlalchemy as sa
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User

TIER_SUFFIXES = {
    "standard": "ST",
    "vip": "VIP",
    "high roller": "HR",
    "whale": "WH",
}


async def generate_member_id(db: AsyncSession, tier_name: str | None = None) -> str:
    """Generate a new unique member ID using the member_id_seq PostgreSQL sequence.

    Uses SELECT nextval('member_id_seq') to get the next sequential number.
    Format: BJ-XXXX-{SUFFIX} where XXXX is zero-padded to 4 digits.
    """
    result = await db.execute(sa.text("SELECT nextval('member_id_seq')"))
    seq_num = result.scalar_one()
    suffix = _get_suffix(tier_name)
    return f"BJ-{seq_num:04d}-{suffix}"


async def assign_member_id(db: AsyncSession, user: User, tier_name: str | None = None) -> User:
    """Assign a new member ID to a user who doesn't have one yet."""
    if user.member_id:
        return user
    user.member_id = await generate_member_id(db, tier_name)
    await db.commit()
    await db.refresh(user)
    return user


async def update_member_id_tier_suffix(db: AsyncSession, user: User, new_tier_name: str) -> User:
    """Update the tier suffix in a user's member ID when their tier changes.

    The sequential number stays the same; only the suffix changes.
    """
    if not user.member_id:
        return await assign_member_id(db, user, new_tier_name)
    # Extract number, rebuild with new suffix
    parts = user.member_id.split("-")
    # Format: ['BJ', 'XXXX', 'SUFFIX'] → number is parts[1]
    number_str = parts[1] if len(parts) >= 2 else "0000"
    try:
        number = int(number_str)
    except ValueError:
        number = 0
    suffix = _get_suffix(new_tier_name)
    user.member_id = f"BJ-{number:04d}-{suffix}"
    await db.commit()
    await db.refresh(user)
    return user


def _get_suffix(tier_name: str | None) -> str:
    if not tier_name:
        return "ST"
    return TIER_SUFFIXES.get(tier_name.lower(), "ST")
