"""Admin treasury bridge endpoints — admin-only, requires 2FA confirmation header."""

import os
from datetime import datetime, timezone
from decimal import Decimal

import pyotp
from fastapi import APIRouter, Depends, Header, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.models.audit_log import AuditLog
from app.models.user import User
from app.services.stargate_service import execute_bridge, get_bridge_quote, get_bridge_status
from app.services.teller_service import get_last_sync_status, sync_all_balances

router = APIRouter(prefix="/admin/treasury", tags=["admin-treasury"])


def require_admin(user: User = Depends(get_current_user)) -> User:
    if not user.is_admin:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Admin access required")
    return user


# ---------------------------------------------------------------------------
# Schemas
# ---------------------------------------------------------------------------


class BridgeRequest(BaseModel):
    amount_usdt: Decimal = Field(..., gt=0, description="USDT amount to bridge")
    destination_address: str = Field(..., description="Polygon recipient address")


class BridgeQuoteResponse(BaseModel):
    native_fee_wei: int
    native_fee_eth: float
    amount_usdt: float


class BridgeResponse(BaseModel):
    tx_hash: str
    layerzero_scan_url: str
    amount_usdt: float


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------


@router.get("/bridge/quote", response_model=BridgeQuoteResponse)
async def bridge_quote(
    amount_usdt: Decimal = Depends(lambda amount_usdt: amount_usdt),
    admin: User = Depends(require_admin),
):
    """Get LayerZero fee estimate for bridging USDT to Polygon."""
    from fastapi import Query

    raise HTTPException(
        status.HTTP_422_UNPROCESSABLE_ENTITY,
        "Use query param: /quote?amount_usdt=100",
    )


@router.get("/bridge/quote-amount")
async def bridge_quote_amount(
    amount_usdt: Decimal,
    admin: User = Depends(require_admin),
):
    """Get LayerZero fee estimate for bridging a specific USDT amount."""
    try:
        quote = get_bridge_quote(amount_usdt)
    except RuntimeError as exc:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, str(exc))
    return quote


@router.post("/bridge", response_model=BridgeResponse)
async def bridge_usdt(
    body: BridgeRequest,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
    x_2fa_token: str | None = Header(None, alias="X-2FA-Token"),
):
    """Bridge USDT from Ethereum treasury to Polygon.

    Requires the X-2FA-Token header to be present (admin 2FA confirmation).
    Logs the action to audit_logs.
    """
    if not x_2fa_token:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "X-2FA-Token header is required for treasury operations",
        )

    # TODO: Add totp_secret column to User model
    # Admin must have a 2FA secret configured; fall back to environment variable
    totp_secret = getattr(admin, "totp_secret", None) or os.environ.get("ADMIN_TOTP_SECRET")
    if not totp_secret:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "Admin account has no 2FA configured. Contact system administrator.",
        )

    totp = pyotp.TOTP(totp_secret)
    if not totp.verify(x_2fa_token, valid_window=1):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Invalid or expired 2FA token")

    try:
        result = execute_bridge(body.amount_usdt, body.destination_address)
    except Exception as exc:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, f"Bridge failed: {exc}")

    # Log to audit trail
    audit = AuditLog(
        actor_id=admin.id,
        action="admin_treasury_bridge",
        resource_type="stargate_bridge",
        resource_id=result["tx_hash"],
        details={
            "amount_usdt": str(body.amount_usdt),
            "destination_address": body.destination_address,
            "tx_hash": result["tx_hash"],
            "layerzero_scan_url": result["layerzero_scan_url"],
        },
    )
    db.add(audit)
    await db.commit()

    return BridgeResponse(**result)


@router.get("/bridge/status/{tx_hash}")
async def bridge_status(
    tx_hash: str,
    admin: User = Depends(require_admin),
):
    """Poll LayerZero for the status of a bridge transaction."""
    return get_bridge_status(tx_hash)


# ---------------------------------------------------------------------------
# Teller Bank Account Endpoints
# ---------------------------------------------------------------------------


@router.get("/teller")
async def get_teller_accounts(
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Return current Teller bank account balances and sync status for all accounts."""
    accounts = await get_last_sync_status(db)
    return accounts


@router.post("/teller-sync")
async def trigger_teller_sync(
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Manually trigger a Teller balance sync for all bank accounts."""
    try:
        await sync_all_balances(db)
        return {"success": True, "synced_at": datetime.now(timezone.utc).isoformat()}
    except Exception as exc:
        raise HTTPException(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            f"Teller sync failed: {exc}",
        )
