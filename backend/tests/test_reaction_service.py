"""Unit tests for app.services.reaction_service.

All tests use AsyncMock / MagicMock — no real database is required.
"""

import uuid
from unittest.mock import AsyncMock, MagicMock

import pytest
from fastapi import HTTPException
from sqlalchemy.exc import IntegrityError

from app.services.reaction_service import add_reaction, get_reactions, remove_reaction

pytestmark = pytest.mark.asyncio


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _make_reaction(message_id: uuid.UUID, user_id: uuid.UUID, emoji: str) -> MagicMock:
    """Return a MagicMock that looks like a MessageReaction ORM object."""
    r = MagicMock()
    r.message_id = message_id
    r.user_id = user_id
    r.emoji = emoji
    return r


def _make_db(
    *,
    scalars: list | None = None,
    scalar_one: object = None,
    commit_raises: Exception | None = None,
) -> AsyncMock:
    """Build a minimal AsyncSession mock.

    - scalar_one_or_none for remove_reaction / get_reactions single-row lookups
    - scalars().all() for get_reactions bulk fetch
    - scalar_one for count queries inside add_reaction
    """
    db = AsyncMock()

    # .commit()
    if commit_raises is not None:
        db.commit.side_effect = commit_raises
    else:
        db.commit.return_value = None

    db.refresh.return_value = None
    db.delete.return_value = None
    db.add.return_value = None
    db.rollback.return_value = None

    # execute() returns different shapes depending on context;
    # we configure side_effect per-test when needed.
    result_mock = MagicMock()
    if scalars is not None:
        result_mock.scalars.return_value.all.return_value = scalars
    if scalar_one is not None:
        result_mock.scalar_one.return_value = scalar_one
    result_mock.scalar_one_or_none.return_value = None

    db.execute.return_value = result_mock
    return db


# ---------------------------------------------------------------------------
# add_reaction
# ---------------------------------------------------------------------------


async def test_add_reaction_returns_dict_with_correct_fields():
    """add_reaction should return a dict with message_id, emoji, count, reacted_by_me=True."""
    message_id = uuid.uuid4()
    user_id = uuid.uuid4()
    emoji = "👍"

    db = AsyncMock()
    db.add.return_value = None
    db.commit.return_value = None
    db.rollback.return_value = None

    # First execute() call is the count query inside add_reaction after commit.
    count_result = MagicMock()
    count_result.scalar_one.return_value = 3
    db.execute.return_value = count_result

    # db.refresh just sets attributes on the reaction object — we don't need it to do anything
    db.refresh.return_value = None

    result = await add_reaction(db, message_id, user_id, emoji)

    assert isinstance(result, dict)
    assert result["message_id"] == message_id
    assert result["emoji"] == emoji
    assert result["count"] == 3
    assert result["reacted_by_me"] is True


async def test_add_reaction_raises_409_on_duplicate():
    """add_reaction should raise HTTPException 409 when IntegrityError is caught."""
    message_id = uuid.uuid4()
    user_id = uuid.uuid4()
    emoji = "🔥"

    db = AsyncMock()
    db.add.return_value = None
    db.rollback.return_value = None

    # Simulate the DB UniqueConstraint violation on commit
    db.commit.side_effect = IntegrityError(
        statement="INSERT INTO message_reactions ...",
        params={},
        orig=Exception("UNIQUE constraint failed"),
    )

    with pytest.raises(HTTPException) as exc_info:
        await add_reaction(db, message_id, user_id, emoji)

    assert exc_info.value.status_code == 409
    db.rollback.assert_called_once()


# ---------------------------------------------------------------------------
# remove_reaction
# ---------------------------------------------------------------------------


async def test_remove_reaction_returns_true_on_success():
    """remove_reaction should return True when the reaction exists and is deleted."""
    message_id = uuid.uuid4()
    user_id = uuid.uuid4()
    emoji = "❤️"

    db = AsyncMock()
    db.commit.return_value = None

    existing_reaction = _make_reaction(message_id, user_id, emoji)
    result_mock = MagicMock()
    result_mock.scalar_one_or_none.return_value = existing_reaction
    db.execute.return_value = result_mock

    removed = await remove_reaction(db, message_id, user_id, emoji)

    assert removed is True
    db.delete.assert_called_once_with(existing_reaction)
    db.commit.assert_called_once()


