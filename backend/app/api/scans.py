from fastapi import APIRouter, Depends, Query
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import get_current_user, get_db
from app.api.schemas.scan import (
    ScanHistoryItem,
    ScanHistoryPage,
    ScanResponse,
    ScanSubmit,
)
from app.models.qr_code import QRCode
from app.models.scan import Scan
from app.models.user import User
from app.services.qr_code import submit_scan

router = APIRouter(prefix="/scans", tags=["scans"])


@router.post("/submit", response_model=ScanResponse)
async def scan_submit(
    body: ScanSubmit,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await submit_scan(db, current_user, body.qr_code)
    return ScanResponse(**result)


@router.get("/recent", response_model=list[ScanHistoryItem])
async def scans_recent(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Scan)
        .options(selectinload(Scan.qr_code).selectinload(QRCode.product))
        .where(Scan.user_id == current_user.id)
        .order_by(Scan.created_at.desc())
        .limit(20)
    )
    scans = result.scalars().all()
    return [
        ScanHistoryItem(
            id=s.id,
            product_name=s.qr_code.product.name if s.qr_code and s.qr_code.product else None,
            scanned_at=s.created_at,
        )
        for s in scans
    ]


@router.get("/history", response_model=ScanHistoryPage)
async def scans_history(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    base = select(Scan).where(Scan.user_id == current_user.id)

    count_result = await db.execute(
        select(func.count()).select_from(base.subquery())
    )
    total = count_result.scalar_one()

    result = await db.execute(
        base
        .options(selectinload(Scan.qr_code).selectinload(QRCode.product))
        .order_by(Scan.created_at.desc())
        .offset((page - 1) * per_page)
        .limit(per_page)
    )
    scans = result.scalars().all()

    return ScanHistoryPage(
        items=[
            ScanHistoryItem(
                id=s.id,
                product_name=s.qr_code.product.name if s.qr_code and s.qr_code.product else None,
                scanned_at=s.created_at,
            )
            for s in scans
        ],
        total=total,
        page=page,
        per_page=per_page,
    )
