"""Treasury Celery tasks."""

import asyncio
import logging
from decimal import Decimal

from app.celery_app import celery_app

logger = logging.getLogger(__name__)


@celery_app.task(name="app.tasks.treasury.take_treasury_snapshot", bind=True)
def take_treasury_snapshot(self) -> dict:
    """Capture on-chain and bank balances for all 3 treasury pools.

    Runs hourly. Reads Teller bank balances (if configured) and on-chain
    USDT balances from Polygon. Writes to treasury_snapshots table.
    """
    from app.db.session import AsyncSessionLocal
    from app.services.timescale_service import write_treasury_snapshot

    # Pool → settings attribute for on-chain address
    from app.core.config import settings
    pool_config = {
        "consumer": settings.BLOCKCHAIN_MEMBER_TREASURY_ADDRESS,
        "affiliate": settings.BLOCKCHAIN_AFFILIATE_TREASURY_ADDRESS,
        "wholesale": settings.BLOCKCHAIN_WHOLESALE_TREASURY_ADDRESS,
    }

    async def _run():
        results = {}
        async with AsyncSessionLocal() as db:
            for pool_type, address in pool_config.items():
                onchain = Decimal("0")
                if address:
                    try:
                        from app.services.blockchain import get_usdt_balance
                        onchain = get_usdt_balance(address)
                    except Exception as exc:
                        logger.warning("Could not fetch on-chain balance for %s: %s", pool_type, exc)

                snapshot = await write_treasury_snapshot(
                    db, pool_type=pool_type, onchain_balance=onchain
                )
                results[pool_type] = str(onchain)
                logger.info("Snapshot written: pool=%s onchain=%s", pool_type, onchain)
        return results

    # Dwolla platform balance (non-blocking)
    dwolla_balance = Decimal("0")
    try:
        from app.services.dwolla_service import get_platform_balance
        dwolla_balance = get_platform_balance()
    except Exception as exc:
        logger.warning("Could not fetch Dwolla platform balance: %s", exc)

    try:
        results = asyncio.get_event_loop().run_until_complete(_run())
        results["dwolla_platform"] = str(dwolla_balance)
        return {"status": "ok", "snapshots": results}
    except Exception as exc:
        logger.error("[treasury] take_treasury_snapshot failed: %s", exc)
        return {"status": "error", "error": str(exc)}


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
