"""Guaranteed comps Celery task.

run_monthly_guaranteed_comps: processes the $50 monthly guaranteed comp
for all qualifying members who haven't yet hit a milestone this month.

Real logic wired in Phase D (comp engine).
"""

import logging
from datetime import datetime, timezone

from app.celery_app import celery_app

logger = logging.getLogger(__name__)


@celery_app.task(name="app.tasks.comps.run_monthly_guaranteed_comps", bind=True)
def run_monthly_guaranteed_comps(self) -> dict:
    """Run monthly guaranteed comp batch for all qualifying members.

    Runs on the 1st of each month at 2:00 AM UTC. Awards $50 guaranteed
    comp to all active members who have not hit a milestone comp this month.
    Real implementation wired in Phase D comp engine.
    """
    now = datetime.now(timezone.utc)
    month_key = now.strftime("%Y-%m")

    # Idempotency check: bail out if this month's run has already been recorded.
    # The task stores a sentinel key in the Celery/Redis backend so a second
    # invocation in the same calendar month is a no-op.
    idempotency_key = f"comps:monthly_guaranteed:{month_key}"
    backend = self.backend
    if backend is not None:
        try:
            already_ran = backend.client.get(idempotency_key)
            if already_ran:
                logger.info(
                    "[comps] run_monthly_guaranteed_comps already ran for %s — skipping.",
                    month_key,
                )
                return {
                    "status": "skipped",
                    "task": "run_monthly_guaranteed_comps",
                    "month": month_key,
                    "message": "Already executed for this month.",
                }
            # Mark as ran; expire after 35 days so old keys are cleaned up automatically.
            backend.client.setex(idempotency_key, 60 * 60 * 24 * 35, "1")
        except Exception as exc:
            # If Redis is unavailable, log and proceed rather than blocking the task.
            logger.warning(
                "[comps] Could not check/set idempotency key %s: %s — proceeding anyway.",
                idempotency_key,
                exc,
            )

    logger.info("[comps] run_monthly_guaranteed_comps — task stub executed.")
    return {
        "status": "stub",
        "task": "run_monthly_guaranteed_comps",
        "message": "Real implementation wired in Phase D comp engine.",
    }
