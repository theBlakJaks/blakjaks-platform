"""Chat service — channel access, messaging, reactions, moderation."""

import logging
import time
import uuid
from datetime import datetime, timedelta, timezone

from sqlalchemy import and_, delete, func, select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.channel import Channel
from app.models.channel_tier_access import ChannelTierAccess
from app.models.chat_mute import ChatMute
from app.models.chat_report import ChatReport
from app.models.message import Message
from app.models.message_reaction import MessageReaction
from app.models.tier import Tier
from app.models.user import User
from app.services.chat_buffer import (
    buffer_message,
    check_idempotency,
    next_sequence,
    set_idempotency,
)
from app.services.redis_client import get_redis
from app.services.tier import TIER_ORDER, get_user_tier_info

logger = logging.getLogger(__name__)

# Rate limit cooldowns per tier (seconds)
RATE_LIMITS: dict[str, float] = {
    "Standard": 1.0,
    "VIP": 0.5,
    "High Roller": 0.0,
    "Whale": 0.0,
}

# Spam detection: identical message threshold and mute duration
SPAM_THRESHOLD = 5
SPAM_MUTE_HOURS = 1


# ── Helpers ──────────────────────────────────────────────────────────


def _tier_rank(tier_name: str | None) -> int:
    """Return numeric rank for a tier name. Higher = more access."""
    if tier_name is None:
        return 0
    try:
        return TIER_ORDER.index(tier_name)
    except ValueError:
        return 0


async def _get_user_effective_tier_name(db: AsyncSession, user_id: uuid.UUID) -> str:
    """Get the effective tier name for a user.

    Uses the tier service's dynamic calculation (quarterly scans + affiliate),
    but also checks the user's directly assigned tier_id as a fallback/override.
    Returns whichever tier is higher.
    """
    info = await get_user_tier_info(db, user_id)
    dynamic_tier = info.get("tier_name", "Standard") or "Standard"

    # Also check the user's directly assigned tier (e.g. admin-assigned)
    user_result = await db.execute(select(User).where(User.id == user_id))
    user = user_result.scalar_one_or_none()
    if user and user.tier_id:
        tier_result = await db.execute(select(Tier).where(Tier.id == user.tier_id))
        tier = tier_result.scalar_one_or_none()
        if tier and _tier_rank(tier.name) > _tier_rank(dynamic_tier):
            return tier.name

    return dynamic_tier


async def _get_channel_tier_name(db: AsyncSession, channel: Channel) -> str | None:
    """Get the tier name required for a channel, or None if open."""
    if channel.tier_required_id is None:
        return None
    result = await db.execute(select(Tier).where(Tier.id == channel.tier_required_id))
    tier = result.scalar_one_or_none()
    return tier.name if tier else None


async def _get_channel_access_level(
    db: AsyncSession, user_id: uuid.UUID, channel: Channel
) -> str:
    """Return the access level for a user on a channel.

    Returns 'full', 'view_only', or 'hidden'.
    Falls back to the legacy tier_required_id check, then to 'full'.
    """
    # Get user's effective tier
    user_tier_name = await _get_user_effective_tier_name(db, user_id)

    # Look up the user's tier row
    tier_result = await db.execute(
        select(Tier).where(func.lower(Tier.name) == user_tier_name.lower())
    )
    user_tier = tier_result.scalar_one_or_none()

    if user_tier:
        # Check channel_tier_access table first
        access_result = await db.execute(
            select(ChannelTierAccess).where(
                ChannelTierAccess.channel_id == channel.id,
                ChannelTierAccess.tier_id == user_tier.id,
            )
        )
        access = access_result.scalar_one_or_none()
        if access:
            return access.access_level

    # Fallback: legacy tier_required_id check
    required_tier = await _get_channel_tier_name(db, channel)
    if required_tier is None:
        return "full"
    user_rank = _tier_rank(user_tier_name)
    required_rank = _tier_rank(required_tier)
    if user_rank < required_rank:
        return "hidden"
    return "full"


async def _can_access_channel(db: AsyncSession, user_id: uuid.UUID, channel: Channel) -> bool:
    """Check if a user's tier allows access to the channel."""
    level = await _get_channel_access_level(db, user_id, channel)
    return level != "hidden"


