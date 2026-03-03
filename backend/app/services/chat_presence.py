"""Presence tracking for real-time chat.

Uses a Redis set per channel for connected user IDs, with individual
heartbeat keys (60s TTL) to handle crash scenarios where the disconnect
event never fires. Lazy cleanup removes expired members on read.

Redis Keys:
    channel:{channel_id}:presence         — SET of user_id strings
    presence:{channel_id}:{user_id}       — STRING heartbeat (60s TTL)
"""

from __future__ import annotations

import logging
import uuid

from app.services.redis_client import get_redis

logger = logging.getLogger(__name__)

PRESENCE_TTL_SECONDS = 60


async def add_presence(channel_id: uuid.UUID, user_id: uuid.UUID) -> None:
    """Mark a user as present in a channel.

    Adds user_id to the channel presence set and creates a heartbeat key
    with 60-second TTL.
    """
    redis = await get_redis()
    async with redis.pipeline(transaction=True) as pipe:
        pipe.sadd(f"channel:{channel_id}:presence", str(user_id))
        pipe.set(
            f"presence:{channel_id}:{user_id}",
            "1",
            ex=PRESENCE_TTL_SECONDS,
        )
        await pipe.execute()


async def remove_presence(channel_id: uuid.UUID, user_id: uuid.UUID) -> None:
    """Remove a user from a channel's presence set and delete their heartbeat key."""
    redis = await get_redis()
    async with redis.pipeline(transaction=True) as pipe:
        pipe.srem(f"channel:{channel_id}:presence", str(user_id))
        pipe.delete(f"presence:{channel_id}:{user_id}")
        await pipe.execute()


async def refresh_presence(channel_id: uuid.UUID, user_id: uuid.UUID) -> None:
    """Refresh the heartbeat TTL for a user in a channel.

    Called on every pong response. If the heartbeat key had already expired
    (crash recovery), re-adds the user to the presence set.
    """
    redis = await get_redis()
    key = f"presence:{channel_id}:{user_id}"

    # Reset TTL
    renewed = await redis.expire(key, PRESENCE_TTL_SECONDS)
    if not renewed:
        # Key had expired — re-add to the presence set
        async with redis.pipeline(transaction=True) as pipe:
            pipe.sadd(f"channel:{channel_id}:presence", str(user_id))
            pipe.set(key, "1", ex=PRESENCE_TTL_SECONDS)
            await pipe.execute()


async def get_present_users(channel_id: uuid.UUID) -> list[str]:
    """Return list of user_id strings currently present in a channel.

    Performs lazy cleanup: any member whose heartbeat key has expired
    is removed from the set before returning.
    """
    redis = await get_redis()
    set_key = f"channel:{channel_id}:presence"
    members = await redis.smembers(set_key)
    if not members:
        return []

    # Check heartbeat keys in a single pipeline
    async with redis.pipeline(transaction=False) as pipe:
        for uid in members:
            pipe.exists(f"presence:{channel_id}:{uid}")
        results = await pipe.execute()

    active = []
    expired = []
    for uid, exists in zip(members, results):
        if exists:
            active.append(uid)
        else:
            expired.append(uid)

    # Lazy cleanup: remove expired members
    if expired:
        await redis.srem(set_key, *expired)
        logger.debug(
            "Cleaned up %d expired presence entries for channel %s",
            len(expired),
            channel_id,
        )

    return active


async def cleanup_expired_presence(channel_id: uuid.UUID) -> list[uuid.UUID]:
    """Explicitly clean up expired presence entries for a channel.

    Returns list of user_ids that were removed (for broadcasting
    presence_update events).
    """
    redis = await get_redis()
    set_key = f"channel:{channel_id}:presence"
    members = await redis.smembers(set_key)
    if not members:
        return []

    async with redis.pipeline(transaction=False) as pipe:
        for uid in members:
            pipe.exists(f"presence:{channel_id}:{uid}")
        results = await pipe.execute()

    removed = []
    for uid, exists in zip(members, results):
        if not exists:
            removed.append(uuid.UUID(uid))

    if removed:
        await redis.srem(set_key, *[str(uid) for uid in removed])

    return removed
