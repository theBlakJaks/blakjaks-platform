import logging
import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from jose import JWTError
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.api.schemas.auth import (
    AccessTokenResponse,
    AuthResponse,
    LoginRequest,
    MessageResponse,
    RefreshRequest,
    ResetPasswordConfirm,
    ResetPasswordRequest,
    SignupRequest,
    TokenResponse,
    UserResponse,
)
from app.core.security import (
    create_access_token,
    create_refresh_token,
    create_reset_token,
    decode_token,
    hash_password,
    verify_password,
)
from app.models.user import User
from app.services.wallet_service import create_user_wallet
from app.services.email_service import send_password_reset, send_welcome_email
from app.services.intercom_service import create_or_update_contact

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/signup", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
async def signup(body: SignupRequest, db: AsyncSession = Depends(get_db)):
    user = User(
        email=body.email,
        password_hash=hash_password(body.password),
        first_name=body.first_name,
        last_name=body.last_name,
        birthdate=body.birthdate,
    )
    db.add(user)
    try:
        await db.commit()
        await db.refresh(user)
    except IntegrityError:
        await db.rollback()
        raise HTTPException(status.HTTP_409_CONFLICT, "Email already registered")

    # Auto-create wallet for the new user
    await create_user_wallet(db, user.id, email=body.email)

    # Send welcome email and sync to Intercom (fire-and-forget)
    try:
        await send_welcome_email(body.email, body.first_name)
    except Exception:
        logger.exception("Failed to send welcome email to %s", body.email)
    try:
        await create_or_update_contact(user.id, body.email, f"{body.first_name} {body.last_name}")
    except Exception:
        logger.exception("Failed to sync user to Intercom: %s", body.email)

    return AuthResponse(
        user=UserResponse.model_validate(user),
        tokens=TokenResponse(
            access_token=create_access_token(user.id),
            refresh_token=create_refresh_token(user.id),
        ),
    )


@router.post("/login", response_model=AuthResponse)
async def login(body: LoginRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == body.email))
    user = result.scalar_one_or_none()

    if user is None or not verify_password(body.password, user.password_hash):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid email or password")
    if not user.is_active:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Account is deactivated")

    return AuthResponse(
        user=UserResponse.model_validate(user),
        tokens=TokenResponse(
            access_token=create_access_token(user.id),
            refresh_token=create_refresh_token(user.id),
        ),
    )


@router.post("/refresh", response_model=AccessTokenResponse)
async def refresh(body: RefreshRequest, db: AsyncSession = Depends(get_db)):
    try:
        payload = decode_token(body.refresh_token)
        if payload.get("type") != "refresh":
            raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid token type")
        user_id = uuid.UUID(payload["sub"])
    except (JWTError, KeyError, ValueError):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid or expired refresh token")

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if user is None or not user.is_active:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "User not found or deactivated")

    return AccessTokenResponse(access_token=create_access_token(user.id))


@router.post("/reset-password", response_model=MessageResponse)
async def reset_password(body: ResetPasswordRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == body.email))
    user = result.scalar_one_or_none()

    # Always return success to prevent email enumeration
    if user is not None:
        token = create_reset_token(user.id)
        reset_url = f"https://blakjaks.com/reset-password?token={token}"
        try:
            await send_password_reset(user.email, token, reset_url)
        except Exception:
            logger.exception("Failed to send password reset email to %s", user.email)

    return MessageResponse(message="If that email exists, a reset link has been sent")


@router.post("/reset-password/confirm", response_model=MessageResponse)
async def reset_password_confirm(body: ResetPasswordConfirm, db: AsyncSession = Depends(get_db)):
    try:
        payload = decode_token(body.token)
        if payload.get("type") != "reset":
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "Invalid token type")
        user_id = uuid.UUID(payload["sub"])
    except (JWTError, KeyError, ValueError):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Invalid or expired reset token")

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Invalid or expired reset token")

    user.password_hash = hash_password(body.new_password)
    await db.commit()

    return MessageResponse(message="Password has been reset successfully")
