"""Affiliate payout Celery task.

run_weekly_affiliate_payout: distributes the weekly affiliate pool to qualified affiliates.

Real logic wired in Phase D (affiliate service).
"""

import logging
from datetime import datetime, timezone

from app.celery_app import celery_app

logger = logging.getLogger(__name__)


@celery_app.task(name="app.tasks.affiliate.run_weekly_affiliate_payout", bind=True)
def run_weekly_affiliate_payout(self) -> dict:
    """Run the weekly affiliate pool payout.

    Runs every Sunday at 3:00 AM UTC. Distributes 21% match rewards
    to qualifying affiliates using the affiliate pool wallet.
    Real implementation wired in Phase D.
    """
    now = datetime.now(timezone.utc)
    # ISO week key, e.g. "2026-W08" — unique per calendar week
    iso_year, iso_week, _ = now.isocalendar()
    week_key = f"{iso_year}-W{iso_week:02d}"

    # Idempotency check: bail out if this ISO week's payout has already been recorded.
    idempotency_key = f"affiliate:weekly_payout:{week_key}"
    backend = self.backend
    if backend is not None:
        try:
            already_ran = backend.client.get(idempotency_key)
            if already_ran:
                logger.info(
                    "[affiliate] run_weekly_affiliate_payout already ran for %s — skipping.",
                    week_key,
                )
                return {
                    "status": "skipped",
                    "task": "run_weekly_affiliate_payout",
                    "week": week_key,
                    "message": "Already executed for this ISO week.",
                }
            # Mark as ran; expire after 10 days so old keys are cleaned up automatically.
            backend.client.setex(idempotency_key, 60 * 60 * 24 * 10, "1")
        except Exception as exc:
            # If Redis is unavailable, log and proceed rather than blocking the task.
            logger.warning(
                "[affiliate] Could not check/set idempotency key %s: %s — proceeding anyway.",
                idempotency_key,
                exc,
            )

    logger.info("[affiliate] run_weekly_affiliate_payout — task stub executed.")
    return {
        "status": "stub",
        "task": "run_weekly_affiliate_payout",
        "message": "Real implementation wired in Phase D affiliate service.",
    }
