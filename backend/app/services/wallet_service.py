"""User wallet service — manages wallet records and transactions."""

import hashlib
import re
import uuid
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.transaction import Transaction
from app.models.wallet import Wallet

# Minimum withdrawal amount in USDC
MIN_WITHDRAWAL_USDC = Decimal("5.00")

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
    from app.models.user import User

    wallet = await get_user_wallet(db, user_id)

    user_result = await db.execute(select(User).where(User.id == user_id))
    user = user_result.scalar_one_or_none()
    comp_balance = user.comp_balance if user else Decimal("0")

    if wallet is None:
        return {
            "address": None,
            "balance_available": Decimal("0"),
            "balance_pending": Decimal("0"),
            "comp_balance": comp_balance,
        }
    return {
        "address": wallet.address,
        "balance_available": wallet.balance_available,
        "balance_pending": wallet.balance_pending,
        "comp_balance": comp_balance,
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
    to_address: str | None = None,
    method: str = "crypto",  # 'crypto' | 'bank'
) -> Transaction:
    """Request a withdrawal from the user's comp_balance.

    Validates minimum amount and sufficient comp_balance, then creates a pending
    withdrawal transaction. Actual on-chain/ACH transfer happens in a background worker.

    For crypto: to_address is the Polygon wallet address.
    For bank: to_address is None (Dwolla handles via stored funding source).
    """
    if amount < MIN_WITHDRAWAL_USDC:
        raise ValueError(f"Minimum withdrawal is {MIN_WITHDRAWAL_USDC} USDC")

    if method == "crypto" and to_address and not POLYGON_ADDRESS_RE.match(to_address):
        raise ValueError("Invalid Polygon address format")

    from app.models.user import User

    user_result = await db.execute(
        select(User).where(User.id == user_id).with_for_update()
    )
    user = user_result.scalar_one_or_none()
    if user is None:
        raise ValueError("User not found")

    if user.comp_balance < amount:
        raise ValueError("Insufficient balance")

    # Deduct from comp_balance
    user.comp_balance -= amount

    txn = Transaction(
        user_id=user_id,
        type="withdrawal",
        amount=amount,
        status="pending",
        to_address=to_address,
        payout_destination=method,
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


async def apply_comp_payout_choice(
    db: AsyncSession,
    user_id: uuid.UUID,
    comp_txn_id: uuid.UUID,
    method: str,  # 'crypto' | 'bank' | 'later'
) -> Transaction:
    """Apply user's payout choice to a pending_choice comp transaction.

    - crypto/bank: credits comp_balance, sets status='held', sets payout_destination
    - later: sets status='held', payout_destination='held', no comp_balance change

    Returns the updated transaction.
    """
    from app.models.user import User

    if method not in ("crypto", "bank", "later"):
        raise ValueError("method must be 'crypto', 'bank', or 'later'")

    # Fetch the comp transaction
    result = await db.execute(
        select(Transaction).where(
            Transaction.id == comp_txn_id,
            Transaction.user_id == user_id,
            Transaction.type.in_(["comp_award", "guaranteed_comp"]),
            Transaction.status == "pending_choice",
        )
    )
    txn = result.scalar_one_or_none()
    if txn is None:
        raise ValueError("Comp transaction not found or not in pending_choice state")

    if method in ("crypto", "bank"):
        # Credit comp_balance
        user_result = await db.execute(select(User).where(User.id == user_id))
        user = user_result.scalar_one_or_none()
        if user is None:
            raise ValueError("User not found")
        user.comp_balance += txn.amount
        txn.payout_destination = method
        txn.status = "held"

        # Trigger affiliate reward matching now that choice is confirmed
        from app.services.comp_engine import process_affiliate_reward_match
        await process_affiliate_reward_match(db, user_id, txn.amount)
    else:
        # later — hold without crediting balance
        txn.payout_destination = "held"
        txn.status = "held"

    await db.commit()
    await db.refresh(txn)
    return txn
