"""Chat service — channel access, messaging, reactions, moderation."""

import logging
import uuid
from datetime import datetime, timedelta, timezone

from sqlalchemy import and_, delete, func, select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.channel import Channel
from app.models.chat_mute import ChatMute
from app.models.chat_report import ChatReport
from app.models.message import Message
from app.models.message_reaction import MessageReaction
from app.models.tier import Tier
from app.models.user import User
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

# In-memory rate limit tracker: user_id -> last_message_timestamp
_last_message_time: dict[uuid.UUID, datetime] = {}

# In-memory spam tracker: user_id -> list of recent message contents
_recent_messages: dict[uuid.UUID, list[str]] = {}


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


async def _can_access_channel(db: AsyncSession, user_id: uuid.UUID, channel: Channel) -> bool:
    """Check if a user's tier allows access to the channel."""
    required_tier = await _get_channel_tier_name(db, channel)
    if required_tier is None:
        return True
    user_tier = await _get_user_effective_tier_name(db, user_id)
    return _tier_rank(user_tier) >= _tier_rank(required_tier)


async def _can_post(db: AsyncSession, user_id: uuid.UUID) -> bool:
    """Standard members are observational only — cannot post."""
    user_tier = await _get_user_effective_tier_name(db, user_id)
    return user_tier != "Standard"


# ── Channel queries ──────────────────────────────────────────────────


async def get_channels(db: AsyncSession, user_id: uuid.UUID) -> list[dict]:
    """Return all channels the user can access based on their effective tier."""
    user_tier = await _get_user_effective_tier_name(db, user_id)
    user_rank = _tier_rank(user_tier)

    result = await db.execute(
        select(Channel).order_by(Channel.category, Channel.sort_order)
    )
    channels = result.scalars().all()

    accessible = []
    for ch in channels:
        if ch.tier_required_id is not None:
            tier_result = await db.execute(select(Tier).where(Tier.id == ch.tier_required_id))
            tier = tier_result.scalar_one_or_none()
            if tier and _tier_rank(tier.name) > user_rank:
                continue
            tier_name = tier.name if tier else None
        else:
            tier_name = None

        accessible.append({
            "id": ch.id,
            "name": ch.name,
            "description": ch.description,
            "category": ch.category,
            "tier_required": tier_name,
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
            "original_language": msg.original_language,
            "reply_to_id": msg.reply_to_id,
            "reply_preview": reply_preview,
            "reactions": reactions,
            "is_pinned": msg.is_pinned,
            "is_system": msg.is_system,
            "created_at": msg.created_at,
        })

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
) -> Message | str:
    """Send a message. Returns the Message on success, or an error string."""
    # Verify channel
    ch_result = await db.execute(select(Channel).where(Channel.id == channel_id))
    channel = ch_result.scalar_one_or_none()
    if channel is None:
        return "Channel not found"

    # Check tier access
    if not await _can_access_channel(db, user_id, channel):
        return "You do not have access to this channel"

    # Standard members cannot post
    if not await _can_post(db, user_id):
        return "Standard members can view but cannot post messages"

    # Check mute
    mute_msg = await check_mute(db, user_id, channel_id)
    if mute_msg:
        return mute_msg

    # Rate limit
    user_tier = await _get_user_effective_tier_name(db, user_id)
    rate_err = check_rate_limit(user_id, user_tier)
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

    # Update rate limit tracker
    _last_message_time[user_id] = datetime.now(timezone.utc)

    # Track for spam detection
    _recent_messages.setdefault(user_id, []).append(content)
    if len(_recent_messages[user_id]) > SPAM_THRESHOLD:
        _recent_messages[user_id] = _recent_messages[user_id][-SPAM_THRESHOLD:]

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


# ── Rate limit & spam ────────────────────────────────────────────────


def check_rate_limit(user_id: uuid.UUID, tier_name: str) -> str | None:
    """Check if the user can send a message based on tier cooldown. Returns error or None."""
    cooldown = RATE_LIMITS.get(tier_name, 1.0)
    if cooldown == 0.0:
        return None

    last_time = _last_message_time.get(user_id)
    if last_time is None:
        return None

    elapsed = (datetime.now(timezone.utc) - last_time).total_seconds()
    if elapsed < cooldown:
        return f"Rate limited. Please wait {cooldown - elapsed:.1f}s"

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
    recent = _recent_messages.get(user_id, [])
    identical_count = sum(1 for m in recent if m == content)
    if identical_count >= SPAM_THRESHOLD - 1:  # This would be the 5th
        await mute_user(db, user_id, channel_id, SPAM_MUTE_HOURS, "Spam detection: repeated identical messages")
        _recent_messages[user_id] = []
        return "You have been muted for 1 hour due to spam"
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