async def _can_post(db: AsyncSession, user_id: uuid.UUID, channel_id: uuid.UUID | None = None) -> bool:
    """Check if a user can post messages in a channel."""
    if channel_id is None:
        return True
    ch_result = await db.execute(select(Channel).where(Channel.id == channel_id))
    channel = ch_result.scalar_one_or_none()
    if channel is None:
        return True
    level = await _get_channel_access_level(db, user_id, channel)
    return level == "full"


# ── Channel queries ──────────────────────────────────────────────────


async def get_channels(db: AsyncSession, user_id: uuid.UUID) -> list[dict]:
    """Return all channels the user can access based on their effective tier."""
    result = await db.execute(
        select(Channel).order_by(Channel.category, Channel.sort_order)
    )
    channels = result.scalars().all()

    accessible = []
    for ch in channels:
        access_level = await _get_channel_access_level(db, user_id, ch)
        if access_level == "hidden":
            continue

        # Get tier name for display
        tier_name = None
        if ch.tier_required_id is not None:
            tier_result = await db.execute(select(Tier).where(Tier.id == ch.tier_required_id))
            tier = tier_result.scalar_one_or_none()
            tier_name = tier.name if tier else None

        accessible.append({
            "id": ch.id,
            "name": ch.name,
            "description": ch.description,
            "category": ch.category,
            "tier_required": tier_name,
            "view_only": access_level == "view_only",
            "unread_count": 0,  # TODO: track per-user read cursors
            "member_count": 0,
        })

    return accessible


# ── Message queries ──────────────────────────────────────────────────


async def get_channel_messages(
    db: AsyncSession,
    channel_id: uuid.UUID,
    user_id: uuid.UUID,
    before_id: uuid.UUID | None = None,
    limit: int = 50,
    since_sequence: int | None = None,
) -> list[dict]:
    """Return paginated messages for a channel (cursor-based via before_id)."""
    # Verify channel exists and user has access
    ch_result = await db.execute(select(Channel).where(Channel.id == channel_id))
    channel = ch_result.scalar_one_or_none()
    if channel is None:
        return []
    if not await _can_access_channel(db, user_id, channel):
        return []

    query = (
        select(Message)
        .where(Message.channel_id == channel_id, Message.is_deleted == False)  # noqa: E712
        .options(selectinload(Message.user), selectinload(Message.reactions).selectinload(MessageReaction.user))
        .order_by(Message.created_at.desc())
        .limit(limit)
    )

    if since_sequence is not None:
        query = query.where(Message.sequence > since_sequence)

    if before_id is not None:
        # Get the created_at of the cursor message
        cursor_result = await db.execute(select(Message.created_at).where(Message.id == before_id))
        cursor_ts = cursor_result.scalar_one_or_none()
        if cursor_ts is not None:
            query = query.where(Message.created_at < cursor_ts)

    result = await db.execute(query)
    messages = result.scalars().all()

    output = []
    for msg in messages:
        # Get reply preview if applicable
        reply_preview = None
        if msg.reply_to_id:
            rp_result = await db.execute(select(Message.content).where(Message.id == msg.reply_to_id))
            rp_content = rp_result.scalar_one_or_none()
            if rp_content:
                reply_preview = rp_content[:100]

        # Build reactions summary
        reaction_map: dict[str, list[str]] = {}
        for r in msg.reactions:
            reaction_map.setdefault(r.emoji, []).append(
                r.user.first_name if r.user and r.user.first_name else "User"
            )

        reactions = [
            {"emoji": emoji, "count": len(users), "users": users}
            for emoji, users in reaction_map.items()
        ]

        # Get user tier name
        user_tier = None
        if msg.user and msg.user.tier_id:
            tier_result = await db.execute(select(Tier.name).where(Tier.id == msg.user.tier_id))
            user_tier = tier_result.scalar_one_or_none()

        output.append({
            "id": msg.id,
            "channel_id": msg.channel_id,
            "user_id": msg.user_id,
            "username": msg.user.username if msg.user else "Unknown",
            "user_tier": user_tier,
            "avatar_url": msg.user.avatar_url if msg.user else None,
            "content": msg.content,
            "sequence": msg.sequence,
            "original_language": msg.original_language,
            "reply_to_id": msg.reply_to_id,
            "reply_preview": reply_preview,
            "reactions": reactions,
            "is_pinned": msg.is_pinned,
            "is_system": msg.is_system,
            "created_at": msg.created_at,
        })

    # Query is DESC (newest first) for cursor pagination, but chat UI
    # renders top-to-bottom, so reverse to chronological order.
    output.reverse()
    return output


