"""Admin affiliate endpoints — affiliate management, payouts, sunset."""

import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.api.schemas.affiliate import PayoutOut
from app.models.user import User
from app.services.affiliate_service import (
    approve_payout_batch,
    check_sunset_status,
    execute_payouts,
    get_affiliate,
    get_all_affiliates,
    get_pending_payouts,
)

router = APIRouter(prefix="/admin/affiliates", tags=["admin-affiliate"])


def require_admin(user: User = Depends(get_current_user)) -> User:
    if not user.is_admin:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Admin access required")
    return user


@router.get("")
async def list_affiliates(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    sort_by: str = Query("earnings", pattern="^(earnings|downline|recent)$"),
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await get_all_affiliates(db, page, per_page, sort_by)
    items = []
    for aff in result["items"]:
        items.append({
            "id": str(aff.id),
            "user_id": str(aff.user_id),
            "referral_code": aff.referral_code,
            "referred_count": aff.referred_count,
            "lifetime_earnings": str(aff.lifetime_earnings),
            "tier_status": aff.tier_status,
        })
    return {"items": items, "total": result["total"], "page": result["page"], "per_page": result["per_page"]}


@router.get("/{affiliate_user_id}")
async def get_affiliate_detail(
    affiliate_user_id: uuid.UUID,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    affiliate = await get_affiliate(db, affiliate_user_id)
    if not affiliate:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Affiliate not found")
    return {
        "id": str(affiliate.id),
        "user_id": str(affiliate.user_id),
        "referral_code": affiliate.referral_code,
        "referred_count": affiliate.referred_count,
        "lifetime_earnings": str(affiliate.lifetime_earnings),
        "tier_status": affiliate.tier_status,
        "reward_matching_pct": str(affiliate.reward_matching_pct),
    }


@router.post("/payouts/approve")
async def approve_payouts(
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    count = await approve_payout_batch(db)
    return {"message": f"{count} payouts approved"}


@router.post("/payouts/execute")
async def execute_payouts_endpoint(
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    count = await execute_payouts(db)
    return {"message": f"{count} payouts executed"}


@router.get("/payouts/pending", response_model=list[PayoutOut])
async def pending_payouts(
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    return await get_pending_payouts(db)


@router.post("/sunset/check")
async def check_sunset(
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    return await check_sunset_status(db)
