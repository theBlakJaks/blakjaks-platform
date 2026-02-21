"""Treasury Celery tasks."""

import logging

from app.celery_app import celery_app

logger = logging.getLogger(__name__)


@celery_app.task(name="app.tasks.treasury.take_treasury_snapshot", bind=True)
def take_treasury_snapshot(self) -> dict:
    """Capture on-chain and bank balances for all 3 treasury pools.

    Runs hourly. Reads Teller bank balances (if configured) and on-chain
    USDC balances from Polygon. Writes to treasury_snapshots table.
    Real implementation wired in Task E3.
    """
    logger.info("[treasury] take_treasury_snapshot — task stub executed.")
    return {
        "status": "stub",
        "task": "take_treasury_snapshot",
        "message": "Real implementation wired in Task E3.",
    }


@celery_app.task(name="app.tasks.treasury.reconcile_leaderboard", bind=True)
def reconcile_leaderboard(self) -> dict:
    """Reconcile Redis leaderboard scores against PostgreSQL scan counts.

    Runs daily at midnight UTC. Corrects drift between Redis and DB.
    Real implementation wired in Task E3.
    """
    logger.info("[treasury] reconcile_leaderboard — task stub executed.")
    return {
        "status": "stub",
        "task": "reconcile_leaderboard",
        "message": "Real implementation wired in Task E3.",
    }
