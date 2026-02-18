"""User wallet service — manages wallet records and transactions."""

import hashlib
import re
import uuid
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.transaction import Transaction
from app.models.wallet import Wallet

# Minimum withdrawal amount in USDT
MIN_WITHDRAWAL_USDT = Decimal("5.00")

# Polygon address regex: 0x followed by 40 hex chars
POLYGON_ADDRESS_RE = re.compile(r"^0x[0-9a-fA-F]{40}$")


def _deterministic_placeholder_address(email: str) -> str:
    """Generate a deterministic placeholder wallet address from an email.

    In production, the real address comes from the MetaMask Embedded Wallets SDK
    (Web3Auth) on the client side. This is a placeholder for development.
    """
    digest = hashlib.sha256(email.lower().encode()).hexdigest()
    return f"0x{digest[:40]}"


async def create_user_wallet(db: AsyncSession, user_id: uuid.UUID, email: str | None = None) -> Wallet:
    """Create a wallet for a user.

    If email is provided, generates a deterministic placeholder address.
    Otherwise, uses random UUIDs (legacy behaviour).
    """
    if email:
        address = _deterministic_placeholder_address(email)
    else:
        address = f"0x{(uuid.uuid4().hex + uuid.uuid4().hex)[:40]}"

    wallet = Wallet(
        user_id=user_id,
        address=address,
        balance_available=Decimal("0"),
        balance_pending=Decimal("0"),
    )
    db.add(wallet)
    await db.commit()
    await db.refresh(wallet)
    return wallet


async def get_user_wallet(db: AsyncSession, user_id: uuid.UUID) -> Wallet | None:
    """Get the wallet record for a user, or None."""
    result = await db.execute(select(Wallet).where(Wallet.user_id == user_id))
    return result.scalar_one_or_none()


async def get_user_wallet_balance(db: AsyncSession, user_id: uuid.UUID) -> dict:
    """Read wallet balances from the database."""
    wallet = await get_user_wallet(db, user_id)
    if wallet is None:
        return {"address": None, "balance_available": Decimal("0"), "balance_pending": Decimal("0")}
    return {
        "address": wallet.address,
        "balance_available": wallet.balance_available,
        "balance_pending": wallet.balance_pending,
    }


async def update_wallet_address(db: AsyncSession, user_id: uuid.UUID, new_address: str) -> Wallet:
    """Update a wallet's on-chain address (e.g. after MetaMask SDK setup)."""
    if not POLYGON_ADDRESS_RE.match(new_address):
        raise ValueError("Invalid Polygon address format")

    wallet = await get_user_wallet(db, user_id)
    if wallet is None:
        raise ValueError("User has no wallet")

    wallet.address = new_address
    await db.commit()
    await db.refresh(wallet)
    return wallet


async def request_withdrawal(
    db: AsyncSession,
    user_id: uuid.UUID,
    amount: Decimal,
    to_address: str,
) -> Transaction:
    """Request a USDT withdrawal from the user's available balance.

    Validates minimum amount and sufficient balance, then creates a pending
    transaction. Actual on-chain transfer happens in a background worker (future).
    """
    if amount < MIN_WITHDRAWAL_USDT:
        raise ValueError(f"Minimum withdrawal is {MIN_WITHDRAWAL_USDT} USDT")

    if not POLYGON_ADDRESS_RE.match(to_address):
        raise ValueError("Invalid Polygon address format")

    wallet = await get_user_wallet(db, user_id)
    if wallet is None:
        raise ValueError("User has no wallet")

    if wallet.balance_available < amount:
        raise ValueError("Insufficient balance")

    # Deduct from available, add to pending
    wallet.balance_available -= amount
    wallet.balance_pending += amount

    txn = Transaction(
        user_id=user_id,
        type="withdrawal",
        amount=amount,
        status="pending",
        to_address=to_address,
    )
    db.add(txn)
    await db.commit()
    await db.refresh(txn)
    return txn


async def get_user_transactions(
    db: AsyncSession,
    user_id: uuid.UUID,
    limit: int = 20,
    offset: int = 0,
) -> list[Transaction]:
    """Get paginated transaction history for a user, newest first."""
    result = await db.execute(
        select(Transaction)
        .where(Transaction.user_id == user_id)
        .order_by(Transaction.created_at.desc())
        .limit(limit)
        .offset(offset)
    )
    return list(result.scalars().all())


async def record_transaction(
    db: AsyncSession,
    user_id: uuid.UUID,
    type: str,
    amount: Decimal,
    tx_hash: str | None = None,
    from_address: str | None = None,
    to_address: str | None = None,
    status: str = "pending",
) -> Transaction:
    """Write a transaction record to the database."""
    txn = Transaction(
        user_id=user_id,
        type=type,
        amount=amount,
        status=status,
        tx_hash=tx_hash,
        from_address=from_address,
        to_address=to_address,
    )
    db.add(txn)
    await db.commit()
    await db.refresh(txn)
    return txn
