"""Social Hub REST endpoints — channels, messages, reactions, reports."""

import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.api.schemas.social import (
    ChannelOut,
    MessageCreate,
    MessageOut,
    ReactionCreate,
    ReportCreate,
    TranslateRequest,
    TranslateResponse,
)
from app.models.user import User
from app.services.chat_service import (
    delete_message,
    get_channel_messages,
    get_channels,
    get_pinned_messages,
    report_message,
    send_message,
)
from app.services.reaction_service import (
    add_reaction as svc_add_reaction,
    get_reactions as svc_get_reactions,
    remove_reaction as svc_remove_reaction,
)
from app.services.translation_service import detect_language, translate_message

router = APIRouter(prefix="/social", tags=["social"])


@router.get("/channels", response_model=list[ChannelOut])
async def list_channels(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    channels = await get_channels(db, user.id)
    return channels


@router.get("/channels/{channel_id}/messages", response_model=list[MessageOut])
async def list_messages(
    channel_id: uuid.UUID,
    before: uuid.UUID | None = Query(None),
    limit: int = Query(50, ge=1, le=100),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    messages = await get_channel_messages(db, channel_id, user.id, before_id=before, limit=limit)
    return messages


@router.get("/channels/{channel_id}/pinned", response_model=list[MessageOut])
async def list_pinned(
    channel_id: uuid.UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await get_pinned_messages(db, channel_id)


@router.post("/channels/{channel_id}/messages", response_model=MessageOut, status_code=status.HTTP_201_CREATED)
async def create_message(
    channel_id: uuid.UUID,
    body: MessageCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await send_message(db, channel_id, user.id, body.content, body.reply_to_id)
    if isinstance(result, str):
        raise HTTPException(status.HTTP_403_FORBIDDEN, result)
    # Build response
    return MessageOut(
        id=result.id,
        channel_id=result.channel_id,
        user_id=result.user_id,
        username=user.first_name or "Unknown",
        avatar_url=user.avatar_url,
        user_tier=None,
        content=result.content,
        original_language=result.original_language,
        reply_to_id=result.reply_to_id,
        reply_preview=None,
        reactions=[],
        is_pinned=result.is_pinned,
        is_system=result.is_system,
        created_at=result.created_at,
    )


@router.post("/messages/{message_id}/reactions", status_code=status.HTTP_201_CREATED)
async def create_reaction(
    message_id: uuid.UUID,
    body: ReactionCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # svc_add_reaction raises HTTPException 409 on duplicate; propagates naturally
    result = await svc_add_reaction(db, message_id, user.id, body.emoji)
    # TODO: emit Socket.IO "reaction_added" event to channel subscribers when
    # a socket namespace is wired into the REST layer.
    return result


@router.delete("/messages/{message_id}/reactions/{emoji}")
async def destroy_reaction(
    message_id: uuid.UUID,
    emoji: str,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    removed = await svc_remove_reaction(db, message_id, user.id, emoji)
    if not removed:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Reaction not found")
    # TODO: emit Socket.IO "reaction_removed" event to channel subscribers when
    # a socket namespace is wired into the REST layer.
    return {"message": "Reaction removed"}


@router.get("/messages/{message_id}/reactions")
async def list_reactions(
    message_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """Public endpoint — returns grouped reaction counts.

    Note: reacted_by_me will always be False because this endpoint does not
    require authentication.  Authenticated clients that need the reacted_by_me
    flag should use the authenticated variant or inspect the user's own
    reactions client-side.
    """
    reactions = await svc_get_reactions(db, message_id, requesting_user_id=None)
    return reactions


@router.post("/messages/{message_id}/report", status_code=status.HTTP_201_CREATED)
async def create_report(
    message_id: uuid.UUID,
    body: ReportCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        report = await report_message(db, message_id, user.id, body.reason)
    except ValueError as e:
        raise HTTPException(status.HTTP_404_NOT_FOUND, str(e))
    return {"message": "Report submitted", "id": str(report.id)}


@router.delete("/messages/{message_id}")
async def destroy_message(
    message_id: uuid.UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    deleted = await delete_message(db, message_id, user.id, is_admin=user.is_admin)
    if not deleted:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Message not found or not authorized")
    return {"message": "Message deleted"}


@router.post("/channels/{channel_id}/translate", response_model=TranslateResponse)
async def translate(
    channel_id: uuid.UUID,
    body: TranslateRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from sqlalchemy import select
    from app.models.message import Message

    msg_result = await db.execute(select(Message).where(Message.id == body.message_id))
    msg = msg_result.scalar_one_or_none()
    if msg is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Message not found")

    source_lang = msg.original_language or await detect_language(msg.content)
    translated = await translate_message(msg.content, source_lang, body.target_lang, str(msg.id))
    return TranslateResponse(
        original_text=msg.content,
        translated_text=translated,
        source_lang=source_lang,
        target_lang=body.target_lang,
    )