async def get_pinned_messages(db: AsyncSession, channel_id: uuid.UUID) -> list[dict]:
    """Return all pinned messages for a channel."""
    result = await db.execute(
        select(Message)
        .where(Message.channel_id == channel_id, Message.is_pinned == True, Message.is_deleted == False)  # noqa: E712
        .options(selectinload(Message.user))
        .order_by(Message.created_at.desc())
    )
    messages = result.scalars().all()
    return [
        {
            "id": m.id,
            "channel_id": m.channel_id,
            "user_id": m.user_id,
            "username": m.user.username if m.user else "Unknown",
            "user_tier": None,
            "avatar_url": m.user.avatar_url if m.user else None,
            "content": m.content,
            "original_language": m.original_language,
            "reply_to_id": m.reply_to_id,
            "reply_preview": None,
            "reactions": [],
            "is_pinned": True,
            "is_system": m.is_system,
            "created_at": m.created_at,
        }
        for m in messages
    ]


# ── Send message ─────────────────────────────────────────────────────


async def send_message(
    db: AsyncSession,
    channel_id: uuid.UUID,
    user_id: uuid.UUID,
    content: str,
    reply_to_id: uuid.UUID | None = None,
    idempotency_key: str | None = None,
) -> Message | str:
    """Send a message. Returns the Message on success, or an error string.

    If ``idempotency_key`` is provided, checks Redis first to prevent
    duplicate processing.  On success, stores the key→message_id mapping
    with a 5-minute TTL and assigns a per-channel sequence number.
    """
    # ── Idempotency check ──
    if idempotency_key:
        try:
            existing_id = await check_idempotency(idempotency_key)
            if existing_id:
                # Return the already-created message
                msg = await db.get(Message, uuid.UUID(existing_id))
                if msg:
                    return msg
        except Exception:
            logger.warning("Idempotency check failed — proceeding normally")

    # Verify channel
    ch_result = await db.execute(select(Channel).where(Channel.id == channel_id))
    channel = ch_result.scalar_one_or_none()
    if channel is None:
        return "Channel not found"

    # Check tier access
    if not await _can_access_channel(db, user_id, channel):
        return "You do not have access to this channel"

    # Check per-channel posting permissions
    if not await _can_post(db, user_id, channel_id):
        return "You can view but cannot post in this channel"

    # Check mute
    mute_msg = await check_mute(db, user_id, channel_id)
    if mute_msg:
        return mute_msg

    # Rate limit
    user_tier = await _get_user_effective_tier_name(db, user_id)
    rate_err = await check_rate_limit(user_id, user_tier)
    if rate_err:
        return rate_err

    # Spam detection
    spam_err = await _check_spam(db, user_id, channel_id, content)
    if spam_err:
        return spam_err

    # Validate content length
    if len(content) > 2000:
        return "Message exceeds 2000 character limit"

    msg = Message(
        channel_id=channel_id,
        user_id=user_id,
        content=content,
        reply_to_id=reply_to_id,
    )
    db.add(msg)
    await db.commit()
    await db.refresh(msg)

    # ── Assign sequence number ──
    try:
        seq = await next_sequence(channel_id)
        msg.sequence = seq
        await db.commit()
    except Exception:
        logger.warning("Failed to assign sequence number — message saved without sequence")

    # ── Store idempotency key ──
    if idempotency_key:
        try:
            await set_idempotency(idempotency_key, str(msg.id))
        except Exception:
            logger.warning("Failed to store idempotency key")

    # Update rate limit and spam trackers in Redis
    try:
        redis = await get_redis()
        # Rate limit: store timestamp, auto-expire after 10s
        await redis.set(f"chat:rate:{user_id}", str(time.time()), ex=10)
        # Spam detection: keep last N messages, expire after 5 minutes
        spam_key = f"chat:spam:{user_id}"
        await redis.lpush(spam_key, content)
        await redis.ltrim(spam_key, 0, SPAM_THRESHOLD - 1)
        await redis.expire(spam_key, 300)
    except Exception:
        logger.warning("Redis unavailable for rate/spam tracking")

    return msg


# ── Reactions ────────────────────────────────────────────────────────


