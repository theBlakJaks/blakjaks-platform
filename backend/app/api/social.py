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
    add_reaction,
    delete_message,
    get_channel_messages,
    get_channels,
    get_pinned_messages,
    remove_reaction,
    report_message,
    send_message,
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
    result = await add_reaction(db, message_id, user.id, body.emoji)
    if isinstance(result, str):
        raise HTTPException(status.HTTP_409_CONFLICT, result)
    return {"message": "Reaction added", "id": str(result.id)}


@router.delete("/messages/{message_id}/reactions/{emoji}")
async def destroy_reaction(
    message_id: uuid.UUID,
    emoji: str,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    removed = await remove_reaction(db, message_id, user.id, emoji)
    if not removed:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Reaction not found")
    return {"message": "Reaction removed"}


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
