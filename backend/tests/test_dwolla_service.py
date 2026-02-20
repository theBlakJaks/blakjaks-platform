"""Tests for dwolla_service.py — Dwolla ACH payout service."""

import uuid
from decimal import Decimal
from unittest.mock import MagicMock, patch

import pytest


# ── Token caching ─────────────────────────────────────────────────────────────


def test_get_access_token_raises_without_credentials():
    from app.services.dwolla_service import _get_access_token
    from app.core.config import settings

    with patch.object(settings, "DWOLLA_KEY", ""), \
         patch.object(settings, "DWOLLA_SECRET", ""):
        with pytest.raises(RuntimeError, match="DWOLLA_KEY and DWOLLA_SECRET"):
            _get_access_token()


def test_get_access_token_caches_token():
    from app.services import dwolla_service
    from app.core.config import settings

    mock_resp = MagicMock()
    mock_resp.json.return_value = {"access_token": "tok_abc", "expires_in": 3600}
    mock_resp.raise_for_status = MagicMock()

    with patch.object(settings, "DWOLLA_KEY", "key"), \
         patch.object(settings, "DWOLLA_SECRET", "secret"), \
         patch("httpx.post", return_value=mock_resp) as mock_post:
        dwolla_service._TOKEN_CACHE.clear()
        t1 = dwolla_service._get_access_token()
        t2 = dwolla_service._get_access_token()

    assert t1 == "tok_abc"
    assert t2 == "tok_abc"
    mock_post.assert_called_once()


# ── create_customer ───────────────────────────────────────────────────────────


def test_create_customer_returns_location_on_201():
    from app.services.dwolla_service import create_customer

    mock_resp = MagicMock()
    mock_resp.status_code = 201
    mock_resp.headers = {"Location": "https://api-sandbox.dwolla.com/customers/abc-123"}

    with patch("app.services.dwolla_service._get_access_token", return_value="tok"), \
         patch("httpx.post", return_value=mock_resp):
        url = create_customer(uuid.uuid4(), "test@test.com", "John", "Doe")

    assert url == "https://api-sandbox.dwolla.com/customers/abc-123"


def test_create_customer_handles_duplicate_303():
    from app.services.dwolla_service import create_customer

    mock_resp = MagicMock()
    mock_resp.status_code = 303
    mock_resp.headers = {"Location": "https://api-sandbox.dwolla.com/customers/existing-123"}

    with patch("app.services.dwolla_service._get_access_token", return_value="tok"), \
         patch("httpx.post", return_value=mock_resp):
        url = create_customer(uuid.uuid4(), "test@test.com", "John", "Doe")

    assert url == "https://api-sandbox.dwolla.com/customers/existing-123"


# ── initiate_transfer ─────────────────────────────────────────────────────────


def test_initiate_transfer_raises_without_master_source():
    from app.services.dwolla_service import initiate_transfer
    from app.core.config import settings

    with patch.object(settings, "DWOLLA_MASTER_FUNDING_SOURCE", ""):
        with pytest.raises(RuntimeError, match="DWOLLA_MASTER_FUNDING_SOURCE"):
            initiate_transfer(
                "https://api-sandbox.dwolla.com/funding-sources/dest",
                Decimal("25.00"),
            )


def test_initiate_transfer_returns_location():
    from app.services.dwolla_service import initiate_transfer
    from app.core.config import settings

    mock_resp = MagicMock()
    mock_resp.status_code = 201
    mock_resp.headers = {"Location": "https://api-sandbox.dwolla.com/transfers/xfer-123"}
    mock_resp.raise_for_status = MagicMock()

    with patch.object(
        settings,
        "DWOLLA_MASTER_FUNDING_SOURCE",
        "https://api-sandbox.dwolla.com/funding-sources/master",
    ), \
         patch("app.services.dwolla_service._get_access_token", return_value="tok"), \
         patch("httpx.post", return_value=mock_resp):
        url = initiate_transfer(
            "https://api-sandbox.dwolla.com/funding-sources/dest",
            Decimal("50.00"),
        )

    assert url == "https://api-sandbox.dwolla.com/transfers/xfer-123"


# ── get_transfer_status ───────────────────────────────────────────────────────


def test_get_transfer_status_returns_normalized_dict():
    from app.services.dwolla_service import get_transfer_status

    mock_resp = MagicMock()
    mock_resp.raise_for_status = MagicMock()
    mock_resp.json.return_value = {
        "id": "xfer-123",
        "status": "processed",
        "amount": {"currency": "USD", "value": "50.00"},
        "created": "2025-05-01T12:00:00Z",
    }

    with patch("app.services.dwolla_service._get_access_token", return_value="tok"), \
         patch("httpx.get", return_value=mock_resp):
        result = get_transfer_status("https://api-sandbox.dwolla.com/transfers/xfer-123")

    assert result["id"] == "xfer-123"
    assert result["status"] == "processed"
    assert result["amount"]["value"] == "50.00"


# ── get_platform_balance ──────────────────────────────────────────────────────


def test_get_platform_balance_returns_zero_without_config():
    from app.services.dwolla_service import get_platform_balance
    from app.core.config import settings

    with patch.object(settings, "DWOLLA_MASTER_FUNDING_SOURCE", ""):
        balance = get_platform_balance()

    assert balance == Decimal("0")


def test_get_platform_balance_returns_decimal_from_api():
    from app.services.dwolla_service import get_platform_balance
    from app.core.config import settings

    mock_resp = MagicMock()
    mock_resp.raise_for_status = MagicMock()
    mock_resp.json.return_value = {"balance": {"value": "12345.67"}}

    with patch.object(
        settings,
        "DWOLLA_MASTER_FUNDING_SOURCE",
        "https://api-sandbox.dwolla.com/funding-sources/master",
    ), \
         patch("app.services.dwolla_service._get_access_token", return_value="tok"), \
         patch("httpx.get", return_value=mock_resp):
        balance = get_platform_balance()

    assert balance == Decimal("12345.67")
