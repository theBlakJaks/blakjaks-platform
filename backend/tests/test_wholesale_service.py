"""Tests for app.services.wholesale_service — wholesale account and order management."""

import uuid
from decimal import Decimal
from unittest.mock import AsyncMock, MagicMock

import pytest
from fastapi import HTTPException

from app.services.wholesale_service import (
    approve_wholesale_account,
    create_order,
    create_wholesale_account,
    get_order,
    get_wholesale_account,
    list_orders,
    list_wholesale_accounts,
    update_order_status,
)

pytestmark = pytest.mark.asyncio


# ── Helpers ───────────────────────────────────────────────────────────


def _make_db() -> AsyncMock:
    """Return a minimal AsyncSession mock with commit/refresh pre-wired."""
    db = AsyncMock()
    db.commit = AsyncMock()
    db.refresh = AsyncMock()
    db.add = MagicMock()
    return db


def _scalar_result(value):
    """Wrap a value so db.execute(...).scalar_one_or_none() returns it."""
    result = MagicMock()
    result.scalar_one_or_none.return_value = value
    result.scalar_one.return_value = value
    result.scalars.return_value.all.return_value = value if isinstance(value, list) else []
    return result


# ── create_wholesale_account ──────────────────────────────────────────


async def test_create_wholesale_account_sets_pending_status():
    """create_wholesale_account should produce an account with status='pending'."""
    db = _make_db()
    user_id = uuid.uuid4()

    # db.refresh will mutate the object that was add()ed; simulate by capturing it
    captured = {}

    def _capture_add(obj):
        captured["account"] = obj

    db.add.side_effect = _capture_add

    async def _fake_refresh(obj):
        pass  # no-op; we inspect the object directly

    db.refresh.side_effect = _fake_refresh

    account = await create_wholesale_account(
        db,
        user_id=user_id,
        business_name="Acme Corp",
        contact_name="Alice",
        contact_email="alice@acme.com",
    )

    db.add.assert_called_once()
    db.commit.assert_called_once()
    db.refresh.assert_called_once()

    obj = captured["account"]
    assert obj.status == "pending"
    assert obj.user_id == user_id
    assert obj.business_name == "Acme Corp"
    assert obj.chips_balance == Decimal("0")


async def test_create_wholesale_account_approved_at_is_none():
    """Newly created accounts should not have approved_at set."""
    db = _make_db()
    captured = {}
    db.add.side_effect = lambda obj: captured.update({"account": obj})
    db.refresh.side_effect = AsyncMock()

    await create_wholesale_account(
        db,
        user_id=uuid.uuid4(),
        business_name="Beta Ltd",
        contact_name="Bob",
        contact_email="bob@beta.com",
    )

    obj = captured["account"]
    assert obj.approved_at is None
    assert obj.approved_by is None


# ── get_wholesale_account ─────────────────────────────────────────────


async def test_get_wholesale_account_returns_none_for_missing_user():
    """get_wholesale_account should return None when no record matches."""
    db = _make_db()
    db.execute.return_value = _scalar_result(None)

    result = await get_wholesale_account(db, uuid.uuid4())

    assert result is None


async def test_get_wholesale_account_returns_account_when_found():
    """get_wholesale_account should return the account object when it exists."""
    db = _make_db()
    fake_account = MagicMock()
    fake_account.user_id = uuid.uuid4()
    db.execute.return_value = _scalar_result(fake_account)

    result = await get_wholesale_account(db, fake_account.user_id)

    assert result is fake_account


# ── list_wholesale_accounts ───────────────────────────────────────────


async def test_list_wholesale_accounts_returns_paginated_dict():
    """list_wholesale_accounts should return the standard paginated dict."""
    db = _make_db()

    fake_accounts = [MagicMock(), MagicMock()]

    count_result = MagicMock()
    count_result.scalar_one.return_value = 2

    items_result = MagicMock()
    items_result.scalars.return_value.all.return_value = fake_accounts

    # First call → count, second call → items
    db.execute.side_effect = [count_result, items_result]

    result = await list_wholesale_accounts(db, page=1, per_page=20)

    assert result["total"] == 2
    assert result["page"] == 1
    assert result["per_page"] == 20
    assert result["items"] == fake_accounts


async def test_list_wholesale_accounts_respects_pagination_params():
    """list_wholesale_accounts should forward page and per_page correctly."""
    db = _make_db()

    count_result = MagicMock()
    count_result.scalar_one.return_value = 50

    items_result = MagicMock()
    items_result.scalars.return_value.all.return_value = []

    db.execute.side_effect = [count_result, items_result]

    result = await list_wholesale_accounts(db, page=3, per_page=10)

    assert result["page"] == 3
    assert result["per_page"] == 10
    assert result["total"] == 50


# ── create_order ──────────────────────────────────────────────────────


