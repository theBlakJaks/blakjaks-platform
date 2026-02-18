import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.api.schemas.scan import (
    QRCodeGenerateRequest,
    QRCodeGenerateResponse,
    QRCodeListPage,
    QRCodeResponse,
)
from app.models.qr_code import QRCode
from app.models.user import User
from app.services.qr_code import generate_qr_codes

router = APIRouter(prefix="/admin/qr-codes", tags=["admin-qr"])


def require_admin(user: User = Depends(get_current_user)) -> User:
    if not user.is_admin:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Admin access required")
    return user


@router.post("/generate", response_model=QRCodeGenerateResponse)
async def generate(
    body: QRCodeGenerateRequest,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    codes = await generate_qr_codes(db, body.product_id, body.quantity)
    return QRCodeGenerateResponse(generated=len(codes), codes=codes)


@router.get("", response_model=QRCodeListPage)
async def list_qr_codes(
    page: int = Query(1, ge=1),
    per_page: int = Query(50, ge=1, le=200),
    product_id: uuid.UUID | None = None,
    is_used: bool | None = None,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    base = select(QRCode)
    if product_id is not None:
        base = base.where(QRCode.product_id == product_id)
    if is_used is not None:
        base = base.where(QRCode.is_used == is_used)

    count_result = await db.execute(
        select(func.count()).select_from(base.subquery())
    )
    total = count_result.scalar_one()

    result = await db.execute(
        base.order_by(QRCode.created_at.desc())
        .offset((page - 1) * per_page)
        .limit(per_page)
    )
    items = result.scalars().all()

    return QRCodeListPage(
        items=[
            QRCodeResponse(
                id=qr.id,
                product_code=qr.product_code,
                unique_id=qr.unique_id,
                full_code=qr.unique_id,
                is_used=qr.is_used,
                scanned_by=qr.scanned_by,
                scanned_at=qr.scanned_at,
                created_at=qr.created_at,
            )
            for qr in items
        ],
        total=total,
        page=page,
        per_page=per_page,
    )
