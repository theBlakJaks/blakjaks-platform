"""Teller.io bank sync Celery task."""

import asyncio
import logging

from app.celery_app import celery_app

logger = logging.getLogger(__name__)


@celery_app.task(name="app.tasks.teller.sync_teller_balances", bind=True)
def sync_teller_balances(self) -> dict:
    """Sync bank balances for Operating, Reserve, and Comp Pool accounts via Teller.io.

    Runs every 6 hours. Writes results to teller_accounts and treasury_snapshots.
    """
    from app.db.session import AsyncSessionLocal
    from app.services.teller_service import sync_all_balances

    async def _run():
        async with AsyncSessionLocal() as db:
            return await sync_all_balances(db)

    try:
        results = asyncio.get_event_loop().run_until_complete(_run())
        return {"status": "ok", "results": {k: str(v) for k, v in results.items()}}
    except Exception as exc:
        logger.error("[teller] sync_teller_balances failed: %s", exc)
        return {"status": "error", "error": str(exc)}
