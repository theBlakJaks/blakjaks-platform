"""Affiliate payout Celery task.

run_weekly_affiliate_payout: distributes the weekly affiliate pool to qualified affiliates.

Real logic wired in Phase D (affiliate service).
"""

import logging

from app.celery_app import celery_app

logger = logging.getLogger(__name__)


@celery_app.task(name="app.tasks.affiliate.run_weekly_affiliate_payout", bind=True)
def run_weekly_affiliate_payout(self) -> dict:
    """Run the weekly affiliate pool payout.

    Runs every Sunday at 3:00 AM UTC. Distributes 21% match rewards
    to qualifying affiliates using the affiliate pool wallet.
    Real implementation wired in Phase D.
    """
    logger.info("[affiliate] run_weekly_affiliate_payout — task stub executed.")
    return {
        "status": "stub",
        "task": "run_weekly_affiliate_payout",
        "message": "Real implementation wired in Phase D affiliate service.",
    }
