"""Teller.io bank sync service.

Uses mTLS (mutual TLS) with the Teller-issued client certificate to authenticate.
Certificate and private key paths are configured via TELLER_CERT_PATH and TELLER_KEY_PATH.

Syncs balances for 3 accounts: Operating, Reserve, Comp Pool.
Writes results to teller_accounts and treasury_snapshots tables.
"""

import logging
from datetime import datetime, timezone
from decimal import Decimal

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.teller_account import TellerAccount
from app.models.treasury_snapshot import TreasurySnapshot

logger = logging.getLogger(__name__)

TELLER_API_BASE = "https://api.teller.io"


def _build_mtls_client() -> httpx.AsyncClient | None:
    """Build an httpx client configured with Teller mTLS credentials.

    Returns None if credentials are not configured — callers should handle
    the None case gracefully.
    """
    if not settings.TELLER_CERT_PATH or not settings.TELLER_KEY_PATH:
        logger.warning(
            "Teller mTLS credentials not configured. "
            "Set TELLER_CERT_PATH and TELLER_KEY_PATH (paths to .pem and .key files). "
            "Download the certificate bundle from teller.io → Application Settings."
        )
        return None

    try:
        return httpx.AsyncClient(
            cert=(settings.TELLER_CERT_PATH, settings.TELLER_KEY_PATH),
            timeout=30.0,
        )
    except Exception as exc:
        logger.error("Failed to initialize Teller mTLS client: %s", exc)
        return None


async def get_account_balance(teller_account_id: str) -> Decimal | None:
    """Fetch the current balance for a single Teller account.

    Args:
        teller_account_id: Teller-assigned account ID (e.g. "acc_abc123").

    Returns:
        Balance as Decimal, or None on error.
    """
    client = _build_mtls_client()
    if client is None:
        return None

    async with client:
        try:
            response = await client.get(
                f"{TELLER_API_BASE}/accounts/{teller_account_id}/balances",
            )
            response.raise_for_status()
            data = response.json()
            # Teller returns balance in the "available" field as a string
            balance_str = data.get("available") or data.get("ledger", "0")
            return Decimal(str(balance_str))
        except httpx.HTTPStatusError as exc:
            logger.error(
                "Teller API error for account %s: %s %s",
                teller_account_id,
                exc.response.status_code,
                exc.response.text,
            )
            return None
        except Exception as exc:
            logger.error("Teller balance fetch failed for %s: %s", teller_account_id, exc)
            return None


async def sync_all_balances(db: AsyncSession) -> dict:
    """Sync balances for all 3 Teller accounts and write to DB.

    Fetches all TellerAccount rows, syncs each via Teller API,
    writes updated balances to teller_accounts and a treasury_snapshot row.

    A failure on one account does NOT abort the entire sync — other accounts
    continue and the failed account is recorded with sync_status="error".

    Returns:
        dict with per-account sync results: {"account_name": {"balance": Decimal, "status": str}}
    """
    result = await db.execute(select(TellerAccount))
    accounts = list(result.scalars().all())

    if not accounts:
        logger.warning("No Teller accounts found in DB. Run migrations (015_teller_accounts) first.")
        return {}

    sync_results = {}
    now = datetime.now(timezone.utc)

    for account in accounts:
        account_result = {"balance": None, "status": "error"}

        try:
            if not account.teller_account_id:
                logger.info(
                    "Account %s has no teller_account_id — skipping live sync (no credentials).",
                    account.name,
                )
                account.sync_status = "unconfigured"
                account_result["status"] = "unconfigured"
            else:
                balance = await get_account_balance(account.teller_account_id)

                if balance is not None:
                    account.balance = balance
                    account.last_synced_at = now
                    account.sync_status = "ok"
                    account_result = {"balance": balance, "status": "ok"}

                    # Write treasury snapshot
                    snapshot = TreasurySnapshot(
                        timestamp=now,
                        pool_type=account.account_type,
                        onchain_balance=Decimal("0"),  # on-chain balance updated separately
                        bank_balance=balance,
                    )
                    db.add(snapshot)
                else:
                    account.sync_status = "error"
                    account_result["status"] = "error"

        except Exception as exc:
            logger.error("Unexpected error syncing account %s: %s", account.name, exc)
            account.sync_status = "error"

        sync_results[account.name] = account_result

    await db.commit()
    logger.info("Teller sync complete: %s", sync_results)
    return sync_results


async def get_last_sync_status(db: AsyncSession) -> list[dict]:
    """Return current balance and last sync time for each Teller account.

    Returns:
        List of dicts with: name, account_type, balance, currency,
        last_synced_at, sync_status, institution_name
    """
    result = await db.execute(select(TellerAccount))
    accounts = list(result.scalars().all())

    return [
        {
            "name": a.name,
            "account_type": a.account_type,
            "balance": float(a.balance),
            "currency": a.currency,
            "last_synced_at": a.last_synced_at.isoformat() if a.last_synced_at else None,
            "sync_status": a.sync_status,
            "institution_name": a.institution_name,
        }
        for a in accounts
    ]
