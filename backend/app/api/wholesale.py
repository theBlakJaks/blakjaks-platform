"""Wholesale endpoints — account application, order management, and admin controls."""

import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.services.wholesale_service import (
    approve_wholesale_account,
    create_order,
    create_wholesale_account,
    get_order,
    get_wholesale_account,
    get_wholesale_account_by_id,
    list_orders,
    list_wholesale_accounts,
    update_order_status,
)

router = APIRouter(tags=["wholesale"])


# ── Dependency helpers ────────────────────────────────────────────────


def require_admin(user: User = Depends(get_current_user)) -> User:
    if not user.is_admin:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Admin access required")
    return user


# ── Request schemas ───────────────────────────────────────────────────


class WholesaleAccountCreate(BaseModel):
    business_name: str
    contact_name: str
    contact_email: str
    contact_phone: str | None = None
    business_address: str | None = None
    notes: str | None = None


class OrderItemIn(BaseModel):
    product_sku: str | None = None
    product_id: str | None = None
    quantity: int
    unit_price: float


class OrderCreate(BaseModel):
    items: list[OrderItemIn]
    notes: str | None = None


class OrderStatusUpdate(BaseModel):
    status: str


# ── Customer endpoints: /wholesale ────────────────────────────────────


@router.get("/wholesale/account")
async def get_my_account(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get the current user's wholesale account."""
    account = await get_wholesale_account(db, user.id)
    if account is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Wholesale account not found")
    return {
        "id": str(account.id),
        "user_id": str(account.user_id),
        "business_name": account.business_name,
        "contact_name": account.contact_name,
        "contact_email": account.contact_email,
        "contact_phone": account.contact_phone,
        "business_address": account.business_address,
        "status": account.status,
        "chips_balance": str(account.chips_balance),
        "approved_at": account.approved_at,
        "notes": account.notes,
        "created_at": account.created_at,
    }


@router.post("/wholesale/account", status_code=status.HTTP_201_CREATED)
async def apply_for_account(
    body: WholesaleAccountCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Apply for a wholesale account. Creates account with status='pending'."""
    existing = await get_wholesale_account(db, user.id)
    if existing is not None:
        raise HTTPException(status.HTTP_409_CONFLICT, "Wholesale account already exists")

    account = await create_wholesale_account(
        db,
        user_id=user.id,
        business_name=body.business_name,
        contact_name=body.contact_name,
        contact_email=body.contact_email,
        contact_phone=body.contact_phone,
        business_address=body.business_address,
        notes=body.notes,
    )
    return {
        "id": str(account.id),
        "user_id": str(account.user_id),
        "business_name": account.business_name,
        "contact_name": account.contact_name,
        "contact_email": account.contact_email,
        "contact_phone": account.contact_phone,
        "business_address": account.business_address,
        "status": account.status,
        "chips_balance": str(account.chips_balance),
        "approved_at": account.approved_at,
        "notes": account.notes,
        "created_at": account.created_at,
    }


@router.get("/wholesale/orders")
async def list_my_orders(
    status_filter: str | None = Query(None, alias="status"),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """List the current user's wholesale orders."""
    account = await get_wholesale_account(db, user.id)
    if account is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Wholesale account not found")

    result = await list_orders(
        db,
        account_id=account.id,
        status=status_filter,
        page=page,
        per_page=per_page,
    )
    return {
        "items": [_serialize_order(o) for o in result["items"]],
        "total": result["total"],
        "page": result["page"],
        "per_page": result["per_page"],
    }


@router.post("/wholesale/orders", status_code=status.HTTP_201_CREATED)
async def create_my_order(
    body: OrderCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a new wholesale order. Account must be approved."""
    account = await get_wholesale_account(db, user.id)
    if account is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Wholesale account not found")
    if account.status != "approved":
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "Wholesale account is not approved",
        )

    if not body.items:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Order must contain at least one item")

    items_payload = [item.model_dump() for item in body.items]
    orders = await create_order(db, account_id=account.id, items=items_payload, notes=body.notes)
    return {"orders": [_serialize_order(o) for o in orders]}


@router.get("/wholesale/orders/{order_id}")
async def get_order_detail(
    order_id: uuid.UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get a single wholesale order. Must be the owner or an admin."""
    order = await get_order(db, order_id)
    if order is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Order not found")

    if not user.is_admin:
        account = await get_wholesale_account(db, user.id)
        if account is None or account.id != order.account_id:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "Access denied")

    return _serialize_order(order)


# ── Admin endpoints: /admin/wholesale ────────────────────────────────


@router.get("/admin/wholesale/accounts")
async def admin_list_accounts(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Admin: list all wholesale accounts (paginated)."""
    result = await list_wholesale_accounts(db, page=page, per_page=per_page)
    return {
        "items": [_serialize_account(a) for a in result["items"]],
        "total": result["total"],
        "page": result["page"],
        "per_page": result["per_page"],
    }


@router.post("/admin/wholesale/accounts/{account_id}/approve")
async def admin_approve_account(
    account_id: uuid.UUID,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Admin: approve a wholesale account."""
    account = await approve_wholesale_account(db, account_id=account_id, approved_by=admin.id)
    return _serialize_account(account)


@router.get("/admin/wholesale/orders")
async def admin_list_orders(
    status_filter: str | None = Query(None, alias="status"),
    account_id: uuid.UUID | None = Query(None),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Admin: list all wholesale orders with optional status and account filters."""
    result = await list_orders(
        db,
        account_id=account_id,
        status=status_filter,
        page=page,
        per_page=per_page,
    )
    return {
        "items": [_serialize_order(o) for o in result["items"]],
        "total": result["total"],
        "page": result["page"],
        "per_page": result["per_page"],
    }


@router.patch("/admin/wholesale/orders/{order_id}/status")
async def admin_update_order_status(
    order_id: uuid.UUID,
    body: OrderStatusUpdate,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Admin: update the status of a wholesale order."""
    order = await update_order_status(db, order_id=order_id, new_status=body.status)
    return _serialize_order(order)


# ── Serialisation helpers ─────────────────────────────────────────────


def _serialize_account(account) -> dict:
    return {
        "id": str(account.id),
        "user_id": str(account.user_id),
        "business_name": account.business_name,
        "contact_name": account.contact_name,
        "contact_email": account.contact_email,
        "contact_phone": account.contact_phone,
        "business_address": account.business_address,
        "status": account.status,
        "chips_balance": str(account.chips_balance),
        "approved_at": account.approved_at,
        "approved_by": str(account.approved_by) if account.approved_by else None,
        "notes": account.notes,
        "created_at": account.created_at,
    }


def _serialize_order(order) -> dict:
    return {
        "id": str(order.id),
        "account_id": str(order.account_id),
        "product_sku": order.product_sku,
        "quantity": order.quantity,
        "unit_price": str(order.unit_price),
        "total_amount": str(order.total_amount),
        "chips_earned": str(order.chips_earned),
        "status": order.status,
        "shipping_address": order.shipping_address,
        "tracking_number": order.tracking_number,
        "notes": order.notes,
        "created_at": order.created_at,
    }
