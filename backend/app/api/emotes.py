"""Saved Emotes REST endpoints — CRUD for user's saved 7TV emotes."""

from fastapi import APIRouter, Depends, HTTPException, status
from slowapi import Limiter
from slowapi.util import get_remote_address
from sqlalchemy import delete, select, update
from sqlalchemy.ext.asyncio import AsyncSession
from starlette.requests import Request

from app.api.deps import get_current_user, get_db
from app.api.schemas.emotes import SavedEmoteCreate, SavedEmoteOut, SavedEmoteReorder
from app.models.saved_emote import SavedEmote
from app.models.user import User

limiter = Limiter(key_func=get_remote_address)

router = APIRouter(prefix="/emotes", tags=["emotes"])


@router.get("/saved", response_model=list[SavedEmoteOut])
@limiter.limit("60/minute")
async def list_saved_emotes(
    request: Request,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(SavedEmote)
        .where(SavedEmote.user_id == user.id)
        .order_by(SavedEmote.sort_order)
    )
    return result.scalars().all()


@router.post("/saved", response_model=SavedEmoteOut, status_code=status.HTTP_201_CREATED)
@limiter.limit("120/minute")
async def save_emote(
    request: Request,
    body: SavedEmoteCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Check if already saved
    existing = await db.execute(
        select(SavedEmote).where(
            SavedEmote.user_id == user.id,
            SavedEmote.emote_id == body.emote_id,
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status.HTTP_409_CONFLICT, "Emote already saved")

    # New emotes go to the front (sort_order = 0), shift others down
    await db.execute(
        update(SavedEmote)
        .where(SavedEmote.user_id == user.id)
        .values(sort_order=SavedEmote.sort_order + 1)
    )

    emote = SavedEmote(
        user_id=user.id,
        emote_id=body.emote_id,
        emote_name=body.emote_name,
        animated=body.animated,
        zero_width=body.zero_width,
        sort_order=0,
    )
    db.add(emote)
    await db.commit()
    await db.refresh(emote)
    return emote


@router.delete("/saved/{emote_id}", status_code=status.HTTP_204_NO_CONTENT)
@limiter.limit("120/minute")
async def delete_saved_emote(
    request: Request,
    emote_id: str,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        delete(SavedEmote).where(
            SavedEmote.user_id == user.id,
            SavedEmote.emote_id == emote_id,
        )
    )
    if result.rowcount == 0:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Emote not found")
    await db.commit()


@router.put("/saved/reorder", status_code=status.HTTP_204_NO_CONTENT)
@limiter.limit("30/minute")
async def reorder_saved_emotes(
    request: Request,
    body: SavedEmoteReorder,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    for idx, emote_id in enumerate(body.emote_ids):
        await db.execute(
            update(SavedEmote)
            .where(SavedEmote.user_id == user.id, SavedEmote.emote_id == emote_id)
            .values(sort_order=idx)
        )
    await db.commit()
