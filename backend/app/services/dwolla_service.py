"""Dwolla ACH payout service.

Handles payout-only ACH transfers from the BlakJaks platform balance to
user bank accounts. Flow:

  1. Frontend calls Plaid Link, exchanges public token for processor token.
  2. Backend calls create_funding_source() with the Plaid processor token to
     register the user's bank in Dwolla.
  3. Backend calls initiate_transfer() to push funds from the master funding
     source to the user's bank.
  4. Backend polls get_transfer_status() until the transfer settles.

Dwolla environment is determined by DWOLLA_ENV setting ("sandbox" or "production").

Sandbox base URL : https://api-sandbox.dwolla.com
Production base URL: https://api.dwolla.com
"""

import hashlib
import hmac
import logging
from decimal import Decimal
from uuid import UUID

import httpx

from app.core.config import settings

logger = logging.getLogger(__name__)

_SANDBOX_BASE = "https://api-sandbox.dwolla.com"
_PROD_BASE = "https://api.dwolla.com"

_TOKEN_CACHE: dict = {}  # {"token": str, "expires_at": float}


def _base_url() -> str:
    return _SANDBOX_BASE if getattr(settings, "DWOLLA_ENV", "sandbox") == "sandbox" else _PROD_BASE


def _get_access_token() -> str:
    """Obtain (and cache) a Dwolla OAuth2 client-credentials token."""
    import time

    cached = _TOKEN_CACHE.get("token")
    if cached and _TOKEN_CACHE.get("expires_at", 0) > time.time() + 60:
        return cached

    if not settings.DWOLLA_KEY or not settings.DWOLLA_SECRET:
        raise RuntimeError("DWOLLA_KEY and DWOLLA_SECRET must be configured")

    resp = httpx.post(
        f"{_base_url()}/token",
        data={"grant_type": "client_credentials"},
        auth=(settings.DWOLLA_KEY, settings.DWOLLA_SECRET),
        timeout=15,
    )
    resp.raise_for_status()
    data = resp.json()
    token = data["access_token"]
    _TOKEN_CACHE["token"] = token
    _TOKEN_CACHE["expires_at"] = time.time() + data.get("expires_in", 3600)
    return token


def _headers() -> dict:
    return {
        "Accept": "application/vnd.dwolla.v1.hal+json",
        "Content-Type": "application/vnd.dwolla.v1.hal+json",
        "Authorization": f"Bearer {_get_access_token()}",
    }


def create_customer(
    user_id: UUID,
    email: str,
    first_name: str,
    last_name: str,
) -> str:
    """Create (or locate existing) Dwolla receive-only customer.

    Args:
        user_id: BlakJaks user UUID — stored as correlationId.
        email: User's email address.
        first_name: User's first name.
        last_name: User's last name.

    Returns:
        Dwolla customer resource URL (e.g. https://api.dwolla.com/customers/xxx).

    Raises:
        httpx.HTTPStatusError: On API error.
        RuntimeError: If Dwolla credentials are not configured.
    """
    resp = httpx.post(
        f"{_base_url()}/customers",
        json={
            "firstName": first_name,
            "lastName": last_name,
            "email": email,
            "type": "receive-only",
            "businessName": "",
            "correlationId": str(user_id),
        },
        headers=_headers(),
        timeout=15,
    )

    if resp.status_code == 201:
        return resp.headers["Location"]

    # 303 See Other → customer already exists
    if resp.status_code == 303:
        return resp.headers["Location"]

    # 422 with code "DuplicateResource" → extract existing customer URL
    if resp.status_code == 422:
        body = resp.json()
        embedded = body.get("_embedded", {})
        errors = embedded.get("errors", [{}])
        existing_url = errors[0].get("path", "")
        if existing_url:
            return existing_url

    resp.raise_for_status()
    return resp.headers["Location"]


