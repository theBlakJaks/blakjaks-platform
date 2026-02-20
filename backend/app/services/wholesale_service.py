"""Wholesale service — account management, order creation and status tracking."""

import uuid
from datetime import datetime, timezone
from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.wholesale_account import WholesaleAccount
from app.models.wholesale_order import WholesaleOrder

VALID_STATUSES = {"pending", "confirmed", "shipped", "delivered", "cancelled"}


# ── Wholesale account CRUD ────────────────────────────────────────────


async def create_wholesale_account(
    db: AsyncSession,
    user_id: uuid.UUID,
    business_name: str,
    contact_name: str,
    contact_email: str,
    contact_phone: str | None = None,
    business_address: str | None = None,
    notes: str | None = None,
) -> WholesaleAccount:
    """Create a new wholesale account with status='pending' (unapproved)."""
    account = WholesaleAccount(
        user_id=user_id,
        business_name=business_name,
        contact_name=contact_name,
        contact_email=contact_email,
        contact_phone=contact_phone,
        business_address=business_address,
        status="pending",
        chips_balance=Decimal("0"),
        notes=notes,
    )
    db.add(account)
    await db.commit()
    await db.refresh(account)
    return account


async def get_wholesale_account(
    db: AsyncSession, user_id: uuid.UUID
) -> WholesaleAccount | None:
    """Get wholesale account by user_id. Returns None if not found."""
    result = await db.execute(
        select(WholesaleAccount).where(WholesaleAccount.user_id == user_id)
    )
    return result.scalar_one_or_none()


async def get_wholesale_account_by_id(
    db: AsyncSession, account_id: uuid.UUID
) -> WholesaleAccount | None:
    """Get wholesale account by account id. Returns None if not found."""
    result = await db.execute(
        select(WholesaleAccount).where(WholesaleAccount.id == account_id)
    )
    return result.scalar_one_or_none()


async def list_wholesale_accounts(
    db: AsyncSession, page: int = 1, per_page: int = 20
) -> dict:
    """Paginated list of all wholesale accounts.

    Returns {"items": [...], "total": int, "page": int, "per_page": int}.
    """
    count_result = await db.execute(
        select(func.count()).select_from(WholesaleAccount)
    )
    total = count_result.scalar_one()

    result = await db.execute(
        select(WholesaleAccount)
        .order_by(WholesaleAccount.created_at.desc())
        .offset((page - 1) * per_page)
        .limit(per_page)
    )
    items = list(result.scalars().all())

    return {"items": items, "total": total, "page": page, "per_page": per_page}


async def approve_wholesale_account(
    db: AsyncSession, account_id: uuid.UUID, approved_by: uuid.UUID | None = None
) -> WholesaleAccount:
    """Set account status to 'approved'. Raises 404 if not found."""
    account = await get_wholesale_account_by_id(db, account_id)
    if account is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Wholesale account not found")

    account.status = "approved"
    account.approved_at = datetime.now(timezone.utc)
    if approved_by is not None:
        account.approved_by = approved_by

    await db.commit()
    await db.refresh(account)
    return account


# ── Wholesale order CRUD ──────────────────────────────────────────────


async def create_order(
    db: AsyncSession,
    account_id: uuid.UUID,
    items: list[dict],
    notes: str | None = None,
) -> list[WholesaleOrder]:
    """Create one WholesaleOrder row per item with status='pending'.

    Each item dict must contain: product_sku (or product_id), quantity, unit_price.
    Returns the list of created WholesaleOrder instances.
    """
    created = []
    for item in items:
        # Accept either 'product_sku' or 'product_id' as the SKU key
        sku = item.get("product_sku") or item.get("product_id") or ""
        quantity = int(item["quantity"])
        unit_price = Decimal(str(item["unit_price"]))
        total_amount = (unit_price * quantity).quantize(Decimal("0.01"))

        order = WholesaleOrder(
            account_id=account_id,
            product_sku=sku,
            quantity=quantity,
            unit_price=unit_price,
            total_amount=total_amount,
            chips_earned=Decimal("0"),
            status="pending",
            notes=notes,
        )
        db.add(order)
        created.append(order)

    await db.commit()
    for order in created:
        await db.refresh(order)

    return created


async def get_order(
    db: AsyncSession, order_id: uuid.UUID
) -> WholesaleOrder | None:
    """Get a single wholesale order by id. Returns None if not found."""
    result = await db.execute(
        select(WholesaleOrder).where(WholesaleOrder.id == order_id)
    )
    return result.scalar_one_or_none()


async def list_orders(
    db: AsyncSession,
    account_id: uuid.UUID | None = None,
    status: str | None = None,
    page: int = 1,
    per_page: int = 20,
) -> dict:
    """Paginated list of wholesale orders, optionally filtered by account_id and/or status.

    Returns {"items": [...], "total": int, "page": int, "per_page": int}.
    """
    query = select(WholesaleOrder)

    if account_id is not None:
        query = query.where(WholesaleOrder.account_id == account_id)
    if status is not None:
        query = query.where(WholesaleOrder.status == status)

    count_result = await db.execute(
        select(func.count()).select_from(query.subquery())
    )
    total = count_result.scalar_one()

    result = await db.execute(
        query.order_by(WholesaleOrder.created_at.desc())
        .offset((page - 1) * per_page)
        .limit(per_page)
    )
    items = list(result.scalars().all())

    return {"items": items, "total": total, "page": page, "per_page": per_page}


async def update_order_status(
    db: AsyncSession, order_id: uuid.UUID, new_status: str
) -> WholesaleOrder:
    """Update the status of a wholesale order.

    Valid statuses: pending, confirmed, shipped, delivered, cancelled.
    Raises 404 if order not found, 400 if status is invalid.
    """
    if new_status not in VALID_STATUSES:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"Invalid status '{new_status}'. Must be one of: {', '.join(sorted(VALID_STATUSES))}",
        )

    order = await get_order(db, order_id)
    if order is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Wholesale order not found")

    order.status = new_status
    await db.commit()
    await db.refresh(order)
    return order
