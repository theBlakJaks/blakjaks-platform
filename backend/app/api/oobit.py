"""Oobit crypto payment widget endpoints."""

from fastapi import APIRouter, Depends, HTTPException, status

from app.api.deps import get_current_user
from app.models.user import User
from app.services.oobit_service import generate_widget_token, get_widget_url

router = APIRouter(prefix="/oobit", tags=["oobit"])


@router.get("/widget-token")
async def oobit_widget_token(
    current_user: User = Depends(get_current_user),
):
    """Generate a signed Oobit widget token for the authenticated user.

    Returns a short-lived JWT (15 min) for embedding the Oobit payment widget.
    """
    try:
        token = generate_widget_token(current_user.id, current_user.email)
        url = get_widget_url(current_user.id, current_user.email)
    except RuntimeError as exc:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, str(exc))

    return {"token": token, "widget_url": url}
