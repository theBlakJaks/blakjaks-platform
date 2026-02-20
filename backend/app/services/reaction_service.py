"""Reaction service — add, remove, and retrieve grouped emoji reactions on messages."""

import logging
import uuid

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.message_reaction import MessageReaction

logger = logging.getLogger(__name__)


async def add_reaction(
    db: AsyncSession,
    message_id: uuid.UUID,
    user_id: uuid.UUID,
    emoji: str,
) -> dict:
    """Add an emoji reaction.

    Enforces UNIQUE(message_id, user_id, emoji) via the DB constraint.
    Returns {message_id, emoji, count, reacted_by_me: True} on success.
    Raises HTTPException 409 if the same user already reacted with the same emoji.
    """
    reaction = MessageReaction(message_id=message_id, user_id=user_id, emoji=emoji)
    db.add(reaction)
    try:
        await db.commit()
        await db.refresh(reaction)
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="You have already reacted with this emoji",
        )

    # Count current reactions for this message+emoji
    count_result = await db.execute(
        select(func.count()).where(
            MessageReaction.message_id == message_id,
            MessageReaction.emoji == emoji,
        )
    )
    count = count_result.scalar_one()

    return {
        "message_id": message_id,
        "emoji": emoji,
        "count": count,
        "reacted_by_me": True,
    }


async def remove_reaction(
    db: AsyncSession,
    message_id: uuid.UUID,
    user_id: uuid.UUID,
    emoji: str,
) -> bool:
    """Remove a reaction.

    Returns True if the reaction was found and removed, False if it did not exist.
    """
    result = await db.execute(
        select(MessageReaction).where(
            MessageReaction.message_id == message_id,
            MessageReaction.user_id == user_id,
            MessageReaction.emoji == emoji,
        )
    )
    reaction = result.scalar_one_or_none()
    if reaction is None:
        return False

    await db.delete(reaction)
    await db.commit()
    return True


async def get_reactions(
    db: AsyncSession,
    message_id: uuid.UUID,
    requesting_user_id: uuid.UUID | None = None,
) -> list[dict]:
    """Return grouped reaction counts for a message.

    Returns a list of dicts: [{emoji, count, reacted_by_me: bool}, ...]
    sorted by count descending.  If requesting_user_id is None, reacted_by_me
    is always False.
    """
    result = await db.execute(
        select(MessageReaction).where(MessageReaction.message_id == message_id)
    )
    all_reactions = result.scalars().all()

    if not all_reactions:
        return []

    # Group by emoji
    emoji_map: dict[str, list[uuid.UUID]] = {}
    for r in all_reactions:
        emoji_map.setdefault(r.emoji, []).append(r.user_id)

    grouped = []
    for emoji, user_ids in emoji_map.items():
        reacted_by_me = (requesting_user_id in user_ids) if requesting_user_id is not None else False
        grouped.append(
            {
                "emoji": emoji,
                "count": len(user_ids),
                "reacted_by_me": reacted_by_me,
            }
        )

    # Sort by count descending, then emoji for stable ordering
    grouped.sort(key=lambda x: (-x["count"], x["emoji"]))
    return grouped
