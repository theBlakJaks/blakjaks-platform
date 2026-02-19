import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import get_current_user, get_db
from app.api.schemas.user import (
    AvatarUploadResponse,
    NotificationResponse,
    PaginatedNotifications,
    TierResponse,
    UsernameChangeRequest,
    UsernameCheckResponse,
    UserProfileResponse,
    UserStatsResponse,
    UserUpdateRequest,
)
from app.services.username_service import validate_username_format, is_profane, is_reserved, generate_suggestions
from app.models.notification import Notification
from app.models.scan import Scan
from app.models.user import User
from app.services.tier import get_current_quarter_range, get_user_tier_info

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/check-username", response_model=UsernameCheckResponse)
async def check_username(
    username: str = Query(..., min_length=4, max_length=25),
    db: AsyncSession = Depends(get_db),
):
    """Check if a username is available."""
    # Format validation
    fmt = validate_username_format(username)
    if not fmt["valid"]:
        return UsernameCheckResponse(available=False, message=fmt["error"])

    # Profanity check
    if is_profane(username):
        return UsernameCheckResponse(available=False, message="This username is not allowed")

    # Reserved check
    if is_reserved(username):
        return UsernameCheckResponse(available=False, message="This username is not allowed")

    # DB uniqueness
    result = await db.execute(
        select(User).where(User.username_lower == username.lower())
    )
    if result.scalar_one_or_none():
        suggestions = await generate_suggestions(username, db)
        return UsernameCheckResponse(
            available=False,
            message="Username already taken",
            suggestions=suggestions,
        )

    return UsernameCheckResponse(available=True, message="Username available")


@router.put("/me/username")
async def change_username(
    body: UsernameChangeRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Change current user's username. Limited to once every 60 days."""
    from datetime import timedelta

    # Check 60-day cooldown
    if current_user.username_changed_at:
        cooldown_end = current_user.username_changed_at + timedelta(days=60)
        now = datetime.now(timezone.utc)
        if now < cooldown_end:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                f"Username can be changed again after {cooldown_end.strftime('%B %d, %Y')}",
            )

    # Validate
    fmt = validate_username_format(body.username)
    if not fmt["valid"]:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, fmt["error"])
    if is_profane(body.username):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "This username is not allowed")
    if is_reserved(body.username):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "This username is not allowed")

    # Check uniqueness (excluding current user)
    result = await db.execute(
        select(User).where(
            User.username_lower == body.username.lower(),
            User.id != current_user.id,
        )
    )
    if result.scalar_one_or_none():
        raise HTTPException(status.HTTP_409_CONFLICT, "Username already taken")

    current_user.username = body.username
    current_user.username_lower = body.username.lower()
    current_user.username_changed_at = datetime.now(timezone.utc)
    await db.commit()

    return {"message": "Username updated", "username": body.username}


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


@router.post("/me/avatar", response_model=AvatarUploadResponse)
async def upload_avatar(
    avatar: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Upload a new profile picture with content moderation."""
    from app.services.image_moderation import (
        ModerationResult,
        check_rate_limit,
        record_rejection,
        record_upload,
        scan_image_for_explicit_content,
    )
    from app.services.image_processing import (
        process_avatar,
        validate_image_dimensions,
        validate_image_file,
    )
    from app.services.avatar_storage import (
        get_avatar_urls,
        upload_avatar_to_gcs,
    )

    # Step 1: Read file
    image_bytes = await avatar.read()

    # Step 2: Validate basics
    error = validate_image_file(avatar.filename, avatar.content_type, len(image_bytes))
    if error:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, detail=error)

    dim_error = validate_image_dimensions(image_bytes)
    if dim_error:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, detail=dim_error)

    # Step 3: Rate limit check
    rate_error = check_rate_limit(current_user.id)
    if rate_error:
        raise HTTPException(status.HTTP_429_TOO_MANY_REQUESTS, detail=rate_error)

    record_upload(current_user.id)

    # Step 4: Scan for explicit content
    moderation = scan_image_for_explicit_content(image_bytes)

    if moderation["result"] == ModerationResult.SCAN_FAILED:
        raise HTTPException(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=moderation["message"],
        )

    if moderation["result"] != ModerationResult.APPROVED:
        record_rejection(current_user.id)
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            detail={"error": "image_rejected", "message": moderation["message"]},
        )

    # Step 5: Process image
    processed = process_avatar(image_bytes)

    # Step 6: Upload to GCS
    avatar_path = upload_avatar_to_gcs(current_user.id, processed)

    # Step 7: Update database
    now = datetime.now(timezone.utc)
    current_user.avatar_url = avatar_path
    current_user.avatar_updated_at = now
    await db.commit()

    # Step 8: Return URLs
    return AvatarUploadResponse(
        avatar_url=avatar_path,
        sizes=get_avatar_urls(current_user.id),
    )


@router.delete("/me/avatar")
async def delete_avatar(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Remove profile picture and revert to default."""
    from app.services.avatar_storage import delete_avatar_from_gcs

    if current_user.avatar_url:
        delete_avatar_from_gcs(current_user.id)

    current_user.avatar_url = None
    current_user.avatar_updated_at = datetime.now(timezone.utc)
    await db.commit()

    return {"message": "Avatar removed"}
