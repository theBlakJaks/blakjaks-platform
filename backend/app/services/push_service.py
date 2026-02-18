"""Push notification service for iOS (APNs) and Android (FCM).

PLACEHOLDER: Logs push notifications instead of making real API calls.
TODO: Replace with real APNs/FCM calls when Apple Developer Account and
Firebase are configured.
"""

import logging
import uuid

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.device_token import DeviceToken

logger = logging.getLogger(__name__)


async def register_device_token(
    db: AsyncSession, user_id: uuid.UUID, token: str, platform: str
) -> DeviceToken:
    """Store a device token for push notifications.

    If the token already exists for this user, return the existing record.
    """
    result = await db.execute(
        select(DeviceToken).where(
            DeviceToken.user_id == user_id,
            DeviceToken.token == token,
        )
    )
    existing = result.scalar_one_or_none()
    if existing:
        return existing

    device_token = DeviceToken(
        user_id=user_id,
        token=token,
        platform=platform,
    )
    db.add(device_token)
    await db.commit()
    await db.refresh(device_token)
    return device_token


async def unregister_device_token(
    db: AsyncSession, user_id: uuid.UUID, token: str
) -> bool:
    """Remove a device token on logout. Returns True if a token was removed."""
    result = await db.execute(
        select(DeviceToken).where(
            DeviceToken.user_id == user_id,
            DeviceToken.token == token,
        )
    )
    device_token = result.scalar_one_or_none()
    if device_token is None:
        return False

    await db.delete(device_token)
    await db.commit()
    return True


async def send_push_notification(
    db: AsyncSession, user_id: uuid.UUID, title: str, body: str, data: dict | None = None
) -> int:
    """Send push notification to a specific user's devices.

    PLACEHOLDER: Logs instead of calling APNs/FCM.
    Returns the number of devices notified.
    """
    result = await db.execute(
        select(DeviceToken).where(DeviceToken.user_id == user_id)
    )
    tokens = list(result.scalars().all())

    for dt in tokens:
        if dt.platform == "ios":
            # TODO: Send via APNs using Apple Developer credentials
            logger.info(
                "PUSH [APNs] user=%s token=%s title=%s body=%s data=%s",
                user_id, dt.token, title, body, data,
            )
        elif dt.platform == "android":
            # TODO: Send via FCM using Firebase credentials
            logger.info(
                "PUSH [FCM] user=%s token=%s title=%s body=%s data=%s",
                user_id, dt.token, title, body, data,
            )

    return len(tokens)


async def send_push_to_segment(
    db: AsyncSession, tier_name: str, title: str, body: str, data: dict | None = None
) -> int:
    """Send push to all users of a specific tier.

    PLACEHOLDER: Logs instead of calling APNs/FCM.
    """
    from app.models.user import User
    from app.models.tier import Tier

    result = await db.execute(
        select(DeviceToken)
        .join(User, DeviceToken.user_id == User.id)
        .join(Tier, User.tier_id == Tier.id)
        .where(Tier.name == tier_name)
    )
    tokens = list(result.scalars().all())

    for dt in tokens:
        logger.info(
            "PUSH [segment=%s] user=%s token=%s title=%s",
            tier_name, dt.user_id, dt.token, title,
        )

    return len(tokens)


async def send_push_to_all(
    db: AsyncSession, title: str, body: str, data: dict | None = None
) -> int:
    """Broadcast push to all users with registered devices.

    PLACEHOLDER: Logs instead of calling APNs/FCM.
    """
    result = await db.execute(select(DeviceToken))
    tokens = list(result.scalars().all())

    for dt in tokens:
        logger.info(
            "PUSH [broadcast] user=%s token=%s title=%s",
            dt.user_id, dt.token, title,
        )

    return len(tokens)
