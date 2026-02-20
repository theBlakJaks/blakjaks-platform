"""Insights API — public transparency endpoints, no authentication required.

All endpoints delegate directly to insights_service aggregator functions and
return the raw dict. No Pydantic response model is used so the schema can
evolve freely as new data sources are added.
"""

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.services.insights_service import (
    get_activity_feed,
    get_comp_stats,
    get_overview,
    get_partner_stats,
    get_systems_health,
    get_treasury_insights,
)

router = APIRouter(prefix="/insights", tags=["insights"])


@router.get("/overview")
async def insights_overview(db: AsyncSession = Depends(get_db)) -> dict:
    """Public overview: scan count, active members, 24h payouts, velocity, recent activity."""
    return await get_overview(db)


@router.get("/treasury")
async def insights_treasury(db: AsyncSession = Depends(get_db)) -> dict:
    """Public treasury: pool balances, bank balances, 90-day sparklines, blockchain health."""
    return await get_treasury_insights(db)


@router.get("/systems")
async def insights_systems(db: AsyncSession = Depends(get_db)) -> dict:
    """Public systems health: scan velocity, node health, Teller sync, tier distribution."""
    return await get_systems_health(db)


@router.get("/comps")
async def insights_comps(db: AsyncSession = Depends(get_db)) -> dict:
    """Public comp stats: prize tier counts, total comps paid, active members comped."""
    return await get_comp_stats(db)


@router.get("/partners")
async def insights_partners(db: AsyncSession = Depends(get_db)) -> dict:
    """Public partner stats: affiliate count, wholesale account count."""
    return await get_partner_stats(db)


@router.get("/dwolla-balance")
async def insights_dwolla_balance() -> dict:
    """Dwolla platform ACH reserve balance (admin-facing)."""
    from app.services.dwolla_service import get_platform_balance
    balance = get_platform_balance()
    return {"balance_usd": float(balance)}


@router.get("/feed")
async def insights_feed(
    hours: int = Query(default=24, ge=1, le=720, description="Hours of history to include"),
    page: int = Query(default=1, ge=1, description="Page number (1-based)"),
    per_page: int = Query(default=20, ge=1, le=100, description="Items per page"),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Public activity feed: comp payouts, tier upgrades, new members — paginated."""
    return await get_activity_feed(db, hours=hours, page=page, per_page=per_page)
