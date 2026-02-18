"""User wallet service — manages wallet records and transactions."""

import uuid
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.transaction import Transaction
from app.models.wallet import Wallet


async def create_user_wallet(db: AsyncSession, user_id: uuid.UUID) -> Wallet:
    """Create a placeholder wallet for a user.

    Real MetaMask Embedded Wallets integration comes in Task 9.
    For now, generates a placeholder address.
    """
    placeholder_address = f"0x{(uuid.uuid4().hex + uuid.uuid4().hex)[:40]}"

    wallet = Wallet(
        user_id=user_id,
        address=placeholder_address,
        balance_available=Decimal("0"),
        balance_pending=Decimal("0"),
    )
    db.add(wallet)
    await db.commit()
    await db.refresh(wallet)
    return wallet


async def get_user_wallet_balance(db: AsyncSession, user_id: uuid.UUID) -> dict:
    """Read wallet balances from the database."""
    result = await db.execute(select(Wallet).where(Wallet.user_id == user_id))
    wallet = result.scalar_one_or_none()
    if wallet is None:
        return {"address": None, "balance_available": Decimal("0"), "balance_pending": Decimal("0")}
    return {
        "address": wallet.address,
        "balance_available": wallet.balance_available,
        "balance_pending": wallet.balance_pending,
    }


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
