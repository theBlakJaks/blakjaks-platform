"""Treasury transparency endpoints — all public, no auth required."""

from datetime import datetime, timezone

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.api.schemas.treasury import (
    CompRecipient,
    CompRecipientList,
    PoolBalance,
    TreasuryPools,
    TreasuryStats,
)
from app.services.blockchain import AFFILIATE_POOL, CONSUMER_POOL, WHOLESALE_POOL
from app.services.comp_engine import (
    get_pool_balances,
    get_recent_comp_recipients,
    get_treasury_stats,
)

router = APIRouter(prefix="/treasury", tags=["treasury"])


@router.get("/pools", response_model=TreasuryPools)
async def treasury_pools():
    """Return current pool balances and wallet addresses (public)."""
    pools = await get_pool_balances()
    return TreasuryPools(
        consumer=PoolBalance(
            name="consumer",
            address=pools["consumer"]["address"],
            balance=pools["consumer"]["balance"],
            allocation_pct=CONSUMER_POOL,
        ),
        affiliate=PoolBalance(
            name="affiliate",
            address=pools["affiliate"]["address"],
            balance=pools["affiliate"]["balance"],
            allocation_pct=AFFILIATE_POOL,
        ),
        wholesale=PoolBalance(
            name="wholesale",
            address=pools["wholesale"]["address"],
            balance=pools["wholesale"]["balance"],
            allocation_pct=WHOLESALE_POOL,
        ),
        last_updated=datetime.now(timezone.utc),
    )


@router.get("/recipients", response_model=CompRecipientList)
async def treasury_recipients(
    limit: int = 20,
    db: AsyncSession = Depends(get_db),
):
    """Return recent comp recipients with masked usernames (public)."""
    recipients = await get_recent_comp_recipients(db, limit=limit)
    return CompRecipientList(
        recipients=[CompRecipient(**r) for r in recipients],
        count=len(recipients),
    )


@router.get("/stats", response_model=TreasuryStats)
async def treasury_stats(db: AsyncSession = Depends(get_db)):
    """Return aggregate treasury statistics (public)."""
    stats = await get_treasury_stats(db)
    return TreasuryStats(**stats)
