"""Redis-backed message buffer and sequence numbering for real-time chat.

Redis Key Schema (Chat Reliability)
====================================
channel:{channel_id}:seq              — INT    — Per-channel monotonic sequence counter (INCR)
channel:{channel_id}:messages         — ZSET   — Message buffer; score=sequence, value=JSON.
                                                 Trimmed to 500 entries. TTL 90 days.
stream:{stream_id}:messages           — ZSET   — Livestream message buffer; score=sequence,
                                                 value=JSON. No TTL (deleted on stream end).
msg:idem:{idempotency_key}            — STRING — Idempotency dedup. Value=server message ID.
                                                 TTL 5 minutes.
channel:{channel_id}:presence         — SET    — User IDs currently in channel (see chat_presence.py).
presence:{channel_id}:{user_id}       — STRING — Heartbeat key, 60s TTL (see chat_presence.py).
chat:rate:{user_id}                   — STRING — Rate limit timestamp (existing, 10s TTL).
chat:spam:{user_id}                   — LIST   — Recent message content for spam detection
                                                 (existing, 5m TTL).
"""

from __future__ import annotations

import json
import logging
import uuid

from app.services.redis_client import get_redis

logger = logging.getLogger(__name__)

# Buffer limits
MAX_BUFFER_SIZE = 500
BUFFER_TTL_SECONDS = 90 * 24 * 60 * 60  # 90 days
IDEMPOTENCY_TTL_SECONDS = 300  # 5 minutes


async def next_sequence(channel_id: uuid.UUID) -> int:
    """Atomically increment and return the next sequence number for a channel.

    Sequence numbers are per-channel and stored in Redis as a counter.
    They start at 1, never 0. Redis INCR guarantees atomicity.
    """
    redis = await get_redis()
    key = f"channel:{channel_id}:seq"
    return await redis.incr(key)


async def buffer_message(
    channel_id: uuid.UUID,
    sequence: int,
    message_json: dict,
    *,
    is_livestream: bool = False,
    stream_id: uuid.UUID | None = None,
) -> None:
    """Store a message in the Redis sorted set buffer.

    Uses a Redis pipeline so ZADD, ZREMRANGEBYRANK, and EXPIRE execute
    atomically in a single round-trip — prevents a race where a crash
    between ZADD and ZREMRANGEBYRANK leaves the buffer over 500 entries.

    Args:
        channel_id: The channel this message belongs to.
        sequence: The sequence number (used as the sorted set score).
        message_json: Full message payload to store.
        is_livestream: If True, use stream-specific key with no TTL.
        stream_id: Required if is_livestream is True.
    """
    redis = await get_redis()

    if is_livestream and stream_id:
        key = f"stream:{stream_id}:messages"
    else:
        key = f"channel:{channel_id}:messages"

    value = json.dumps(message_json, default=str)

    async with redis.pipeline(transaction=True) as pipe:
        pipe.zadd(key, {value: sequence})
        # Keep only the newest MAX_BUFFER_SIZE entries.
        # ZREMRANGEBYRANK removes by rank (0 = lowest score = oldest).
        # Keeping ranks -(MAX_BUFFER_SIZE) to -1 means keep newest 500.
        pipe.zremrangebyrank(key, 0, -(MAX_BUFFER_SIZE + 1))
        if not is_livestream:
            pipe.expire(key, BUFFER_TTL_SECONDS)
        await pipe.execute()


async def get_messages_after(
    channel_id: uuid.UUID,
    after_sequence: int,
    *,
    is_livestream: bool = False,
    stream_id: uuid.UUID | None = None,
) -> list[dict]:
    """Fetch all buffered messages with sequence > after_sequence.

    Returns parsed JSON dicts sorted by sequence ascending.
    """
    redis = await get_redis()

    if is_livestream and stream_id:
        key = f"stream:{stream_id}:messages"
    else:
        key = f"channel:{channel_id}:messages"

    # ZRANGEBYSCORE returns members with score in (after_sequence, +inf)
    # Using exclusive lower bound via '(' prefix
    raw = await redis.zrangebyscore(key, f"({after_sequence}", "+inf")

    messages = []
    for item in raw:
        try:
            messages.append(json.loads(item))
        except (json.JSONDecodeError, TypeError):
            logger.warning("Corrupt message in buffer key %s, skipping", key)
    return messages


async def get_buffer_range(
    channel_id: uuid.UUID,
    *,
    is_livestream: bool = False,
    stream_id: uuid.UUID | None = None,
) -> tuple[int | None, int | None]:
    """Return (min_sequence, max_sequence) of the buffer, or (None, None) if empty."""
    redis = await get_redis()

    if is_livestream and stream_id:
        key = f"stream:{stream_id}:messages"
    else:
        key = f"channel:{channel_id}:messages"

    # Get first and last entries with scores
    first = await redis.zrange(key, 0, 0, withscores=True)
    last = await redis.zrange(key, -1, -1, withscores=True)

    if not first or not last:
        return None, None

    return int(first[0][1]), int(last[0][1])


async def remove_message_by_sequence(
    channel_id: uuid.UUID,
    sequence: int,
) -> int:
    """Remove a message from the buffer by its exact sequence number.

    Returns the number of entries removed (0 or 1).
    """
    redis = await get_redis()
    key = f"channel:{channel_id}:messages"
    return await redis.zremrangebyscore(key, sequence, sequence)


async def check_idempotency(idempotency_key: str) -> str | None:
    """Check if an idempotency key has been seen before.

    Returns the server message ID if the key exists, None otherwise.
    """
    redis = await get_redis()
    return await redis.get(f"msg:idem:{idempotency_key}")


async def set_idempotency(idempotency_key: str, message_id: str) -> None:
    """Store an idempotency key → message ID mapping with 5-minute TTL."""
    redis = await get_redis()
    await redis.set(
        f"msg:idem:{idempotency_key}",
        message_id,
        ex=IDEMPOTENCY_TTL_SECONDS,
    )


async def cleanup_stream_buffer(stream_id: uuid.UUID) -> None:
    """Delete the Redis sorted set for a ended livestream."""
    redis = await get_redis()
    await redis.delete(f"stream:{stream_id}:messages")


async def cleanup_orphaned_stream_keys() -> int:
    """Scan for stream:*:messages keys and delete any whose stream is not live.

    Called on server startup to clean up after ungraceful shutdowns.
    Returns the number of orphaned keys deleted.
    """
    # Import here to avoid circular imports
    from app.db.session import async_session_factory

    redis = await get_redis()
    deleted = 0

    cursor = 0
    while True:
        cursor, keys = await redis.scan(cursor, match="stream:*:messages", count=100)
        for key in keys:
            # Extract stream_id from key pattern "stream:{uuid}:messages"
            parts = key.split(":")
            if len(parts) != 3:
                continue
            stream_id_str = parts[1]
            try:
                stream_id = uuid.UUID(stream_id_str)
            except ValueError:
                continue

            # Check if stream is still live in the database
            try:
                async with async_session_factory() as db:
                    from sqlalchemy import select, text
                    # Use raw SQL to avoid importing the LiveStream model
                    # which may not exist in all environments
                    result = await db.execute(
                        text("SELECT status FROM live_streams WHERE id = :sid"),
                        {"sid": stream_id},
                    )
                    row = result.first()
                    if row is None or row[0] != "live":
                        await redis.delete(key)
                        deleted += 1
                        logger.info("Deleted orphaned stream buffer: %s", key)
            except Exception:
                # If the live_streams table doesn't exist, skip
                logger.debug("Could not check stream %s — skipping", stream_id_str)

        if cursor == 0:
            break

    return deleted