def create_funding_source(customer_url: str, plaid_processor_token: str, account_name: str = "Bank Account") -> str:
    """Link a bank account via a Plaid processor token.

    Args:
        customer_url: Dwolla customer resource URL returned by create_customer().
        plaid_processor_token: Token from Plaid's /processor/token/create endpoint.
        account_name: Friendly label for the funding source.

    Returns:
        Dwolla funding source resource URL.

    Raises:
        httpx.HTTPStatusError: On API error.
    """
    customer_id = customer_url.rstrip("/").split("/")[-1]
    resp = httpx.post(
        f"{_base_url()}/customers/{customer_id}/funding-sources",
        json={
            "plaidToken": plaid_processor_token,
            "name": account_name,
        },
        headers=_headers(),
        timeout=15,
    )
    resp.raise_for_status()
    return resp.headers["Location"]


def initiate_transfer(
    destination_funding_source_url: str,
    amount_usd: Decimal,
) -> str:
    """Push funds from the BlakJaks master funding source to the user's bank.

    Args:
        destination_funding_source_url: Dwolla funding source URL for the user's bank.
        amount_usd: Amount in USD to transfer (e.g. Decimal("50.00")).

    Returns:
        Dwolla transfer resource URL.

    Raises:
        httpx.HTTPStatusError: On API error.
        RuntimeError: If DWOLLA_MASTER_FUNDING_SOURCE is not configured.
    """
    if not settings.DWOLLA_MASTER_FUNDING_SOURCE:
        raise RuntimeError("DWOLLA_MASTER_FUNDING_SOURCE must be configured with the platform's Dwolla funding source URL")

    resp = httpx.post(
        f"{_base_url()}/transfers",
        json={
            "_links": {
                "source": {"href": settings.DWOLLA_MASTER_FUNDING_SOURCE},
                "destination": {"href": destination_funding_source_url},
            },
            "amount": {
                "currency": "USD",
                "value": str(amount_usd.quantize(Decimal("0.01"))),
            },
        },
        headers=_headers(),
        timeout=15,
    )
    resp.raise_for_status()
    return resp.headers["Location"]


def get_transfer_status(transfer_url: str) -> dict:
    """Retrieve the current status of a Dwolla transfer.

    Args:
        transfer_url: Dwolla transfer resource URL returned by initiate_transfer().

    Returns:
        Dict with keys: id, status, amount (dict), created.
        Status values: "pending", "processed", "failed", "cancelled".

    Raises:
        httpx.HTTPStatusError: On API error.
    """
    resp = httpx.get(transfer_url, headers=_headers(), timeout=15)
    resp.raise_for_status()
    data = resp.json()
    return {
        "id": data.get("id", ""),
        "status": data.get("status", "unknown"),
        "amount": data.get("amount", {}),
        "created": data.get("created", ""),
    }


def get_platform_balance() -> Decimal:
    """Retrieve the available USD balance on the BlakJaks Dwolla master account.

    Returns:
        Available USD balance as Decimal, or Decimal("0") on any error.
    """
    if not settings.DWOLLA_MASTER_FUNDING_SOURCE:
        logger.warning("DWOLLA_MASTER_FUNDING_SOURCE not configured — returning 0")
        return Decimal("0")

    try:
        resp = httpx.get(
            settings.DWOLLA_MASTER_FUNDING_SOURCE,
            headers=_headers(),
            timeout=15,
        )
        resp.raise_for_status()
        data = resp.json()
        balance_value = data.get("balance", {}).get("value", "0")
        return Decimal(str(balance_value))
    except Exception as exc:
        logger.warning("Could not fetch Dwolla platform balance: %s", exc)
        return Decimal("0")


def verify_dwolla_webhook(request_body: bytes, signature_header: str) -> bool:
    """Verify Dwolla webhook authenticity using HMAC-SHA256.

    The signature_header is the value of X-Request-Signature-Sha-256.
    Raises ValueError if DWOLLA_SECRET is not configured.
    """
    secret = settings.DWOLLA_SECRET
    if not secret:
        raise ValueError("DWOLLA_SECRET must be configured to verify webhooks")

    expected = hmac.new(
        secret.encode("utf-8"),
        request_body,
        hashlib.sha256,
    ).hexdigest()

    return hmac.compare_digest(expected, signature_header)
