"""
Dev-only endpoints — returns 404 in production. Never exposes real operations.
All endpoints require admin auth AND non-production environment.
"""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from decimal import Decimal
from app.core.config import settings
from app.api.deps import get_current_user, get_db
from app.models.user import User


def get_current_admin_user(user: User = Depends(get_current_user)) -> User:
    if not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
    return user

router = APIRouter()


def _require_non_production():
    if settings.ENVIRONMENT == "production":
        raise HTTPException(status_code=404, detail="Not found")


class AwardCompRequest(BaseModel):
    user_email: str
    amount: float  # USD value, e.g. 50.00


class SendUsdcRequest(BaseModel):
    to_address: str
    amount: float


@router.post("/award-comp")
async def dev_award_comp(
    body: AwardCompRequest,
    _: None = Depends(_require_non_production),
    admin=Depends(get_current_admin_user),
    db=Depends(get_db),
):
    """
    Award a pending_choice comp to a user by email.
    The app will show the PayoutChoiceSheet (MetaMask / Bank / Later).
    Returns comp_id to use with POST /wallet/comp-payout-choice.
    """
    from sqlalchemy import select
    from app.models.user import User
    from app.models.comp import Comp
    import uuid

    result = await db.execute(select(User).where(User.email == body.user_email))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail=f"User {body.user_email!r} not found")

    comp = Comp(
        id=uuid.uuid4(),
        user_id=user.id,
        comp_amount=Decimal(str(body.amount)),
        status="pending_choice",
        source="dev_award",
    )
    db.add(comp)
    await db.commit()
    await db.refresh(comp)

    return {
        "comp_id": str(comp.id),
        "amount": body.amount,
        "user_id": str(user.id),
        "status": "pending_choice",
        "message": "Open the app → wallet tab → the pending comp banner will appear",
    }


@router.get("/treasury-status")
async def dev_treasury_status(
    _: None = Depends(_require_non_production),
    admin=Depends(get_current_admin_user),
):
    """Check treasury wallet USDC and MATIC balances on the configured network."""
    from app.services.blockchain import get_consumer_pool_address, get_usdc_balance, get_wallet_balance
    address = get_consumer_pool_address()
    usdc = get_usdc_balance(address)
    matic = get_wallet_balance(address)
    network = settings.POLYGON_NETWORK
    contract = (
        settings.USDC_CONTRACT_ADDRESS_MAINNET
        if network == "mainnet"
        else settings.USDC_CONTRACT_ADDRESS_AMOY
    )
    explorer_base = "https://polygonscan.com" if network == "mainnet" else "https://amoy.polygonscan.com"
    return {
        "treasury_address": address,
        "matic_balance": str(matic),
        "usdc_balance": str(usdc),
        "network": network,
        "usdc_contract": contract,
        "explorer_url": f"{explorer_base}/address/{address}",
    }


@router.post("/send-test-usdc")
async def dev_send_test_usdc(
    body: SendUsdcRequest,
    _: None = Depends(_require_non_production),
    admin=Depends(get_current_admin_user),
):
    """Manually send USDC from the consumer treasury to any address. Testnet only."""
    from app.services.blockchain import send_usdc_from_pool
    network = settings.POLYGON_NETWORK
    tx_hash = send_usdc_from_pool("consumer", body.to_address, Decimal(str(body.amount)))
    explorer_base = "https://polygonscan.com" if network == "mainnet" else "https://amoy.polygonscan.com"
    return {
        "tx_hash": tx_hash,
        "amount": body.amount,
        "to": body.to_address,
        "explorer_url": f"{explorer_base}/tx/{tx_hash}",
    }
