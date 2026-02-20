"""Tests for app.services.user_service — Member ID generation."""

import re
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.services.user_service import (
    _get_suffix,
    assign_member_id,
    generate_member_id,
    update_member_id_tier_suffix,
)

pytestmark = pytest.mark.asyncio

MEMBER_ID_PATTERN = re.compile(r"^BJ-\d{4}-[A-Z]+$")


# ---------------------------------------------------------------------------
# _get_suffix
# ---------------------------------------------------------------------------


def test_get_suffix_standard():
    assert _get_suffix("standard") == "ST"


def test_get_suffix_vip():
    assert _get_suffix("vip") == "VIP"


def test_get_suffix_high_roller():
    assert _get_suffix("high roller") == "HR"


def test_get_suffix_whale():
    assert _get_suffix("whale") == "WH"


def test_get_suffix_unknown_defaults_to_st():
    assert _get_suffix("diamond") == "ST"


def test_get_suffix_none_defaults_to_st():
    assert _get_suffix(None) == "ST"


def test_get_suffix_case_insensitive():
    assert _get_suffix("VIP") == "VIP"
    assert _get_suffix("Whale") == "WH"
    assert _get_suffix("HIGH ROLLER") == "HR"


# ---------------------------------------------------------------------------
# generate_member_id
# ---------------------------------------------------------------------------


async def _make_db_mock(seq_value: int) -> AsyncMock:
    """Return an AsyncSession mock whose execute().scalar_one() returns seq_value."""
    scalar_result = MagicMock()
    scalar_result.scalar_one.return_value = seq_value

    db = AsyncMock()
    db.execute.return_value = scalar_result
    return db


async def test_generate_member_id_format():
    db = await _make_db_mock(1)
    member_id = await generate_member_id(db)
    assert MEMBER_ID_PATTERN.match(member_id), f"Unexpected format: {member_id}"


async def test_generate_member_id_default_suffix_is_st():
    db = await _make_db_mock(1)
    member_id = await generate_member_id(db)
    assert member_id.endswith("-ST")


async def test_generate_member_id_zero_pads_to_four_digits():
    db = await _make_db_mock(7)
    member_id = await generate_member_id(db, tier_name=None)
    assert member_id == "BJ-0007-ST"


async def test_generate_member_id_large_sequence_number():
    db = await _make_db_mock(9999)
    member_id = await generate_member_id(db)
    assert member_id == "BJ-9999-ST"


async def test_generate_member_id_vip_suffix():
    db = await _make_db_mock(42)
    member_id = await generate_member_id(db, tier_name="vip")
    assert member_id == "BJ-0042-VIP"


async def test_generate_member_id_calls_sequence():
    db = await _make_db_mock(1)
    await generate_member_id(db)
    db.execute.assert_called_once()
    call_args = db.execute.call_args[0][0]
    # Verify the SQL text references the sequence
    assert "nextval" in str(call_args)
    assert "member_id_seq" in str(call_args)


# ---------------------------------------------------------------------------
# assign_member_id
# ---------------------------------------------------------------------------


async def test_assign_member_id_sets_member_id():
    db = await _make_db_mock(5)
    db.commit = AsyncMock()
    db.refresh = AsyncMock()

    user = MagicMock()
    user.member_id = None

    result = await assign_member_id(db, user)

    assert result.member_id == "BJ-0005-ST"
    db.commit.assert_called_once()
    db.refresh.assert_called_once_with(user)


async def test_assign_member_id_skips_if_already_set():
    db = AsyncMock()

    user = MagicMock()
    user.member_id = "BJ-0001-ST"

    result = await assign_member_id(db, user)

    # execute should never be called — user already has a member_id
    db.execute.assert_not_called()
    assert result.member_id == "BJ-0001-ST"


async def test_assign_member_id_with_tier():
    db = await _make_db_mock(10)
    db.commit = AsyncMock()
    db.refresh = AsyncMock()

    user = MagicMock()
    user.member_id = None

    result = await assign_member_id(db, user, tier_name="whale")
    assert result.member_id == "BJ-0010-WH"


# ---------------------------------------------------------------------------
# update_member_id_tier_suffix
# ---------------------------------------------------------------------------


async def test_update_member_id_tier_suffix_changes_suffix():
    db = AsyncMock()
    db.commit = AsyncMock()
    db.refresh = AsyncMock()

    user = MagicMock()
    user.member_id = "BJ-0042-ST"

    result = await update_member_id_tier_suffix(db, user, "vip")

    assert result.member_id == "BJ-0042-VIP"
    db.commit.assert_called_once()


async def test_update_member_id_tier_suffix_preserves_number():
    db = AsyncMock()
    db.commit = AsyncMock()
    db.refresh = AsyncMock()

    user = MagicMock()
    user.member_id = "BJ-0099-ST"

    result = await update_member_id_tier_suffix(db, user, "whale")

    # Number must stay 0099
    assert result.member_id == "BJ-0099-WH"


async def test_update_member_id_tier_suffix_high_roller():
    db = AsyncMock()
    db.commit = AsyncMock()
    db.refresh = AsyncMock()

    user = MagicMock()
    user.member_id = "BJ-0007-VIP"

    result = await update_member_id_tier_suffix(db, user, "high roller")

    assert result.member_id == "BJ-0007-HR"


async def test_update_member_id_tier_suffix_assigns_if_no_member_id():
    """If the user has no member_id yet, fall back to assign_member_id."""
    db = await _make_db_mock(3)
    db.commit = AsyncMock()
    db.refresh = AsyncMock()

    user = MagicMock()
    user.member_id = None

    result = await update_member_id_tier_suffix(db, user, "vip")

    assert result.member_id == "BJ-0003-VIP"


async def test_update_member_id_tier_suffix_unknown_tier_defaults_st():
    db = AsyncMock()
    db.commit = AsyncMock()
    db.refresh = AsyncMock()

    user = MagicMock()
    user.member_id = "BJ-0021-VIP"

    result = await update_member_id_tier_suffix(db, user, "platinum")

    assert result.member_id == "BJ-0021-ST"
