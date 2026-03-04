"""Restructure channels into tier categories and update votes schema

Revision ID: 028
Revises: 027
Create Date: 2026-03-03

- Adds room_type column to channels
- Deletes existing channels/messages/channel_tier_access and seeds 11 new channels
- Replaces vote_type/min_tier_required/proposal_id with target_tiers JSONB
- Drops governance_proposals table
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

revision = "028"
down_revision = "027"
branch_labels = None
depends_on = None


def upgrade():
    # ── Channels ──────────────────────────────────────────────────────────
    # Add room_type column
    op.add_column(
        "channels",
        sa.Column("room_type", sa.String(20), server_default="chat", nullable=False),
    )

    # Clear dependent data (FK cascade)
    op.execute("DELETE FROM messages")
    op.execute("DELETE FROM channel_tier_access")
    op.execute("DELETE FROM channels")

    # Look up tier IDs
    op.execute("""
        DO $$
        DECLARE
            vip_id UUID;
            high_roller_id UUID;
            whale_id UUID;
        BEGIN
            SELECT id INTO vip_id FROM tiers WHERE name = 'VIP';
            SELECT id INTO high_roller_id FROM tiers WHERE name = 'High Roller';
            SELECT id INTO whale_id FROM tiers WHERE name = 'Whale';

            -- Standard channels (no tier required)
            INSERT INTO channels (id, name, description, category, tier_required_id, is_locked, sort_order, room_type, created_at)
            VALUES
                (gen_random_uuid(), 'general-chat', 'General community chat', 'Standard', NULL, false, 0, 'chat', now()),
                (gen_random_uuid(), 'announcements', 'Official BlakJaks announcements', 'Standard', NULL, true, 1, 'announcements', now());

            -- VIP channels
            INSERT INTO channels (id, name, description, category, tier_required_id, is_locked, sort_order, room_type, created_at)
            VALUES
                (gen_random_uuid(), 'general-chat', 'VIP community chat', 'VIP', vip_id, false, 0, 'chat', now()),
                (gen_random_uuid(), 'announcements', 'VIP announcements', 'VIP', vip_id, true, 1, 'announcements', now()),
                (gen_random_uuid(), 'governance', 'VIP governance polls', 'VIP', vip_id, true, 2, 'governance', now());

            -- High Roller channels
            INSERT INTO channels (id, name, description, category, tier_required_id, is_locked, sort_order, room_type, created_at)
            VALUES
                (gen_random_uuid(), 'general-chat', 'High Roller community chat', 'High Roller', high_roller_id, false, 0, 'chat', now()),
                (gen_random_uuid(), 'announcements', 'High Roller announcements', 'High Roller', high_roller_id, true, 1, 'announcements', now()),
                (gen_random_uuid(), 'governance', 'High Roller governance polls', 'High Roller', high_roller_id, true, 2, 'governance', now());

            -- Whale channels
            INSERT INTO channels (id, name, description, category, tier_required_id, is_locked, sort_order, room_type, created_at)
            VALUES
                (gen_random_uuid(), 'general-chat', 'Whale exclusive chat', 'Whale', whale_id, false, 0, 'chat', now()),
                (gen_random_uuid(), 'announcements', 'Whale announcements', 'Whale', whale_id, true, 1, 'announcements', now()),
                (gen_random_uuid(), 'governance', 'Whale governance polls', 'Whale', whale_id, true, 2, 'governance', now());
        END $$;
    """)

    # ── Votes ─────────────────────────────────────────────────────────────
    # Add target_tiers as nullable first
    op.add_column("votes", sa.Column("target_tiers", JSONB, nullable=True))

    # Migrate existing vote_type values
    op.execute("""
        UPDATE votes SET target_tiers = '["VIP", "High Roller", "Whale"]'::jsonb
        WHERE vote_type = 'flavor'
    """)
    op.execute("""
        UPDATE votes SET target_tiers = '["High Roller", "Whale"]'::jsonb
        WHERE vote_type = 'product'
    """)
    op.execute("""
        UPDATE votes SET target_tiers = '["High Roller", "Whale"]'::jsonb
        WHERE vote_type = 'loyalty'
    """)
    op.execute("""
        UPDATE votes SET target_tiers = '["Whale"]'::jsonb
        WHERE vote_type = 'corporate'
    """)

    # Default any remaining NULLs
    op.execute("""
        UPDATE votes SET target_tiers = '["VIP", "High Roller", "Whale"]'::jsonb
        WHERE target_tiers IS NULL
    """)

    # Make NOT NULL
    op.alter_column("votes", "target_tiers", nullable=False)

    # Drop old columns
    op.drop_column("votes", "vote_type")
    op.drop_column("votes", "min_tier_required")

    # Drop proposal_id FK and column
    op.drop_constraint("votes_proposal_id_fkey", "votes", type_="foreignkey")
    op.drop_column("votes", "proposal_id")

    # Drop governance_proposals table
    op.drop_table("governance_proposals")


def downgrade():
    # Recreate governance_proposals (minimal schema for rollback)
    op.create_table(
        "governance_proposals",
        sa.Column("id", sa.dialects.postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )

    # Restore vote columns
    op.add_column("votes", sa.Column("proposal_id", sa.dialects.postgresql.UUID(as_uuid=True), nullable=True))
    op.create_foreign_key("votes_proposal_id_fkey", "votes", "governance_proposals", ["proposal_id"], ["id"])
    op.add_column("votes", sa.Column("min_tier_required", sa.String(50), nullable=True))
    op.add_column("votes", sa.Column("vote_type", sa.String(20), nullable=True))

    # Best-effort reverse migration
    op.execute("""UPDATE votes SET vote_type = 'flavor' WHERE target_tiers = '["VIP", "High Roller", "Whale"]'::jsonb""")
    op.execute("""UPDATE votes SET vote_type = 'product' WHERE target_tiers = '["High Roller", "Whale"]'::jsonb""")
    op.execute("""UPDATE votes SET vote_type = 'corporate' WHERE target_tiers = '["Whale"]'::jsonb""")
    op.execute("""UPDATE votes SET vote_type = 'flavor' WHERE vote_type IS NULL""")
    op.execute("""UPDATE votes SET min_tier_required = 'VIP' WHERE min_tier_required IS NULL""")

    op.alter_column("votes", "vote_type", nullable=False)
    op.alter_column("votes", "min_tier_required", nullable=False)

    op.drop_column("votes", "target_tiers")

    # Remove room_type and re-seed channels is impractical; just drop the column
    op.drop_column("channels", "room_type")
