"""Affiliate endpoints — dashboard, referrals, chips, payouts, sunset."""

import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.api.schemas.affiliate import (
    AffiliateOut,
    ChipSummary,
    DownlineList,
    PayoutList,
    PayoutOut,
    ReferralCodeUpdate,
    SunsetProgress,
    VaultRequest,
)
from app.models.user import User
from app.services.affiliate_service import (
    get_affiliate_chips,
    get_downline,
    get_or_create_affiliate,
    get_payout_history,
    get_sunset_progress,
    set_custom_referral_code,
    unvault_chips,
    vault_chips,
)

router = APIRouter(prefix="/affiliate", tags=["affiliate"])


@router.get("/me", response_model=AffiliateOut)
async def affiliate_dashboard(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        affiliate = await get_or_create_affiliate(db, user.id)
    except ValueError as e:
        raise HTTPException(status.HTTP_403_FORBIDDEN, str(e))

    chips = await get_affiliate_chips(db, affiliate.id)

    return AffiliateOut(
        id=affiliate.id,
        user_id=affiliate.user_id,
        referral_code=affiliate.referral_code,
        referral_link=f"https://blakjaks.com/r/{affiliate.referral_code}",
        total_earnings=affiliate.lifetime_earnings,
        pending_earnings=0,
        downline_count=affiliate.referred_count,
        total_chips=chips["active_chips"] + chips["vaulted_chips"],
        vaulted_chips=chips["vaulted_chips"],
        permanent_tier=affiliate.tier_status,
        created_at=affiliate.created_at,
    )


@router.put("/me/referral-code", response_model=AffiliateOut)
async def update_referral_code(
    body: ReferralCodeUpdate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        affiliate = await set_custom_referral_code(db, user.id, body.code)
    except ValueError as e:
        raise HTTPException(status.HTTP_409_CONFLICT, str(e))

    chips = await get_affiliate_chips(db, affiliate.id)
    return AffiliateOut(
        id=affiliate.id,
        user_id=affiliate.user_id,
        referral_code=affiliate.referral_code,
        referral_link=f"https://blakjaks.com/r/{affiliate.referral_code}",
        total_earnings=affiliate.lifetime_earnings,
        pending_earnings=0,
        downline_count=affiliate.referred_count,
        total_chips=chips["active_chips"] + chips["vaulted_chips"],
        vaulted_chips=chips["vaulted_chips"],
        permanent_tier=affiliate.tier_status,
        created_at=affiliate.created_at,
    )


@router.get("/me/downline", response_model=DownlineList)
async def downline_list(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    affiliate = await get_or_create_affiliate(db, user.id)
    return await get_downline(db, affiliate.id, page, per_page)


@router.get("/me/chips", response_model=ChipSummary)
async def chip_summary(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    affiliate = await get_or_create_affiliate(db, user.id)
    return await get_affiliate_chips(db, affiliate.id)


@router.post("/me/chips/vault")
async def vault_user_chips(
    body: VaultRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    affiliate = await get_or_create_affiliate(db, user.id)
    count = await vault_chips(db, affiliate.id, body.chip_ids)
    return {"message": f"{count} chips vaulted"}


@router.post("/me/chips/unvault")
async def unvault_user_chips(
    body: VaultRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    affiliate = await get_or_create_affiliate(db, user.id)
    count = await unvault_chips(db, affiliate.id, body.chip_ids)
    return {"message": f"{count} chips unvaulted"}


@router.get("/me/payouts", response_model=PayoutList)
async def payout_history(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    affiliate = await get_or_create_affiliate(db, user.id)
    return await get_payout_history(db, affiliate.id, page, per_page)


@router.get("/sunset", response_model=SunsetProgress)
async def sunset_status(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await get_sunset_progress(db)
