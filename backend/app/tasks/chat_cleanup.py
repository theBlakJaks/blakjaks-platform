"""Nightly chat cleanup tasks.

Tasks:
  - purge_old_messages: batch DELETE messages older than 90 days (1000 rows/iteration)
  - cleanup_orphaned_streams: scan + delete orphaned stream Redis keys
"""

import logging

from app.celery_app import celery_app

logger = logging.getLogger(__name__)

# Messages older than this many days are hard-deleted
RETENTION_DAYS = 90
# Rows deleted per batch to avoid long-running transactions
BATCH_SIZE = 1000


@celery_app.task(name="app.tasks.chat_cleanup.purge_old_messages")
def purge_old_messages():
    """Hard-delete messages older than 90 days in batches of 1000."""
    import asyncio

    asyncio.run(_purge_old_messages_async())


async def _purge_old_messages_async():
    from datetime import datetime, timedelta, timezone

    from sqlalchemy import delete, select, func

    from app.models.message import Message
    from app.db.session import async_session_factory

    cutoff = datetime.now(timezone.utc) - timedelta(days=RETENTION_DAYS)
    total_deleted = 0

    async with async_session_factory() as db:
        while True:
            # Find batch of old message IDs
            stmt = (
                select(Message.id)
                .where(Message.created_at < cutoff)
                .limit(BATCH_SIZE)
            )
            result = await db.execute(stmt)
            ids = [row[0] for row in result.all()]

            if not ids:
                break

            # Delete reactions first (cascade should handle this, but be explicit)
            from app.models.message_reaction import MessageReaction

            await db.execute(
                delete(MessageReaction).where(MessageReaction.message_id.in_(ids))
            )
            await db.execute(delete(Message).where(Message.id.in_(ids)))
            await db.commit()

            total_deleted += len(ids)
            logger.info("Purged %d old messages (batch), total so far: %d", len(ids), total_deleted)

            if len(ids) < BATCH_SIZE:
                break

    logger.info("Chat purge complete — %d messages deleted (cutoff: %s)", total_deleted, cutoff.isoformat())


@celery_app.task(name="app.tasks.chat_cleanup.cleanup_orphaned_streams")
def cleanup_orphaned_streams():
    """Remove Redis stream buffers for streams that no longer exist."""
    import asyncio

    asyncio.run(_cleanup_orphaned_streams_async())


async def _cleanup_orphaned_streams_async():
    from app.services.chat_buffer import cleanup_orphaned_stream_keys

    removed = await cleanup_orphaned_stream_keys()
    if removed:
        logger.info("Cleaned up %d orphaned stream keys", removed)
