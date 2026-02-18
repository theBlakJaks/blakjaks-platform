"""Tests for Social Hub & Real-Time Chat (Task 13)."""

import uuid
from datetime import datetime, timedelta, timezone

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token, hash_password
from app.models.channel import Channel
from app.models.chat_mute import ChatMute
from app.models.message import Message
from app.models.user import User
from app.services.chat_service import (
    _last_message_time,
    _recent_messages,
    add_reaction,
    check_rate_limit,
    delete_message,
    get_channel_messages,
    get_channels,
    get_pinned_messages,
    mute_user,
    pin_message,
    remove_reaction,
    report_message,
    send_message,
    unpin_message,
)
from app.services.wallet_service import create_user_wallet
from tests.conftest import seed_tiers

pytestmark = pytest.mark.asyncio


# ── Helpers ──────────────────────────────────────────────────────────


async def _create_user_with_tier(db: AsyncSession, email: str, tier_name: str) -> User:
    """Create a user and assign them to a specific tier."""
    from sqlalchemy import select
    from app.models.tier import Tier

    # Ensure tiers are seeded
    tier_result = await db.execute(select(Tier).where(Tier.name == tier_name))
    tier = tier_result.scalar_one_or_none()
    if tier is None:
        await seed_tiers(db)
        tier_result = await db.execute(select(Tier).where(Tier.name == tier_name))
        tier = tier_result.scalar_one_or_none()

    user = User(
        email=email,
        password_hash=hash_password("password123"),
        first_name=email.split("@")[0].capitalize(),
        last_name="Tester",
        tier_id=tier.id if tier else None,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    await create_user_wallet(db, user.id, email=email)
    return user


async def _create_channel(
    db: AsyncSession, name: str, category: str = "General", tier_required_id=None, is_locked: bool = False
) -> Channel:
    ch = Channel(
        name=name, description=f"Test channel {name}", category=category,
        tier_required_id=tier_required_id, is_locked=is_locked, sort_order=0,
    )
    db.add(ch)
    await db.commit()
    await db.refresh(ch)
    return ch


def _auth_headers_for(user: User) -> dict:
    token = create_access_token(user.id)
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture(autouse=True)
def _clear_rate_limit_state():
    """Clear in-memory rate limit / spam state between tests."""
    _last_message_time.clear()
    _recent_messages.clear()
    yield
    _last_message_time.clear()
    _recent_messages.clear()


# ── Channel access by tier ───────────────────────────────────────────


async def test_standard_sees_public_channels_only(db: AsyncSession):
    await seed_tiers(db)
    from sqlalchemy import select
    from app.models.tier import Tier

    hr_tier = (await db.execute(select(Tier).where(Tier.name == "High Roller"))).scalar_one()
    whale_tier = (await db.execute(select(Tier).where(Tier.name == "Whale"))).scalar_one()

    await _create_channel(db, "general-chat")
    await _create_channel(db, "high-roller-chat", tier_required_id=hr_tier.id)
    await _create_channel(db, "whale-room", tier_required_id=whale_tier.id)

    user = await _create_user_with_tier(db, "standard@test.com", "Standard")
    channels = await get_channels(db, user.id)
    names = [c["name"] for c in channels]
    assert "general-chat" in names
    assert "high-roller-chat" not in names
    assert "whale-room" not in names


async def test_vip_sees_public_and_vip_channels(db: AsyncSession):
    await seed_tiers(db)
    from sqlalchemy import select
    from app.models.tier import Tier

    vip_tier = (await db.execute(select(Tier).where(Tier.name == "VIP"))).scalar_one()
    whale_tier = (await db.execute(select(Tier).where(Tier.name == "Whale"))).scalar_one()

    await _create_channel(db, "general-chat")
    await _create_channel(db, "vip-chat", tier_required_id=vip_tier.id)
    await _create_channel(db, "whale-room", tier_required_id=whale_tier.id)

    user = await _create_user_with_tier(db, "vip@test.com", "VIP")
    channels = await get_channels(db, user.id)
    names = [c["name"] for c in channels]
    assert "general-chat" in names
    assert "vip-chat" in names
    assert "whale-room" not in names


async def test_whale_sees_all_channels(db: AsyncSession):
    await seed_tiers(db)
    from sqlalchemy import select
    from app.models.tier import Tier

    vip_tier = (await db.execute(select(Tier).where(Tier.name == "VIP"))).scalar_one()
    hr_tier = (await db.execute(select(Tier).where(Tier.name == "High Roller"))).scalar_one()
    whale_tier = (await db.execute(select(Tier).where(Tier.name == "Whale"))).scalar_one()

    await _create_channel(db, "general-chat")
    await _create_channel(db, "vip-chat", tier_required_id=vip_tier.id)
    await _create_channel(db, "hr-chat", tier_required_id=hr_tier.id)
    await _create_channel(db, "whale-room", tier_required_id=whale_tier.id)

    user = await _create_user_with_tier(db, "whale@test.com", "Whale")
    channels = await get_channels(db, user.id)
    names = [c["name"] for c in channels]
    assert "general-chat" in names
    assert "vip-chat" in names
    assert "hr-chat" in names
    assert "whale-room" in names


# ── Message pagination ───────────────────────────────────────────────


async def test_get_channel_messages_paginated(db: AsyncSession):
    await seed_tiers(db)
    user = await _create_user_with_tier(db, "paginate@test.com", "VIP")
    ch = await _create_channel(db, "msg-test")

    # Create 5 messages
    msgs = []
    for i in range(5):
        m = Message(channel_id=ch.id, user_id=user.id, content=f"Message {i}")
        db.add(m)
        await db.commit()
        await db.refresh(m)
        msgs.append(m)

    # Get latest 3
    result = await get_channel_messages(db, ch.id, user.id, limit=3)
    assert len(result) == 3


# ── Sending messages ─────────────────────────────────────────────────


async def test_vip_can_post_to_public_channel(db: AsyncSession):
    await seed_tiers(db)
    user = await _create_user_with_tier(db, "vippost@test.com", "VIP")
    ch = await _create_channel(db, "public-chat")

    result = await send_message(db, ch.id, user.id, "Hello from VIP!")
    assert isinstance(result, Message)
    assert result.content == "Hello from VIP!"


async def test_standard_cannot_post(db: AsyncSession):
    await seed_tiers(db)
    user = await _create_user_with_tier(db, "stdpost@test.com", "Standard")
    ch = await _create_channel(db, "public-chat2")

    result = await send_message(db, ch.id, user.id, "Trying to post")
    assert isinstance(result, str)
    assert "observational" in result.lower() or "cannot post" in result.lower()


async def test_vip_cannot_post_to_high_roller_channel(db: AsyncSession):
    await seed_tiers(db)
    from sqlalchemy import select
    from app.models.tier import Tier

    hr_tier = (await db.execute(select(Tier).where(Tier.name == "High Roller"))).scalar_one()

    user = await _create_user_with_tier(db, "viphr@test.com", "VIP")
    ch = await _create_channel(db, "hr-only", tier_required_id=hr_tier.id)

    result = await send_message(db, ch.id, user.id, "Trying to get in")
    assert isinstance(result, str)
    assert "access" in result.lower()


async def test_message_exceeds_2000_chars(db: AsyncSession):
    await seed_tiers(db)
    user = await _create_user_with_tier(db, "longmsg@test.com", "VIP")
    ch = await _create_channel(db, "limit-test")

    result = await send_message(db, ch.id, user.id, "x" * 2001)
    assert isinstance(result, str)
    assert "2000" in result


# ── Mute ─────────────────────────────────────────────────────────────


async def test_muted_user_cannot_post(db: AsyncSession):
    await seed_tiers(db)
    user = await _create_user_with_tier(db, "muted@test.com", "VIP")
    ch = await _create_channel(db, "mute-test")

    await mute_user(db, user.id, ch.id, 1, "Test mute")

    result = await send_message(db, ch.id, user.id, "Should fail")
    assert isinstance(result, str)
    assert "muted" in result.lower()


# ── Reactions ────────────────────────────────────────────────────────


async def test_add_reaction(db: AsyncSession):
    await seed_tiers(db)
    user = await _create_user_with_tier(db, "react@test.com", "VIP")
    ch = await _create_channel(db, "react-test")

    msg = await send_message(db, ch.id, user.id, "React to this!")
    assert isinstance(msg, Message)

    reaction = await add_reaction(db, msg.id, user.id, "👍")
    from app.models.message_reaction import MessageReaction
    assert isinstance(reaction, MessageReaction)
    assert reaction.emoji == "👍"


async def test_duplicate_reaction_prevented(db: AsyncSession):
    await seed_tiers(db)
    user = await _create_user_with_tier(db, "dupreact@test.com", "VIP")
    ch = await _create_channel(db, "dup-react-test")

    msg = await send_message(db, ch.id, user.id, "Try double react")
    assert isinstance(msg, Message)

    await add_reaction(db, msg.id, user.id, "🔥")
    result = await add_reaction(db, msg.id, user.id, "🔥")
    assert isinstance(result, str)
    assert "already exists" in result.lower()


async def test_remove_reaction(db: AsyncSession):
    await seed_tiers(db)
    user = await _create_user_with_tier(db, "rmreact@test.com", "VIP")
    ch = await _create_channel(db, "rm-react-test")

    msg = await send_message(db, ch.id, user.id, "Remove reaction")
    assert isinstance(msg, Message)

    await add_reaction(db, msg.id, user.id, "❤️")
    removed = await remove_reaction(db, msg.id, user.id, "❤️")
    assert removed is True

    # Second removal should fail
    removed = await remove_reaction(db, msg.id, user.id, "❤️")
    assert removed is False


# ── Delete message ───────────────────────────────────────────────────


async def test_delete_own_message(db: AsyncSession):
    await seed_tiers(db)
    user = await _create_user_with_tier(db, "delown@test.com", "VIP")
    ch = await _create_channel(db, "del-own-test")

    msg = await send_message(db, ch.id, user.id, "Delete me")
    assert isinstance(msg, Message)

    deleted = await delete_message(db, msg.id, user.id)
    assert deleted is True


async def test_non_admin_cannot_delete_others_message(db: AsyncSession):
    await seed_tiers(db)
    user1 = await _create_user_with_tier(db, "poster@test.com", "VIP")
    user2 = await _create_user_with_tier(db, "deleter@test.com", "VIP")
    ch = await _create_channel(db, "del-other-test")

    msg = await send_message(db, ch.id, user1.id, "Don't delete me")
    assert isinstance(msg, Message)

    deleted = await delete_message(db, msg.id, user2.id, is_admin=False)
    assert deleted is False


async def test_admin_can_delete_any_message(db: AsyncSession):
    await seed_tiers(db)
    user = await _create_user_with_tier(db, "poster2@test.com", "VIP")
    admin = await _create_user_with_tier(db, "admin@test.com", "VIP")
    admin.is_admin = True
    await db.commit()

    ch = await _create_channel(db, "admin-del-test")
    msg = await send_message(db, ch.id, user.id, "Admin will delete")
    assert isinstance(msg, Message)

    deleted = await delete_message(db, msg.id, admin.id, is_admin=True)
    assert deleted is True


# ── Pin / Unpin ──────────────────────────────────────────────────────


async def test_pin_and_unpin_message(db: AsyncSession):
    await seed_tiers(db)
    user = await _create_user_with_tier(db, "pinner@test.com", "VIP")
    ch = await _create_channel(db, "pin-test")

    msg = await send_message(db, ch.id, user.id, "Pin me!")
    assert isinstance(msg, Message)

    pinned = await pin_message(db, msg.id)
    assert pinned is True

    pinned_msgs = await get_pinned_messages(db, ch.id)
    assert len(pinned_msgs) == 1
    assert pinned_msgs[0]["content"] == "Pin me!"

    unpinned = await unpin_message(db, msg.id)
    assert unpinned is True

    pinned_msgs = await get_pinned_messages(db, ch.id)
    assert len(pinned_msgs) == 0


# ── Report ───────────────────────────────────────────────────────────


async def test_report_message(db: AsyncSession):
    await seed_tiers(db)
    user = await _create_user_with_tier(db, "baduser@test.com", "VIP")
    reporter = await _create_user_with_tier(db, "reporter@test.com", "VIP")
    ch = await _create_channel(db, "report-test")

    msg = await send_message(db, ch.id, user.id, "Offensive content")
    assert isinstance(msg, Message)

    report = await report_message(db, msg.id, reporter.id, "This is offensive")
    assert report.status == "pending"
    assert report.reporter_id == reporter.id
    assert report.reported_user_id == user.id


# ── Admin mute ───────────────────────────────────────────────────────


async def test_admin_can_mute_user(db: AsyncSession):
    await seed_tiers(db)
    user = await _create_user_with_tier(db, "mutetarget@test.com", "VIP")

    mute = await mute_user(db, user.id, None, 2, "Being rude")
    assert mute.reason == "Being rude"
    # SQLite returns naive datetimes; compare accordingly
    now = datetime.now(timezone.utc)
    muted = mute.muted_until if mute.muted_until.tzinfo else mute.muted_until.replace(tzinfo=timezone.utc)
    assert muted > now


# ── API endpoints ────────────────────────────────────────────────────


async def test_channels_api(client: AsyncClient, db: AsyncSession):
    await seed_tiers(db)
    user = await _create_user_with_tier(db, "apiuser@test.com", "VIP")
    await _create_channel(db, "api-channel")

    headers = _auth_headers_for(user)
    resp = await client.get("/api/social/channels", headers=headers)
    assert resp.status_code == 200
    assert any(c["name"] == "api-channel" for c in resp.json())


async def test_post_message_api(client: AsyncClient, db: AsyncSession):
    await seed_tiers(db)
    user = await _create_user_with_tier(db, "apipost@test.com", "VIP")
    ch = await _create_channel(db, "api-post-channel")

    headers = _auth_headers_for(user)
    resp = await client.post(
        f"/api/social/channels/{ch.id}/messages",
        headers=headers,
        json={"content": "Hello from API!"},
    )
    assert resp.status_code == 201
    assert resp.json()["content"] == "Hello from API!"


async def test_standard_post_message_api_forbidden(client: AsyncClient, db: AsyncSession):
    await seed_tiers(db)
    user = await _create_user_with_tier(db, "stdapi@test.com", "Standard")
    ch = await _create_channel(db, "api-std-channel")

    headers = _auth_headers_for(user)
    resp = await client.post(
        f"/api/social/channels/{ch.id}/messages",
        headers=headers,
        json={"content": "Should fail"},
    )
    assert resp.status_code == 403