async def add_reaction(db: AsyncSession, message_id: uuid.UUID, user_id: uuid.UUID, emoji: str) -> MessageReaction | str:
    """Add an emoji reaction. Returns the reaction or error string."""
    # Check if message exists
    msg_result = await db.execute(select(Message).where(Message.id == message_id, Message.is_deleted == False))  # noqa: E712
    if msg_result.scalar_one_or_none() is None:
        return "Message not found"

    # Check for duplicate
    existing = await db.execute(
        select(MessageReaction).where(
            MessageReaction.message_id == message_id,
            MessageReaction.user_id == user_id,
            MessageReaction.emoji == emoji,
        )
    )
    if existing.scalar_one_or_none() is not None:
        return "Reaction already exists"

    reaction = MessageReaction(message_id=message_id, user_id=user_id, emoji=emoji)
    db.add(reaction)
    await db.commit()
    await db.refresh(reaction)
    return reaction


async def remove_reaction(db: AsyncSession, message_id: uuid.UUID, user_id: uuid.UUID, emoji: str) -> bool:
    """Remove an emoji reaction. Returns True if removed."""
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


# ── Moderation ───────────────────────────────────────────────────────


async def pin_message(db: AsyncSession, message_id: uuid.UUID) -> bool:
    """Pin a message (admin only — caller must verify)."""
    result = await db.execute(
        update(Message).where(Message.id == message_id).values(is_pinned=True)
    )
    await db.commit()
    return result.rowcount > 0


async def unpin_message(db: AsyncSession, message_id: uuid.UUID) -> bool:
    """Unpin a message (admin only — caller must verify)."""
    result = await db.execute(
        update(Message).where(Message.id == message_id).values(is_pinned=False)
    )
    await db.commit()
    return result.rowcount > 0


async def delete_message(db: AsyncSession, message_id: uuid.UUID, user_id: uuid.UUID, is_admin: bool = False) -> bool:
    """Soft-delete a message. Admins can delete any; users can delete own."""
    if is_admin:
        condition = Message.id == message_id
    else:
        condition = and_(Message.id == message_id, Message.user_id == user_id)

    result = await db.execute(
        update(Message).where(condition).values(is_deleted=True)
    )
    await db.commit()
    return result.rowcount > 0


async def hard_delete_message(
    db: AsyncSession, message_id: uuid.UUID
) -> Message | None:
    """Hard delete a message from PostgreSQL (moderation).

    Returns the deleted Message object (for extracting channel_id and
    sequence) or None if the message was not found.
    """
    result = await db.execute(select(Message).where(Message.id == message_id))
    msg = result.scalar_one_or_none()
    if msg is None:
        return None

    # Capture fields before deletion
    deleted_msg = Message(
        id=msg.id,
        channel_id=msg.channel_id,
        user_id=msg.user_id,
        content=msg.content,
        sequence=msg.sequence,
    )

    await db.execute(delete(Message).where(Message.id == message_id))
    await db.commit()
    return deleted_msg


async def send_livestream_message(
    channel_id: uuid.UUID,
    stream_id: uuid.UUID,
    user_id: uuid.UUID,
    username: str,
    avatar_url: str | None,
    content: str,
) -> dict | str:
    """Send a livestream chat message — Redis only, no PostgreSQL write.

    Returns the message dict on success, or an error string.
    """
    if len(content) > 2000:
        return "Message exceeds 2000 character limit"

    try:
        seq = await next_sequence(channel_id)
    except Exception:
        return "Failed to generate sequence number"

    msg_id = str(uuid.uuid4())
    msg_data = {
        "type": "new_message",
        "id": msg_id,
        "channel_id": str(channel_id),
        "user_id": str(user_id),
        "username": username,
        "avatar_url": avatar_url,
        "content": content,
        "sequence": seq,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "reply_to_id": None,
        "reply_to_content": None,
        "reply_to_username": None,
        "is_system": False,
        "is_pinned": False,
        "idempotency_key": None,
        "status": "sent",
    }

    try:
        await buffer_message(
            channel_id, seq, msg_data, is_livestream=True, stream_id=stream_id
        )
    except Exception:
        logger.warning("Failed to buffer livestream message")

    return msg_data


async def report_message(
    db: AsyncSession, message_id: uuid.UUID, reporter_id: uuid.UUID, reason: str
) -> ChatReport:
    """Create a report for a message."""
    # Get message to find the reported user
    msg_result = await db.execute(select(Message).where(Message.id == message_id))
    msg = msg_result.scalar_one_or_none()
    if msg is None:
        raise ValueError("Message not found")

    report = ChatReport(
        reporter_id=reporter_id,
        message_id=message_id,
        reported_user_id=msg.user_id,
        reason=reason,
    )
    db.add(report)
    await db.commit()
    await db.refresh(report)
    return report


