"""Rename usdt_earned to usdc_earned in scans table

Revision ID: 024
Revises: 023
Create Date: 2026-02-20
"""

from alembic import op

revision = "024"
down_revision = "023"
branch_labels = None
depends_on = None


def upgrade():
    # Column was already named usdc_earned in the initial schema (001);
    # this migration is a no-op on fresh databases.
    conn = op.get_bind()
    result = conn.execute(
        "SELECT column_name FROM information_schema.columns "
        "WHERE table_name='scans' AND column_name='usdt_earned'"
    )
    if result.fetchone():
        op.alter_column('scans', 'usdt_earned', new_column_name='usdc_earned')


def downgrade():
    conn = op.get_bind()
    result = conn.execute(
        "SELECT column_name FROM information_schema.columns "
        "WHERE table_name='scans' AND column_name='usdc_earned'"
    )
    if result.fetchone():
        op.alter_column('scans', 'usdc_earned', new_column_name='usdt_earned')
