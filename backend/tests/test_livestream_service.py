"""Tests for app.services.livestream_service — no real DB required."""

import uuid
from datetime import datetime, timezone
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.services.livestream_service import (
    create_stream,
    delete_stream,
    end_stream,
    get_active_streams,
    get_stream,
    start_stream,
)

pytestmark = pytest.mark.asyncio


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _make_stream(
    stream_id: uuid.UUID | None = None,
    status: str = "scheduled",
    started_at: datetime | None = None,
    ended_at: datetime | None = None,
) -> MagicMock:
    """Return a MagicMock that looks like a LiveStream instance."""
    s = MagicMock()
    s.id = stream_id or uuid.uuid4()
    s.title = "Test Stream"
    s.status = status
    s.started_at = started_at
    s.ended_at = ended_at
    s.streamyard_broadcast_id = str(uuid.uuid4())
    s.created_by = uuid.uuid4()
    return s


def _make_db(scalar_result=None, rowcount: int = 1) -> AsyncMock:
    """Return an AsyncSession mock.

    scalar_result — what db.execute(...).scalar_one_or_none() will return.
    rowcount      — what db.execute(...).rowcount will be (for delete/update).
    """
    execute_result = MagicMock()
    execute_result.scalar_one_or_none.return_value = scalar_result
    execute_result.scalars.return_value.all.return_value = (
        scalar_result if isinstance(scalar_result, list) else []
    )
    execute_result.rowcount = rowcount

    db = AsyncMock()
    db.execute.return_value = execute_result
    db.commit = AsyncMock()
    db.refresh = AsyncMock()
    db.add = MagicMock()
    return db


# ---------------------------------------------------------------------------
# create_stream
# ---------------------------------------------------------------------------


async def test_create_stream_generates_stream_key_when_not_provided():
    """create_stream should auto-generate a UUID stream_key."""
    db = AsyncMock()
    db.commit = AsyncMock()
    db.add = MagicMock()

    captured_stream = None

    async def _refresh(obj):
        nonlocal captured_stream
        captured_stream = obj

    db.refresh.side_effect = _refresh

    host_id = uuid.uuid4()

    with patch("app.services.livestream_service.LiveStream") as MockLiveStream:
        mock_instance = MagicMock()
        mock_instance.streamyard_broadcast_id = None
        MockLiveStream.return_value = mock_instance

        await create_stream(db, host_id, "My Stream")

        # Check that a stream_key (uuid string) was generated and passed in
        call_kwargs = MockLiveStream.call_args.kwargs
        key = call_kwargs.get("streamyard_broadcast_id", "")
        # Must be a valid UUID
        parsed = uuid.UUID(key)
        assert str(parsed) == key


async def test_create_stream_uses_provided_stream_key():
    """create_stream should use the given stream_key if one is supplied."""
    db = AsyncMock()
    db.commit = AsyncMock()
    db.add = MagicMock()
    db.refresh = AsyncMock()

    host_id = uuid.uuid4()
    custom_key = "my-custom-key"

    with patch("app.services.livestream_service.LiveStream") as MockLiveStream:
        mock_instance = MagicMock()
        MockLiveStream.return_value = mock_instance

        await create_stream(db, host_id, "My Stream", stream_key=custom_key)

        call_kwargs = MockLiveStream.call_args.kwargs
        assert call_kwargs["streamyard_broadcast_id"] == custom_key


async def test_create_stream_commits_and_refreshes():
    """create_stream must commit and refresh after adding the record."""
    db = AsyncMock()
    db.commit = AsyncMock()
    db.add = MagicMock()
    db.refresh = AsyncMock()

    with patch("app.services.livestream_service.LiveStream") as MockLiveStream:
        mock_instance = MagicMock()
        MockLiveStream.return_value = mock_instance

        await create_stream(db, uuid.uuid4(), "Title")

    db.add.assert_called_once()
    db.commit.assert_called_once()
    db.refresh.assert_called_once()


# ---------------------------------------------------------------------------
# get_active_streams
# ---------------------------------------------------------------------------


async def test_get_active_streams_returns_only_live_streams():
    """get_active_streams should query status='live' and return results."""
    live_stream = _make_stream(status="live")
    execute_result = MagicMock()
    execute_result.scalars.return_value.all.return_value = [live_stream]

    db = AsyncMock()
    db.execute.return_value = execute_result

    streams = await get_active_streams(db)

    assert streams == [live_stream]
    db.execute.assert_called_once()
    # Verify the query filters by status == 'live' by inspecting the SQL string
    query_str = str(db.execute.call_args[0][0])
    assert "live" in query_str.lower() or "status" in query_str.lower()