async def mute_user(
    db: AsyncSession, user_id: uuid.UUID, channel_id: uuid.UUID | None, duration_hours: int, reason: str
) -> ChatMute:
    """Mute a user for a given duration."""
    muted_until = datetime.now(timezone.utc) + timedelta(hours=duration_hours)
    mute = ChatMute(
        user_id=user_id,
        channel_id=channel_id,
        muted_until=muted_until,
        reason=reason,
    )
    db.add(mute)
    await db.commit()
    await db.refresh(mute)
    return mute


async def ban_user(db: AsyncSession, user_id: uuid.UUID, reason: str) -> ChatMute:
    """Permanently ban a user (global mute for 100 years)."""
    return await mute_user(db, user_id, None, 876000, reason)


async def delete_user_messages(
    db: AsyncSession, user_id: uuid.UUID, channel_id: uuid.UUID | None = None
) -> int:
    """Soft-delete all messages by a user, optionally scoped to a channel."""
    conditions = [Message.user_id == user_id, Message.is_deleted == False]  # noqa: E712
    if channel_id:
        conditions.append(Message.channel_id == channel_id)

    result = await db.execute(
        update(Message).where(*conditions).values(is_deleted=True)
    )
    await db.commit()
    return result.rowcount


# ── Rate limit & spam ────────────────────────────────────────────────


async def check_rate_limit(user_id: uuid.UUID, tier_name: str) -> str | None:
    """Check if the user can send a message based on tier cooldown. Returns error or None."""
    cooldown = RATE_LIMITS.get(tier_name, 1.0)
    if cooldown == 0.0:
        return None

    try:
        redis = await get_redis()
        key = f"chat:rate:{user_id}"
        last_ts = await redis.get(key)
        if last_ts is not None:
            elapsed = time.time() - float(last_ts)
            if elapsed < cooldown:
                return f"Rate limited. Please wait {cooldown - elapsed:.1f}s"
    except Exception:
        logger.warning("Redis unavailable for rate limit check — allowing message")

    return None


async def check_mute(db: AsyncSession, user_id: uuid.UUID, channel_id: uuid.UUID) -> str | None:
    """Check if user is muted (global or channel-specific). Returns error message or None."""
    now = datetime.now(timezone.utc)
    result = await db.execute(
        select(ChatMute).where(
            ChatMute.user_id == user_id,
            ChatMute.muted_until > now,
            (ChatMute.channel_id == channel_id) | (ChatMute.channel_id.is_(None)),
        )
    )
    mute = result.scalars().first()
    if mute:
        return f"You are muted until {mute.muted_until.isoformat()}. Reason: {mute.reason}"
    return None


async def _check_spam(db: AsyncSession, user_id: uuid.UUID, channel_id: uuid.UUID, content: str) -> str | None:
    """Detect spam (5 identical messages) and auto-mute."""
    try:
        redis = await get_redis()
        key = f"chat:spam:{user_id}"
        recent = await redis.lrange(key, 0, SPAM_THRESHOLD - 1)
        identical_count = sum(1 for m in recent if m == content)
        if identical_count >= SPAM_THRESHOLD - 1:  # This would be the 5th
            await mute_user(db, user_id, channel_id, SPAM_MUTE_HOURS, "Spam detection: repeated identical messages")
            await redis.delete(key)
            return "You have been muted for 1 hour due to spam"
    except Exception:
        logger.warning("Redis unavailable for spam check — skipping")

    return None


# ── Admin queries ────────────────────────────────────────────────────


async def get_reports(db: AsyncSession, status_filter: str | None = None) -> list[ChatReport]:
    """Get all chat reports, optionally filtered by status."""
    query = select(ChatReport).order_by(ChatReport.created_at.desc())
    if status_filter:
        query = query.where(ChatReport.status == status_filter)
    result = await db.execute(query)
    return list(result.scalars().all())


async def update_report_status(db: AsyncSession, report_id: uuid.UUID, new_status: str) -> bool:
    """Update a report's status."""
    result = await db.execute(
        update(ChatReport).where(ChatReport.id == report_id).values(status=new_status)
    )
    await db.commit()
    return result.rowcount > 0
