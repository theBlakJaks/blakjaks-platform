import uuid
from decimal import Decimal

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.services.wallet_service import (
    MIN_WITHDRAWAL_USDT,
    _deterministic_placeholder_address,
    create_user_wallet,
    get_user_transactions,
    get_user_wallet_balance,
    record_transaction,
    request_withdrawal,
    update_wallet_address,
)
from tests.conftest import SIGNUP_PAYLOAD

pytestmark = pytest.mark.asyncio


# ── Deterministic placeholder address ────────────────────────────────


def test_deterministic_address_format():
    addr = _deterministic_placeholder_address("test@example.com")
    assert addr.startswith("0x")
    assert len(addr) == 42


def test_deterministic_address_is_stable():
    a1 = _deterministic_placeholder_address("test@example.com")
    a2 = _deterministic_placeholder_address("test@example.com")
    assert a1 == a2


def test_deterministic_address_case_insensitive():
    a1 = _deterministic_placeholder_address("Test@Example.COM")
    a2 = _deterministic_placeholder_address("test@example.com")
    assert a1 == a2


# ── Signup auto-creates wallet ───────────────────────────────────────


async def test_signup_creates_wallet(client: AsyncClient):
    resp = await client.post("/api/auth/signup", json=SIGNUP_PAYLOAD)
    assert resp.status_code == 201

    # Wallet should exist for the new user
    user_id = resp.json()["user"]["id"]
    token = resp.json()["tokens"]["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    wallet_resp = await client.get("/api/wallet", headers=headers)
    assert wallet_resp.status_code == 200
    data = wallet_resp.json()
    assert data["address"] is not None
    assert data["address"].startswith("0x")
    assert len(data["address"]) == 42


# ── Wallet service layer ─────────────────────────────────────────────


async def test_create_user_wallet_with_email(registered_user, db: AsyncSession):
    user_id = uuid.UUID(registered_user["user"]["id"])
    # registered_user already created a wallet via signup, so use a different user
    from app.models.user import User
    from app.core.security import hash_password

    user2 = User(
        email="wallet2@example.com",
        password_hash=hash_password("password123"),
        first_name="Wallet",
        last_name="Test",
    )
    db.add(user2)
    await db.commit()
    await db.refresh(user2)

    wallet = await create_user_wallet(db, user2.id, email="wallet2@example.com")
    expected = _deterministic_placeholder_address("wallet2@example.com")
    assert wallet.address == expected
    assert wallet.balance_available == Decimal("0")


async def test_get_wallet_balance_no_wallet(db: AsyncSession):
    fake_id = uuid.uuid4()
    result = await get_user_wallet_balance(db, fake_id)
    assert result["address"] is None
    assert result["balance_available"] == Decimal("0")


async def test_update_wallet_address(registered_user, db: AsyncSession):
    user_id = uuid.UUID(registered_user["user"]["id"])
    new_addr = "0x" + "ab" * 20
    wallet = await update_wallet_address(db, user_id, new_addr)
    assert wallet.address == new_addr


async def test_update_wallet_address_invalid(registered_user, db: AsyncSession):
    user_id = uuid.UUID(registered_user["user"]["id"])
    with pytest.raises(ValueError, match="Invalid Polygon address"):
        await update_wallet_address(db, user_id, "not-an-address")


# ── Withdrawal ───────────────────────────────────────────────────────


async def test_withdrawal_insufficient_balance(registered_user, db: AsyncSession):
    user_id = uuid.UUID(registered_user["user"]["id"])
    to_addr = "0x" + "cc" * 20
    with pytest.raises(ValueError, match="Insufficient balance"):
        await request_withdrawal(db, user_id, Decimal("10.00"), to_addr)


async def test_withdrawal_below_minimum(registered_user, db: AsyncSession):
    user_id = uuid.UUID(registered_user["user"]["id"])
    to_addr = "0x" + "cc" * 20
    with pytest.raises(ValueError, match="Minimum withdrawal"):
        await request_withdrawal(db, user_id, Decimal("1.00"), to_addr)


async def test_successful_withdrawal(registered_user, db: AsyncSession):
    user_id = uuid.UUID(registered_user["user"]["id"])

    # Fund the user's comp_balance first
    from app.models.user import User
    from sqlalchemy import select

    user_result = await db.execute(select(User).where(User.id == user_id))
    user = user_result.scalar_one()
    user.comp_balance = Decimal("100.00")
    await db.commit()

    to_addr = "0x" + "dd" * 20
    txn = await request_withdrawal(db, user_id, Decimal("25.00"), to_addr, method="crypto")
    assert txn.type == "withdrawal"
    assert txn.amount == Decimal("25.00")
    assert txn.status == "pending"
    assert txn.to_address == to_addr
    assert txn.payout_destination == "crypto"

    # Check comp_balance deducted
    await db.refresh(user)
    assert user.comp_balance == Decimal("75.00")


# ── Transaction history ──────────────────────────────────────────────


async def test_record_and_get_transactions(registered_user, db: AsyncSession):
    user_id = uuid.UUID(registered_user["user"]["id"])
    await record_transaction(db, user_id, type="comp_award", amount=Decimal("5.00"), status="completed")
    await record_transaction(db, user_id, type="comp_award", amount=Decimal("3.00"), status="completed")

    txns = await get_user_transactions(db, user_id)
    assert len(txns) == 2
    # Newest first
    assert txns[0].amount == Decimal("3.00")


# ── API endpoints ────────────────────────────────────────────────────


async def test_wallet_endpoint_unauthenticated(client: AsyncClient):
    resp = await client.get("/api/wallet")
    assert resp.status_code == 401


async def test_transactions_endpoint(client: AsyncClient, auth_headers):
    resp = await client.get("/api/wallet/transactions", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert "transactions" in data
    assert "count" in data


async def test_withdraw_endpoint_validation(client: AsyncClient, auth_headers):
    resp = await client.post(
        "/api/wallet/withdraw",
        json={"amount": "1.00", "to_address": "0x" + "aa" * 20},
        headers=auth_headers,
    )
    assert resp.status_code == 400
    assert "Minimum withdrawal" in resp.json()["detail"]


async def test_dwolla_customer_endpoint_unauthenticated(client: AsyncClient):
    resp = await client.post("/api/dwolla/customer")
    assert resp.status_code == 401


# ── Comp payout choice ───────────────────────────────────────────────

async def test_comp_payout_choice_crypto_credits_comp_balance(registered_user, db: AsyncSession):
    """Choosing crypto credits user.comp_balance."""
    user_id = uuid.UUID(registered_user["user"]["id"])

    # Award a comp (now creates pending_choice transaction)
    from app.services.comp_engine import award_crypto_comp
    txn = await award_crypto_comp(db, user_id, Decimal("100.00"))
    assert txn.status == "pending_choice"

    # Apply payout choice: crypto
    from app.services.wallet_service import apply_comp_payout_choice
    from app.models.user import User
    from sqlalchemy import select

    updated_txn = await apply_comp_payout_choice(db, user_id, txn.id, "crypto")
    assert updated_txn.status == "held"
    assert updated_txn.payout_destination == "crypto"

    user_result = await db.execute(select(User).where(User.id == user_id))
    user = user_result.scalar_one()
    assert user.comp_balance == Decimal("100.00")


async def test_comp_payout_choice_bank_credits_comp_balance(registered_user, db: AsyncSession):
    user_id = uuid.UUID(registered_user["user"]["id"])
    from app.services.comp_engine import award_crypto_comp
    txn = await award_crypto_comp(db, user_id, Decimal("50.00"))

    from app.services.wallet_service import apply_comp_payout_choice
    from app.models.user import User
    from sqlalchemy import select

    updated_txn = await apply_comp_payout_choice(db, user_id, txn.id, "bank")
    assert updated_txn.status == "held"
    assert updated_txn.payout_destination == "bank"

    user_result = await db.execute(select(User).where(User.id == user_id))
    user = user_result.scalar_one()
    assert user.comp_balance == Decimal("50.00")


async def test_comp_payout_choice_later_does_not_credit_balance(registered_user, db: AsyncSession):
    user_id = uuid.UUID(registered_user["user"]["id"])
    from app.services.comp_engine import award_crypto_comp
    txn = await award_crypto_comp(db, user_id, Decimal("75.00"))

    from app.services.wallet_service import apply_comp_payout_choice
    from app.models.user import User
    from sqlalchemy import select

    updated_txn = await apply_comp_payout_choice(db, user_id, txn.id, "later")
    assert updated_txn.status == "held"
    assert updated_txn.payout_destination == "held"

    user_result = await db.execute(select(User).where(User.id == user_id))
    user = user_result.scalar_one()
    assert user.comp_balance == Decimal("0.00")


async def test_comp_payout_choice_invalid_method(registered_user, db: AsyncSession):
    user_id = uuid.UUID(registered_user["user"]["id"])
    from app.services.comp_engine import award_crypto_comp
    txn = await award_crypto_comp(db, user_id, Decimal("25.00"))

    from app.services.wallet_service import apply_comp_payout_choice
    with pytest.raises(ValueError, match="method must be"):
        await apply_comp_payout_choice(db, user_id, txn.id, "invalid")


async def test_comp_payout_choice_not_found(registered_user, db: AsyncSession):
    user_id = uuid.UUID(registered_user["user"]["id"])
    from app.services.wallet_service import apply_comp_payout_choice
    fake_id = uuid.uuid4()
    with pytest.raises(ValueError, match="not found"):
        await apply_comp_payout_choice(db, user_id, fake_id, "crypto")


async def test_award_crypto_comp_does_not_credit_wallet(registered_user, db: AsyncSession):
    """award_crypto_comp should NOT update wallet.balance_available."""
    user_id = uuid.UUID(registered_user["user"]["id"])
    from app.services.comp_engine import award_crypto_comp
    from app.services.wallet_service import get_user_wallet

    wallet_before = await get_user_wallet(db, user_id)
    balance_before = wallet_before.balance_available if wallet_before else Decimal("0")

    await award_crypto_comp(db, user_id, Decimal("100.00"))

    wallet_after = await get_user_wallet(db, user_id)
    balance_after = wallet_after.balance_available if wallet_after else Decimal("0")

    assert balance_after == balance_before  # Balance unchanged


async def test_withdrawal_deducts_comp_balance(registered_user, db: AsyncSession):
    """request_withdrawal now deducts from user.comp_balance."""
    user_id = uuid.UUID(registered_user["user"]["id"])

    # Give the user some comp_balance first
    from app.models.user import User
    from sqlalchemy import select
    user_result = await db.execute(select(User).where(User.id == user_id))
    user = user_result.scalar_one()
    user.comp_balance = Decimal("200.00")
    await db.commit()

    to_addr = "0x" + "dd" * 20
    txn = await request_withdrawal(db, user_id, Decimal("50.00"), to_address=to_addr, method="crypto")
    assert txn.status == "pending"
    assert txn.payout_destination == "crypto"

    await db.refresh(user)
    assert user.comp_balance == Decimal("150.00")


async def test_comp_payout_choice_api_endpoint(client: AsyncClient, auth_headers):
    """POST /api/wallet/comp-payout-choice endpoint."""
    # Test that the endpoint exists and validates input
    resp = await client.post(
        "/api/wallet/comp-payout-choice",
        json={"comp_id": str(uuid.uuid4()), "method": "crypto"},
        headers=auth_headers,
    )
    # Should be 400 (comp not found) not 404/422
    assert resp.status_code == 400


async def test_wallet_detail_endpoint(client: AsyncClient, auth_headers):
    resp = await client.get("/api/wallet/detail", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert "comp_balance" in data
    assert "pending_comps" in data
    assert "address" in data
