"""Tests for teller_service.py — mocks httpx responses, no real Teller calls."""

import pytest
from decimal import Decimal
from unittest.mock import AsyncMock, MagicMock, patch

from app.services.teller_service import get_account_balance, get_last_sync_status, sync_all_balances


@pytest.mark.asyncio
async def test_get_account_balance_returns_none_when_no_cert():
    """When TELLER_CERT_PATH is blank, get_account_balance returns None gracefully."""
    from app.core.config import settings
    with patch.object(settings, "TELLER_CERT_PATH", ""):
        result = await get_account_balance("acc_test123")
    assert result is None


@pytest.mark.asyncio
async def test_get_account_balance_success():
    """Successful Teller API call returns Decimal balance."""
    from app.core.config import settings
    with patch.object(settings, "TELLER_CERT_PATH", "/fake/cert.pem"):
        with patch.object(settings, "TELLER_KEY_PATH", "/fake/key.pem"):
            mock_response = MagicMock()
            mock_response.raise_for_status = MagicMock()
            mock_response.json.return_value = {"available": "1234.56", "ledger": "1234.56"}

            mock_client = AsyncMock()
            mock_client.__aenter__ = AsyncMock(return_value=mock_client)
            mock_client.__aexit__ = AsyncMock(return_value=False)
            mock_client.get = AsyncMock(return_value=mock_response)

            with patch("app.services.teller_service.httpx.AsyncClient", return_value=mock_client):
                result = await get_account_balance("acc_test123")

    assert result == Decimal("1234.56")


@pytest.mark.asyncio
async def test_get_account_balance_http_error_returns_none():
    """HTTP error from Teller API returns None, not an exception."""
    import httpx
    from app.core.config import settings
    with patch.object(settings, "TELLER_CERT_PATH", "/fake/cert.pem"):
        with patch.object(settings, "TELLER_KEY_PATH", "/fake/key.pem"):
            mock_client = AsyncMock()
            mock_client.__aenter__ = AsyncMock(return_value=mock_client)
            mock_client.__aexit__ = AsyncMock(return_value=False)
            mock_client.get = AsyncMock(side_effect=httpx.HTTPStatusError(
                "404", request=MagicMock(), response=MagicMock(status_code=404, text="not found")
            ))

            with patch("app.services.teller_service.httpx.AsyncClient", return_value=mock_client):
                result = await get_account_balance("acc_notfound")

    assert result is None


@pytest.mark.asyncio
async def test_sync_all_balances_unconfigured_accounts():
    """Accounts without teller_account_id are skipped, not errored."""
    from app.models.teller_account import TellerAccount
    from decimal import Decimal

    mock_account = MagicMock(spec=TellerAccount)
    mock_account.name = "Operating Account"
    mock_account.teller_account_id = None
    mock_account.account_type = "operating"
    mock_account.balance = Decimal("0")

    mock_db = AsyncMock()
    mock_result = MagicMock()
    mock_result.scalars.return_value.all.return_value = [mock_account]
    mock_db.execute = AsyncMock(return_value=mock_result)

    results = await sync_all_balances(mock_db)

    assert "Operating Account" in results
    assert results["Operating Account"]["status"] == "unconfigured"


@pytest.mark.asyncio
async def test_sync_one_failure_does_not_abort_others():
    """A failure on one account does not prevent other accounts from syncing."""
    from app.models.teller_account import TellerAccount
    from app.core.config import settings

    mock_account1 = MagicMock(spec=TellerAccount)
    mock_account1.name = "Operating Account"
    mock_account1.teller_account_id = "acc_ok"
    mock_account1.account_type = "operating"
    mock_account1.balance = Decimal("0")

    mock_account2 = MagicMock(spec=TellerAccount)
    mock_account2.name = "Reserve Account"
    mock_account2.teller_account_id = "acc_fail"
    mock_account2.account_type = "reserve"
    mock_account2.balance = Decimal("0")

    mock_db = AsyncMock()
    mock_result = MagicMock()
    mock_result.scalars.return_value.all.return_value = [mock_account1, mock_account2]
    mock_db.execute = AsyncMock(return_value=mock_result)

    with patch(
        "app.services.teller_service.get_account_balance",
        side_effect=[Decimal("500.00"), None],
    ):
        with patch.object(settings, "TELLER_CERT_PATH", "/fake/cert.pem"):
            with patch.object(settings, "TELLER_KEY_PATH", "/fake/key.pem"):
                results = await sync_all_balances(mock_db)

    assert results["Operating Account"]["status"] == "ok"
    assert results["Reserve Account"]["status"] == "error"


@pytest.mark.asyncio
async def test_get_last_sync_status_returns_all_accounts():
    from app.models.teller_account import TellerAccount

    mock_account = MagicMock(spec=TellerAccount)
    mock_account.name = "Operating Account"
    mock_account.account_type = "operating"
    mock_account.balance = Decimal("9999.00")
    mock_account.currency = "USD"
    mock_account.last_synced_at = None
    mock_account.sync_status = "ok"
    mock_account.institution_name = "Chase"

    mock_db = AsyncMock()
    mock_result = MagicMock()
    mock_result.scalars.return_value.all.return_value = [mock_account]
    mock_db.execute = AsyncMock(return_value=mock_result)

    status = await get_last_sync_status(mock_db)

    assert len(status) == 1
    assert status[0]["name"] == "Operating Account"
    assert status[0]["sync_status"] == "ok"