async def test_create_order_sets_pending_status():
    """create_order should produce orders with status='pending'."""
    db = _make_db()
    account_id = uuid.uuid4()

    captured_orders = []

    def _capture_add(obj):
        captured_orders.append(obj)

    db.add.side_effect = _capture_add
    db.refresh.side_effect = AsyncMock()

    items = [
        {"product_sku": "SKU-001", "quantity": 5, "unit_price": "10.00"},
    ]

    orders = await create_order(db, account_id=account_id, items=items)

    assert len(orders) == 1
    assert captured_orders[0].status == "pending"
    assert captured_orders[0].account_id == account_id


async def test_create_order_calculates_total_amount():
    """create_order should set total_amount = quantity * unit_price."""
    db = _make_db()
    captured_orders = []
    db.add.side_effect = lambda obj: captured_orders.append(obj)
    db.refresh.side_effect = AsyncMock()

    items = [
        {"product_sku": "SKU-002", "quantity": 3, "unit_price": "7.50"},
    ]

    await create_order(db, account_id=uuid.uuid4(), items=items)

    assert captured_orders[0].total_amount == Decimal("22.50")


async def test_create_order_supports_multiple_items():
    """create_order with multiple items should create one order row per item."""
    db = _make_db()
    captured_orders = []
    db.add.side_effect = lambda obj: captured_orders.append(obj)
    db.refresh.side_effect = AsyncMock()

    items = [
        {"product_sku": "A", "quantity": 1, "unit_price": "5.00"},
        {"product_sku": "B", "quantity": 2, "unit_price": "3.00"},
    ]

    orders = await create_order(db, account_id=uuid.uuid4(), items=items)

    assert len(orders) == 2
    assert len(captured_orders) == 2


# ── update_order_status ───────────────────────────────────────────────


async def test_update_order_status_changes_status():
    """update_order_status should update the order's status field."""
    db = _make_db()
    order_id = uuid.uuid4()

    fake_order = MagicMock()
    fake_order.id = order_id
    fake_order.status = "pending"

    db.execute.return_value = _scalar_result(fake_order)
    db.refresh.side_effect = AsyncMock()

    result = await update_order_status(db, order_id=order_id, new_status="confirmed")

    assert fake_order.status == "confirmed"
    db.commit.assert_called_once()


async def test_update_order_status_raises_404_for_missing_order():
    """update_order_status should raise HTTP 404 when the order doesn't exist."""
    db = _make_db()
    db.execute.return_value = _scalar_result(None)

    with pytest.raises(HTTPException) as exc_info:
        await update_order_status(db, order_id=uuid.uuid4(), new_status="confirmed")

    assert exc_info.value.status_code == 404


async def test_update_order_status_raises_400_for_invalid_status():
    """update_order_status should raise HTTP 400 for an unknown status string."""
    db = _make_db()

    with pytest.raises(HTTPException) as exc_info:
        await update_order_status(db, order_id=uuid.uuid4(), new_status="unknown_status")

    assert exc_info.value.status_code == 400


# ── approve_wholesale_account ─────────────────────────────────────────


async def test_approve_wholesale_account_sets_approved_status():
    """approve_wholesale_account should set status to 'approved' and record approved_at."""
    db = _make_db()
    account_id = uuid.uuid4()

    fake_account = MagicMock()
    fake_account.id = account_id
    fake_account.status = "pending"
    fake_account.approved_at = None
    fake_account.approved_by = None

    db.execute.return_value = _scalar_result(fake_account)
    db.refresh.side_effect = AsyncMock()

    result = await approve_wholesale_account(db, account_id=account_id)

    assert fake_account.status == "approved"
    assert fake_account.approved_at is not None
    db.commit.assert_called_once()


async def test_approve_wholesale_account_raises_404_when_not_found():
    """approve_wholesale_account should raise HTTP 404 for a missing account."""
    db = _make_db()
    db.execute.return_value = _scalar_result(None)

    with pytest.raises(HTTPException) as exc_info:
        await approve_wholesale_account(db, account_id=uuid.uuid4())

    assert exc_info.value.status_code == 404


async def test_approve_wholesale_account_records_approved_by():
    """approve_wholesale_account should store the admin user's ID in approved_by."""
    db = _make_db()
    account_id = uuid.uuid4()
    admin_id = uuid.uuid4()

    fake_account = MagicMock()
    fake_account.id = account_id
    fake_account.status = "pending"

    db.execute.return_value = _scalar_result(fake_account)
    db.refresh.side_effect = AsyncMock()

    await approve_wholesale_account(db, account_id=account_id, approved_by=admin_id)

    assert fake_account.approved_by == admin_id


# ── list_orders ───────────────────────────────────────────────────────


async def test_list_orders_returns_paginated_dict():
    """list_orders should return the standard paginated dict structure."""
    db = _make_db()

    fake_orders = [MagicMock(), MagicMock(), MagicMock()]

    count_result = MagicMock()
    count_result.scalar_one.return_value = 3

    items_result = MagicMock()
    items_result.scalars.return_value.all.return_value = fake_orders

    db.execute.side_effect = [count_result, items_result]

    result = await list_orders(db, page=1, per_page=20)

    assert result["total"] == 3
    assert result["page"] == 1
    assert result["per_page"] == 20
    assert result["items"] == fake_orders
