"""Dwolla ACH payout endpoints."""

from decimal import Decimal
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.models.user import User

router = APIRouter(prefix="/dwolla", tags=["dwolla"])


class CreateCustomerResponse(BaseModel):
    customer_url: str


class LinkBankRequest(BaseModel):
    plaid_processor_token: str
    account_name: str = "Bank Account"


class LinkBankResponse(BaseModel):
    funding_source_url: str


class WithdrawRequest(BaseModel):
    amount: Decimal
    funding_source_url: Optional[str] = None


class WithdrawResponse(BaseModel):
    transfer_url: str
    status: str


class TransferStatusResponse(BaseModel):
    id: str
    status: str
    amount: dict
    created: str


@router.post("/customer", response_model=CreateCustomerResponse)
async def create_dwolla_customer(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create (or retrieve) a Dwolla receive-only customer for the authenticated user."""
    from app.services.dwolla_service import create_customer

    try:
        customer_url = create_customer(
            user_id=current_user.id,
            email=current_user.email,
            first_name=current_user.first_name,
            last_name=current_user.last_name,
        )
    except RuntimeError as exc:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, str(exc))
    except Exception as exc:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, f"Dwolla error: {exc}")

    await db.execute(
        text(
            """
            INSERT INTO dwolla_customers (id, user_id, dwolla_customer_url)
            VALUES (gen_random_uuid(), :user_id, :customer_url)
            ON CONFLICT (user_id) DO UPDATE SET dwolla_customer_url = EXCLUDED.dwolla_customer_url
            """
        ),
        {"user_id": str(current_user.id), "customer_url": customer_url},
    )
    await db.commit()
    return {"customer_url": customer_url}


@router.post("/funding-source", response_model=LinkBankResponse)
async def link_bank_account(
    body: LinkBankRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Link a bank account via a Plaid processor token."""
    from app.services.dwolla_service import create_funding_source

    row = await db.execute(
        text("SELECT dwolla_customer_url FROM dwolla_customers WHERE user_id = :uid"),
        {"uid": str(current_user.id)},
    )
    rec = row.fetchone()
    if not rec:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Dwolla customer not found — call POST /api/dwolla/customer first",
        )

    try:
        funding_source_url = create_funding_source(
            customer_url=rec[0],
            plaid_processor_token=body.plaid_processor_token,
            account_name=body.account_name,
        )
    except Exception as exc:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, f"Dwolla error: {exc}")

    await db.execute(
        text(
            "UPDATE dwolla_customers SET dwolla_funding_source_url = :url WHERE user_id = :uid"
        ),
        {"url": funding_source_url, "uid": str(current_user.id)},
    )
    await db.commit()
    return {"funding_source_url": funding_source_url}


@router.post("/withdraw", response_model=WithdrawResponse)
async def initiate_ach_withdrawal(
    body: WithdrawRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Initiate an ACH payout from the platform balance to the user's linked bank."""
    from app.services.dwolla_service import initiate_transfer

    funding_source_url = body.funding_source_url
    if not funding_source_url:
        row = await db.execute(
            text(
                "SELECT dwolla_funding_source_url FROM dwolla_customers WHERE user_id = :uid"
            ),
            {"uid": str(current_user.id)},
        )
        rec = row.fetchone()
        if not rec or not rec[0]:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                "No linked bank account — call POST /api/dwolla/funding-source first",
            )
        funding_source_url = rec[0]

    try:
        transfer_url = initiate_transfer(
            destination_funding_source_url=funding_source_url,
            amount_usd=body.amount,
        )
    except RuntimeError as exc:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, str(exc))
    except Exception as exc:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, f"Dwolla error: {exc}")

    return {"transfer_url": transfer_url, "status": "pending"}


@router.get("/status/{transfer_id}", response_model=TransferStatusResponse)
async def get_ach_status(
    transfer_id: str,
    current_user: User = Depends(get_current_user),
):
    """Get the current status of a Dwolla ACH transfer."""
    from app.services.dwolla_service import get_transfer_status
    from app.core.config import settings

    base = (
        "https://api-sandbox.dwolla.com"
        if getattr(settings, "DWOLLA_ENV", "sandbox") == "sandbox"
        else "https://api.dwolla.com"
    )
    transfer_url = f"{base}/transfers/{transfer_id}"

    try:
        data = get_transfer_status(transfer_url)
    except Exception as exc:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, f"Dwolla error: {exc}")

    return data
