"""Live stream service — CRUD operations for live_streams table."""

import uuid
from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.live_stream import LiveStream


async def create_stream(
    db: AsyncSession,
    host_user_id: uuid.UUID,
    title: str,
    stream_key: str | None = None,
) -> LiveStream:
    """Create a new stream record. Generates a UUID stream_key if not provided.

    The stream_key is stored in the streamyard_broadcast_id field (no dedicated
    stream_key column exists in the live_streams table).
    """
    if stream_key is None:
        stream_key = str(uuid.uuid4())

    stream = LiveStream(
        title=title,
        created_by=host_user_id,
        status="scheduled",
        streamyard_broadcast_id=stream_key,
    )
    db.add(stream)
    await db.commit()
    await db.refresh(stream)
    return stream


async def get_active_streams(db: AsyncSession) -> list[LiveStream]:
    """Return all streams where status='live', ordered by started_at desc."""
    result = await db.execute(
        select(LiveStream)
        .where(LiveStream.status == "live")
        .order_by(LiveStream.started_at.desc())
    )
    return list(result.scalars().all())


async def start_stream(db: AsyncSession, stream_id: uuid.UUID) -> LiveStream:
    """Mark a stream as live (status='live', started_at=now). Raises 404 if not found."""
    stream = await get_stream(db, stream_id)
    if stream is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Stream not found")

    stream.status = "live"
    stream.started_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(stream)
    return stream


async def end_stream(db: AsyncSession, stream_id: uuid.UUID) -> LiveStream:
    """Mark a stream as ended (status='ended', ended_at=now). Raises 404 if not found."""
    stream = await get_stream(db, stream_id)
    if stream is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Stream not found")

    stream.status = "ended"
    stream.ended_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(stream)
    return stream


async def get_stream(db: AsyncSession, stream_id: uuid.UUID) -> LiveStream | None:
    """Fetch a single stream by UUID. Returns None if not found."""
    result = await db.execute(
        select(LiveStream).where(LiveStream.id == stream_id)
    )
    return result.scalar_one_or_none()


async def delete_stream(db: AsyncSession, stream_id: uuid.UUID) -> bool:
    """Delete a stream record. Returns True if deleted, False if not found."""
    result = await db.execute(
        delete(LiveStream).where(LiveStream.id == stream_id)
    )
    await db.commit()
    return result.rowcount > 0
