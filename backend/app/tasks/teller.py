"""Teller.io bank sync Celery task.

sync_teller_balances: fetches current balances for all 3 bank accounts
(Operating, Reserve, Comp Pool) via mTLS Teller API.

Real logic wired in Task D2.
"""

import logging

from app.celery_app import celery_app

logger = logging.getLogger(__name__)


@celery_app.task(name="app.tasks.teller.sync_teller_balances", bind=True)
def sync_teller_balances(self) -> dict:
    """Sync bank balances for Operating, Reserve, and Comp Pool accounts via Teller.io.

    Runs every 6 hours. Writes results to teller_accounts and treasury_snapshots.
    Real implementation wired in Task D2.
    """
    logger.info("[teller] sync_teller_balances — task stub executed.")
    return {
        "status": "stub",
        "task": "sync_teller_balances",
        "message": "Real implementation wired in Task D2.",
    }
