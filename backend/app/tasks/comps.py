"""Guaranteed comps Celery task.

run_monthly_guaranteed_comps: processes the $50 monthly guaranteed comp
for all qualifying members who haven't yet hit a milestone this month.

Real logic wired in Phase D (comp engine).
"""

import logging

from app.celery_app import celery_app

logger = logging.getLogger(__name__)


@celery_app.task(name="app.tasks.comps.run_monthly_guaranteed_comps", bind=True)
def run_monthly_guaranteed_comps(self) -> dict:
    """Run monthly guaranteed comp batch for all qualifying members.

    Runs on the 1st of each month at 2:00 AM UTC. Awards $50 guaranteed
    comp to all active members who have not hit a milestone comp this month.
    Real implementation wired in Phase D comp engine.
    """
    logger.info("[comps] run_monthly_guaranteed_comps — task stub executed.")
    return {
        "status": "stub",
        "task": "run_monthly_guaranteed_comps",
        "message": "Real implementation wired in Phase D comp engine.",
    }
