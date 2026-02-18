import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import get_current_user, get_db
from app.api.schemas.user import (
    NotificationResponse,
    PaginatedNotifications,
    TierResponse,
    UserProfileResponse,
    UserStatsResponse,
    UserUpdateRequest,
)
from app.models.notification import Notification
from app.models.scan import Scan
from app.models.user import User
from app.services.tier import get_current_quarter_range, get_user_tier_info

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=UserProfileResponse)
async def get_me(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Eagerly load tier relationship
    result = await db.execute(
        select(User).options(selectinload(User.tier)).where(User.id == current_user.id)
    )
    user = result.scalar_one()

    response = UserProfileResponse.model_validate(user)
    if user.tier is not None:
        response.tier = TierResponse(
            name=user.tier.name,
            discount_pct=user.tier.discount_pct,
            color=user.tier.color,
            benefits=user.tier.benefits_json,
        )
    return response


@router.put("/me", response_model=UserProfileResponse)
async def update_me(
    body: UserUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    update_data = body.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(current_user, field, value)
    await db.commit()
    await db.refresh(current_user)

    # Reload with tier
    result = await db.execute(
        select(User).options(selectinload(User.tier)).where(User.id == current_user.id)
    )
    user = result.scalar_one()

    response = UserProfileResponse.model_validate(user)
    if user.tier is not None:
        response.tier = TierResponse(
            name=user.tier.name,
            discount_pct=user.tier.discount_pct,
            color=user.tier.color,
            benefits=user.tier.benefits_json,
        )
    return response


@router.get("/me/stats", response_model=UserStatsResponse)
async def get_my_stats(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    tier_info = await get_user_tier_info(db, current_user.id)

    # Calculate current streak: consecutive days with scans ending today/yesterday
    q_start, q_end = get_current_quarter_range()
    result = await db.execute(
        select(Scan.streak_day)
        .where(
            Scan.user_id == current_user.id,
            Scan.created_at >= q_start,
            Scan.created_at < q_end,
        )
        .order_by(Scan.created_at.desc())
        .limit(1)
    )
    latest_streak = result.scalar_one_or_none() or 0

    return UserStatsResponse(
        tier_name=tier_info.get("tier_name"),
        tier_color=tier_info.get("tier_color"),
        discount_pct=tier_info.get("discount_pct"),
        benefits=tier_info.get("benefits"),
        quarterly_scans=tier_info["quarterly_scans"],
        scans_to_next_tier=tier_info.get("scans_to_next_tier"),
        current_streak=latest_streak,
    )


@router.get("/me/notifications", response_model=PaginatedNotifications)
async def get_my_notifications(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    base_query = select(Notification).where(Notification.user_id == current_user.id)

    # Total count
    count_result = await db.execute(
        select(func.count()).select_from(base_query.subquery())
    )
    total = count_result.scalar_one()

    # Paginated results
    result = await db.execute(
        base_query
        .order_by(Notification.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    items = list(result.scalars().all())

    return PaginatedNotifications(
        items=[NotificationResponse.model_validate(n) for n in items],
        total=total,
        page=page,
        page_size=page_size,
    )


@router.put("/me/notifications/{notification_id}/read")
async def mark_notification_read(
    notification_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Notification).where(
            Notification.id == notification_id,
            Notification.user_id == current_user.id,
        )
    )
    notification = result.scalar_one_or_none()
    if notification is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Notification not found")

    notification.is_read = True
    await db.commit()
    return {"message": "Notification marked as read"}
