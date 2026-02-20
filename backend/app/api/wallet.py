"""Wallet endpoints — balance, transactions, withdrawal."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.api.schemas.wallet import (
    CompPayoutChoiceRequest,
    CompPayoutChoiceResponse,
    TransactionListResponse,
    TransactionResponse,
    WalletDetailResponse,
    WalletResponse,
    WithdrawRequest,
)
from app.models.user import User
from app.services.wallet_service import (
    apply_comp_payout_choice,
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


@router.get("/detail", response_model=WalletDetailResponse)
async def get_wallet_detail(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get wallet detail: comp_balance, wallet_address, pending comps, balances."""
    from sqlalchemy import select
    from app.models.transaction import Transaction as TransactionModel

    data = await get_user_wallet_balance(db, user.id)

    pending_result = await db.execute(
        select(TransactionModel).where(
            TransactionModel.user_id == user.id,
            TransactionModel.type.in_(["comp_award", "guaranteed_comp"]),
            TransactionModel.status == "pending_choice",
        ).order_by(TransactionModel.created_at.desc())
    )
    pending_comps = list(pending_result.scalars().all())

    return WalletDetailResponse(
        address=data["address"],
        comp_balance=data["comp_balance"],
        balance_available=data["balance_available"],
        balance_pending=data["balance_pending"],
        pending_comps=[
            {"id": t.id, "amount": t.amount, "type": t.type, "awarded_at": t.created_at}
            for t in pending_comps
        ],
    )


@router.post("/comp-payout-choice", response_model=CompPayoutChoiceResponse)
async def comp_payout_choice(
    body: CompPayoutChoiceRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Choose payout method for a pending_choice comp."""
    try:
        txn = await apply_comp_payout_choice(db, user.id, body.comp_id, body.method)
    except ValueError as e:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, str(e))
    return CompPayoutChoiceResponse(
        comp_id=txn.id,
        method=txn.payout_destination,
        status=txn.status,
        amount=txn.amount,
    )


@router.post("/withdraw", response_model=TransactionResponse, status_code=status.HTTP_201_CREATED)
async def withdraw(
    body: WithdrawRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Request a withdrawal from comp_balance (crypto to MetaMask or bank via Dwolla)."""
    try:
        txn = await request_withdrawal(
            db, user.id, body.amount, to_address=body.to_address, method=body.method
        )
    except ValueError as e:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, str(e))
    return TransactionResponse.model_validate(txn)