async def test_remove_reaction_returns_false_when_not_found():
    """remove_reaction should return False when no matching reaction exists."""
    message_id = uuid.uuid4()
    user_id = uuid.uuid4()
    emoji = "😂"

    db = AsyncMock()
    result_mock = MagicMock()
    result_mock.scalar_one_or_none.return_value = None
    db.execute.return_value = result_mock

    removed = await remove_reaction(db, message_id, user_id, emoji)

    assert removed is False
    db.delete.assert_not_called()
    db.commit.assert_not_called()


# ---------------------------------------------------------------------------
# get_reactions
# ---------------------------------------------------------------------------


async def test_get_reactions_returns_empty_list_for_message_with_no_reactions():
    """get_reactions should return [] when there are no reactions for a message."""
    message_id = uuid.uuid4()

    db = AsyncMock()
    result_mock = MagicMock()
    result_mock.scalars.return_value.all.return_value = []
    db.execute.return_value = result_mock

    reactions = await get_reactions(db, message_id)

    assert reactions == []


async def test_get_reactions_returns_grouped_list():
    """get_reactions should group reactions by emoji and return sorted counts."""
    message_id = uuid.uuid4()
    user_a = uuid.uuid4()
    user_b = uuid.uuid4()
    user_c = uuid.uuid4()

    raw_reactions = [
        _make_reaction(message_id, user_a, "👍"),
        _make_reaction(message_id, user_b, "👍"),
        _make_reaction(message_id, user_c, "👍"),
        _make_reaction(message_id, user_a, "❤️"),
    ]

    db = AsyncMock()
    result_mock = MagicMock()
    result_mock.scalars.return_value.all.return_value = raw_reactions
    db.execute.return_value = result_mock

    reactions = await get_reactions(db, message_id)

    assert len(reactions) == 2
    # Sorted by count desc — 👍 (3) should be first
    assert reactions[0]["emoji"] == "👍"
    assert reactions[0]["count"] == 3
    assert reactions[1]["emoji"] == "❤️"
    assert reactions[1]["count"] == 1
    # Each entry has the required keys
    for r in reactions:
        assert "emoji" in r
        assert "count" in r
        assert "reacted_by_me" in r


async def test_get_reactions_reacted_by_me_true_for_requesting_user():
    """get_reactions should set reacted_by_me=True for the requesting user's emoji."""
    message_id = uuid.uuid4()
    my_user_id = uuid.uuid4()
    other_user_id = uuid.uuid4()

    raw_reactions = [
        _make_reaction(message_id, my_user_id, "👍"),
        _make_reaction(message_id, other_user_id, "👍"),
    ]

    db = AsyncMock()
    result_mock = MagicMock()
    result_mock.scalars.return_value.all.return_value = raw_reactions
    db.execute.return_value = result_mock

    reactions = await get_reactions(db, message_id, requesting_user_id=my_user_id)

    assert len(reactions) == 1
    assert reactions[0]["emoji"] == "👍"
    assert reactions[0]["reacted_by_me"] is True


async def test_get_reactions_reacted_by_me_false_for_other_user():
    """get_reactions should set reacted_by_me=False when the requesting user has not reacted."""
    message_id = uuid.uuid4()
    reactor_id = uuid.uuid4()
    observer_id = uuid.uuid4()

    raw_reactions = [
        _make_reaction(message_id, reactor_id, "🔥"),
    ]

    db = AsyncMock()
    result_mock = MagicMock()
    result_mock.scalars.return_value.all.return_value = raw_reactions
    db.execute.return_value = result_mock

    reactions = await get_reactions(db, message_id, requesting_user_id=observer_id)

    assert len(reactions) == 1
    assert reactions[0]["emoji"] == "🔥"
    assert reactions[0]["reacted_by_me"] is False


async def test_get_reactions_reacted_by_me_false_when_no_user_provided():
    """get_reactions should set reacted_by_me=False when requesting_user_id is None."""
    message_id = uuid.uuid4()
    user_id = uuid.uuid4()

    raw_reactions = [
        _make_reaction(message_id, user_id, "😍"),
    ]

    db = AsyncMock()
    result_mock = MagicMock()
    result_mock.scalars.return_value.all.return_value = raw_reactions
    db.execute.return_value = result_mock

    reactions = await get_reactions(db, message_id, requesting_user_id=None)

    assert len(reactions) == 1
    assert reactions[0]["reacted_by_me"] is False
