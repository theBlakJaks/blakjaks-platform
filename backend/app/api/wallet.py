"""Wallet endpoints — balance, transactions, withdrawal, Oobit card."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.api.schemas.wallet import (
    OobitActivateRequest,
    OobitActivateResponse,
    TransactionListResponse,
    TransactionResponse,
    WalletResponse,
    WithdrawRequest,
)
from app.models.user import User
from app.services.wallet_service import (
    get_user_transactions,
    get_user_wallet_balance,
    request_withdrawal,
)

router = APIRouter(prefix="/wallet", tags=["wallet"])


@router.get("", response_model=WalletResponse)
async def get_wallet(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get current user's wallet balance."""
    data = await get_user_wallet_balance(db, user.id)
    return WalletResponse(**data)


@router.get("/transactions", response_model=TransactionListResponse)
async def get_transactions(
    limit: int = 20,
    offset: int = 0,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get paginated transaction history."""
    txns = await get_user_transactions(db, user.id, limit=limit, offset=offset)
    return TransactionListResponse(
        transactions=[TransactionResponse.model_validate(t) for t in txns],
        count=len(txns),
    )


@router.post("/withdraw", response_model=TransactionResponse, status_code=status.HTTP_201_CREATED)
async def withdraw(
    body: WithdrawRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Request a USDT withdrawal."""
    try:
        txn = await request_withdrawal(db, user.id, body.amount, body.to_address)
    except ValueError as e:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, str(e))
    return TransactionResponse.model_validate(txn)


@router.post("/oobit/activate", response_model=OobitActivateResponse)
async def oobit_activate(
    body: OobitActivateRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Placeholder for Oobit card activation.

    Real integration comes in a future task. For now, returns a success stub.
    """
    return OobitActivateResponse(
        status="pending",
        message=f"Card ending in {body.card_last_four} activation queued. Oobit integration coming soon.",
    )
