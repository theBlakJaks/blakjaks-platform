"""Notification service — writes to DB and triggers push notifications."""

import uuid

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.notification import Notification
from app.services.push_service import send_push_notification


# Valid notification types
NOTIFICATION_TYPES = {
    "comp_award",
    "tier_change",
    "order_update",
    "scan_milestone",
    "system",
    "weekly_summary",
}


async def create_notification(
    db: AsyncSession,
    user_id: uuid.UUID,
    type: str,
    title: str,
    body: str | None = None,
) -> Notification:
    """Write notification to DB and trigger push notification."""
    notification = Notification(
        user_id=user_id,
        type=type,
        title=title,
        body=body,
    )
    db.add(notification)
    await db.commit()
    await db.refresh(notification)

    # Trigger push notification (fire-and-forget, don't block on failure)
    try:
        await send_push_notification(db, user_id, title, body or "")
    except Exception:
        pass  # Push failures should not break notification creation

    return notification


async def mark_as_read(db: AsyncSession, notification_id: uuid.UUID, user_id: uuid.UUID) -> bool:
    """Mark a notification as read. Returns True if found and updated."""
    result = await db.execute(
        select(Notification).where(
            Notification.id == notification_id,
            Notification.user_id == user_id,
        )
    )
    notification = result.scalar_one_or_none()
    if notification is None:
        return False

    notification.is_read = True
    await db.commit()
    return True


async def get_unread_count(db: AsyncSession, user_id: uuid.UUID) -> int:
    """Return count of unread notifications for a user."""
    result = await db.execute(
        select(func.count())
        .select_from(Notification)
        .where(
            Notification.user_id == user_id,
            Notification.is_read == False,  # noqa: E712
        )
    )
    return result.scalar_one()


async def batch_create_notifications(
    db: AsyncSession,
    user_ids: list[uuid.UUID],
    type: str,
    title: str,
    body: str | None = None,
) -> list[Notification]:
    """Create notifications for multiple users at once (for broadcasts)."""
    notifications = []
    for uid in user_ids:
        n = Notification(user_id=uid, type=type, title=title, body=body)
        db.add(n)
        notifications.append(n)

    await db.commit()
    for n in notifications:
        await db.refresh(n)

    # Trigger push notifications for each user
    for uid in user_ids:
        try:
            await send_push_notification(db, uid, title, body or "")
        except Exception:
            pass

    return notifications
