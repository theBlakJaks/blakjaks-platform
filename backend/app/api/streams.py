"""Live stream REST endpoints — public listing and host/admin management."""

import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.models.live_stream import LiveStream
from app.models.user import User
from app.services.livestream_service import (
    create_stream,
    delete_stream,
    end_stream,
    get_active_streams,
    get_stream,
    start_stream,
)

router = APIRouter(prefix="/streams", tags=["streams"])


# ---------------------------------------------------------------------------
# Auth helpers
# ---------------------------------------------------------------------------


def require_admin(user: User = Depends(get_current_user)) -> User:
    if not user.is_admin:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Admin access required")
    return user


def _require_host_or_admin(stream: LiveStream, user: User) -> None:
    """Raise 403 unless the caller is the stream's host or an admin."""
    if not user.is_admin and stream.created_by != user.id:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "Only the stream host or an admin may perform this action",
        )


# ---------------------------------------------------------------------------
# Public endpoints (no auth)
# ---------------------------------------------------------------------------


@router.get("", response_model=None)
async def list_active_streams(
    db: AsyncSession = Depends(get_db),
):
    """List all currently live streams (public, no authentication required)."""
    streams = await get_active_streams(db)
    return [_stream_to_dict(s) for s in streams]


@router.get("/{stream_id}", response_model=None)
async def retrieve_stream(
    stream_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """Get a single stream by ID (public, no authentication required)."""
    stream = await get_stream(db, stream_id)
    if stream is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Stream not found")
    return _stream_to_dict(stream)


# ---------------------------------------------------------------------------
# Authenticated endpoints
# ---------------------------------------------------------------------------


@router.post("", status_code=status.HTTP_201_CREATED, response_model=None)
async def create_new_stream(
    title: str,
    stream_key: str | None = None,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a new stream (any authenticated user)."""
    stream = await create_stream(db, user.id, title, stream_key=stream_key)
    return _stream_to_dict(stream)


@router.post("/{stream_id}/start", response_model=None)
async def start_stream_endpoint(
    stream_id: uuid.UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Mark a stream as live (host or admin only)."""
    stream = await get_stream(db, stream_id)
    if stream is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Stream not found")
    _require_host_or_admin(stream, user)
    updated = await start_stream(db, stream_id)
    return _stream_to_dict(updated)


@router.post("/{stream_id}/end", response_model=None)
async def end_stream_endpoint(
    stream_id: uuid.UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Mark a stream as ended (host or admin only)."""
    stream = await get_stream(db, stream_id)
    if stream is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Stream not found")
    _require_host_or_admin(stream, user)
    updated = await end_stream(db, stream_id)
    return _stream_to_dict(updated)


@router.delete("/{stream_id}", status_code=status.HTTP_200_OK, response_model=None)
async def delete_stream_endpoint(
    stream_id: uuid.UUID,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Delete a stream record (admin only)."""
    deleted = await delete_stream(db, stream_id)
    if not deleted:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Stream not found")
    return {"message": "Stream deleted"}


# ---------------------------------------------------------------------------
# Serialisation helper
# ---------------------------------------------------------------------------


def _stream_to_dict(stream: LiveStream) -> dict:
    return {
        "id": str(stream.id),
        "title": stream.title,
        "description": stream.description,
        "status": stream.status,
        "stream_key": stream.streamyard_broadcast_id,
        "scheduled_at": stream.scheduled_at.isoformat() if stream.scheduled_at else None,
        "started_at": stream.started_at.isoformat() if stream.started_at else None,
        "ended_at": stream.ended_at.isoformat() if stream.ended_at else None,
        "viewer_count": stream.viewer_count,
        "peak_viewers": stream.peak_viewers,
        "hls_url": stream.hls_url,
        "vod_url": stream.vod_url,
        "tier_restriction": stream.tier_restriction,
        "created_by": str(stream.created_by) if stream.created_by else None,
        "created_at": stream.created_at.isoformat() if stream.created_at else None,
    }