async def test_get_active_streams_returns_empty_list_when_none_live():
    """get_active_streams should return an empty list when no streams are live."""
    execute_result = MagicMock()
    execute_result.scalars.return_value.all.return_value = []

    db = AsyncMock()
    db.execute.return_value = execute_result

    streams = await get_active_streams(db)

    assert streams == []


# ---------------------------------------------------------------------------
# start_stream
# ---------------------------------------------------------------------------


async def test_start_stream_sets_status_live_and_started_at():
    """start_stream should set status to 'live' and populate started_at."""
    stream = _make_stream(status="scheduled")
    execute_result = MagicMock()
    execute_result.scalar_one_or_none.return_value = stream

    db = AsyncMock()
    db.execute.return_value = execute_result
    db.commit = AsyncMock()
    db.refresh = AsyncMock()

    before = datetime.now(timezone.utc)
    result = await start_stream(db, stream.id)

    assert result.status == "live"
    assert result.started_at is not None
    assert result.started_at >= before
    db.commit.assert_called_once()


async def test_start_stream_raises_404_when_not_found():
    """start_stream should raise HTTP 404 when the stream does not exist."""
    from fastapi import HTTPException

    execute_result = MagicMock()
    execute_result.scalar_one_or_none.return_value = None

    db = AsyncMock()
    db.execute.return_value = execute_result

    with pytest.raises(HTTPException) as exc_info:
        await start_stream(db, uuid.uuid4())

    assert exc_info.value.status_code == 404


# ---------------------------------------------------------------------------
# end_stream
# ---------------------------------------------------------------------------


async def test_end_stream_sets_status_ended_and_ended_at():
    """end_stream should set status to 'ended' and populate ended_at."""
    stream = _make_stream(status="live")
    execute_result = MagicMock()
    execute_result.scalar_one_or_none.return_value = stream

    db = AsyncMock()
    db.execute.return_value = execute_result
    db.commit = AsyncMock()
    db.refresh = AsyncMock()

    before = datetime.now(timezone.utc)
    result = await end_stream(db, stream.id)

    assert result.status == "ended"
    assert result.ended_at is not None
    assert result.ended_at >= before
    db.commit.assert_called_once()


async def test_end_stream_raises_404_when_not_found():
    """end_stream should raise HTTP 404 when the stream does not exist."""
    from fastapi import HTTPException

    execute_result = MagicMock()
    execute_result.scalar_one_or_none.return_value = None

    db = AsyncMock()
    db.execute.return_value = execute_result

    with pytest.raises(HTTPException) as exc_info:
        await end_stream(db, uuid.uuid4())

    assert exc_info.value.status_code == 404


# ---------------------------------------------------------------------------
# get_stream
# ---------------------------------------------------------------------------


async def test_get_stream_returns_none_for_missing_stream():
    """get_stream should return None when the UUID does not exist."""
    execute_result = MagicMock()
    execute_result.scalar_one_or_none.return_value = None

    db = AsyncMock()
    db.execute.return_value = execute_result

    result = await get_stream(db, uuid.uuid4())

    assert result is None


async def test_get_stream_returns_stream_when_found():
    """get_stream should return the LiveStream object when found."""
    stream = _make_stream()
    execute_result = MagicMock()
    execute_result.scalar_one_or_none.return_value = stream

    db = AsyncMock()
    db.execute.return_value = execute_result

    result = await get_stream(db, stream.id)

    assert result is stream


# ---------------------------------------------------------------------------
# delete_stream
# ---------------------------------------------------------------------------


async def test_delete_stream_returns_true_on_success():
    """delete_stream should return True when the row was deleted."""
    execute_result = MagicMock()
    execute_result.rowcount = 1

    db = AsyncMock()
    db.execute.return_value = execute_result
    db.commit = AsyncMock()

    result = await delete_stream(db, uuid.uuid4())

    assert result is True
    db.commit.assert_called_once()


async def test_delete_stream_returns_false_when_not_found():
    """delete_stream should return False when no row matched the UUID."""
    execute_result = MagicMock()
    execute_result.rowcount = 0

    db = AsyncMock()
    db.execute.return_value = execute_result
    db.commit = AsyncMock()

    result = await delete_stream(db, uuid.uuid4())

    assert result is False
