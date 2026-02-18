"""Seed default community channels.

Revision ID: b7c8d9e0f1g2
Revises: a1b2c3d4e5f6
"""
from typing import Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import UUID

revision: str = "b7c8d9e0f1g2"
down_revision: Union[str, None] = "c3d4e5f6g7h8"


def upgrade() -> None:
    conn = op.get_bind()

    # Look up tier IDs
    tiers = conn.execute(sa.text("SELECT id, name FROM tiers")).fetchall()
    tier_map = {name: str(tid) for tid, name in tiers}

    vip_id = tier_map.get("VIP")
    high_roller_id = tier_map.get("High Roller")
    whale_id = tier_map.get("Whale")

    channels = [
        # General
        ("announcements", "Official BlakJaks announcements", "General", None, True, 0),
        ("general-chat", "General community chat", "General", None, False, 1),
        ("introductions", "Introduce yourself to the community", "General", None, False, 2),
        # High Roller Lounge
        ("vip-chat", "VIP members chat", "High Roller Lounge", vip_id, False, 0),
        ("high-roller-chat", "High Roller exclusive chat", "High Roller Lounge", high_roller_id, False, 1),
        # Comps & Crypto
        ("comp-claims", "Celebrate your comp wins", "Comps & Crypto", None, False, 0),
        ("wallet-talk", "Crypto and wallet discussion", "Comps & Crypto", None, False, 1),
        # Governance
        ("proposals", "Submit and discuss governance proposals", "Governance", None, False, 0),
        ("voting", "Active votes and results", "Governance", None, False, 1),
        # Whale Lounge
        ("whale-room", "Whale exclusive lounge", "Whale Lounge", whale_id, False, 0),
    ]

    for name, desc, category, tier_id, is_locked, sort in channels:
        if tier_id:
            conn.execute(
                sa.text(
                    "INSERT INTO channels (id, name, description, category, tier_required_id, is_locked, sort_order, created_at) "
                    "VALUES (gen_random_uuid(), :name, :desc, :category, :tier_id, :locked, :sort, now())"
                ),
                {"name": name, "desc": desc, "category": category, "tier_id": tier_id, "locked": is_locked, "sort": sort},
            )
        else:
            conn.execute(
                sa.text(
                    "INSERT INTO channels (id, name, description, category, is_locked, sort_order, created_at) "
                    "VALUES (gen_random_uuid(), :name, :desc, :category, :locked, :sort, now())"
                ),
                {"name": name, "desc": desc, "category": category, "locked": is_locked, "sort": sort},
            )


def downgrade() -> None:
    conn = op.get_bind()
    names = [
        "announcements", "general-chat", "introductions",
        "vip-chat", "high-roller-chat",
        "comp-claims", "wallet-talk",
        "proposals", "voting",
        "whale-room",
    ]
    for name in names:
        conn.execute(sa.text("DELETE FROM channels WHERE name = :name"), {"name": name})
