"""Giphy GIF search and trending endpoints for social chat."""

from fastapi import APIRouter, Depends, Query

from app.api.deps import get_current_user
from app.models.user import User
from app.services.giphy_service import get_trending_gifs, search_gifs

router = APIRouter(prefix="/giphy", tags=["giphy"])


@router.get("/search")
async def gif_search(
    q: str = Query(..., min_length=1, max_length=100),
    limit: int = Query(20, ge=1, le=50),
    offset: int = Query(0, ge=0),
    _user: User = Depends(get_current_user),
):
    """Search Giphy for GIFs. Results cached in Redis for 5 minutes."""
    results = await search_gifs(q, limit=limit, offset=offset)
    return {"results": results, "count": len(results)}


@router.get("/trending")
async def gif_trending(
    limit: int = Query(20, ge=1, le=50),
    _user: User = Depends(get_current_user),
):
    """Return trending GIFs from Giphy. Cached in Redis for 10 minutes."""
    results = await get_trending_gifs(limit=limit)
    return {"results": results, "count": len(results)}
