"""Tests for stargate_service.py — mocks contract calls, no real Ethereum."""

import pytest
from decimal import Decimal
from unittest.mock import MagicMock, patch


def _make_router_mock(native_fee=500_000_000_000_000):
    """Return a mock Stargate Router contract."""
    mock_quote = MagicMock()
    mock_quote.call.return_value = (native_fee, 0)

    mock_swap = MagicMock()
    mock_swap.build_transaction.return_value = {
        "from": "0xConsumer",
        "value": native_fee,
        "nonce": 1,
        "gas": 500_000,
        "gasPrice": 30_000_000_000,
        "chainId": 137,
    }

    mock_functions = MagicMock()
    mock_functions.quoteLayerZeroFee.return_value = mock_quote
    mock_functions.swap.return_value = mock_swap

    mock_router = MagicMock()
    mock_router.functions = mock_functions
    return mock_router


def _make_w3_mock(router_mock):
    mock_w3 = MagicMock()
    mock_w3.eth.contract.return_value = router_mock
    mock_w3.eth.get_transaction_count.return_value = 1
    mock_w3.eth.gas_price = 30_000_000_000
    mock_w3.eth.chain_id = 137
    mock_w3.eth.send_raw_transaction.return_value = bytes.fromhex(
        "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
    )
    return mock_w3


# ---------------------------------------------------------------------------
# get_bridge_quote
# ---------------------------------------------------------------------------


def test_get_bridge_quote_returns_expected_keys():
    from app.services.stargate_service import get_bridge_quote

    router_mock = _make_router_mock(native_fee=400_000_000_000_000)
    w3_mock = _make_w3_mock(router_mock)

    with patch("app.services.stargate_service.get_w3", return_value=w3_mock), \
         patch("app.services.stargate_service.get_consumer_pool_address",
               return_value="0x1234567890123456789012345678901234567890"):
        result = get_bridge_quote(Decimal("100"))

    assert "native_fee_wei" in result
    assert "native_fee_eth" in result
    assert "amount_usdt" in result


def test_get_bridge_quote_fee_values():
    from app.services.stargate_service import get_bridge_quote

    native_fee = 500_000_000_000_000
    router_mock = _make_router_mock(native_fee=native_fee)
    w3_mock = _make_w3_mock(router_mock)

    with patch("app.services.stargate_service.get_w3", return_value=w3_mock), \
         patch("app.services.stargate_service.get_consumer_pool_address",
               return_value="0x1234567890123456789012345678901234567890"):
        result = get_bridge_quote(Decimal("250"))

    assert result["native_fee_wei"] == native_fee
    assert abs(result["native_fee_eth"] - 0.0005) < 1e-8
    assert result["amount_usdt"] == 250.0


def test_get_bridge_quote_calls_quote_with_correct_chain_id():
    from app.services.stargate_service import get_bridge_quote, LAYERZERO_CHAIN_ID_GOERLI

    router_mock = _make_router_mock()
    w3_mock = _make_w3_mock(router_mock)

    with patch("app.services.stargate_service.get_w3", return_value=w3_mock), \
         patch("app.services.stargate_service.get_consumer_pool_address",
               return_value="0x1234567890123456789012345678901234567890"), \
         patch("app.services.stargate_service.settings") as mock_settings:
        mock_settings.POLYGON_NETWORK = "testnet"
        result = get_bridge_quote(Decimal("10"))

    call_args = router_mock.functions.quoteLayerZeroFee.call_args
    assert call_args[0][0] == LAYERZERO_CHAIN_ID_GOERLI


def test_get_bridge_quote_raises_on_contract_error():
    from app.services.stargate_service import get_bridge_quote

    router_mock = MagicMock()
    router_mock.functions.quoteLayerZeroFee.return_value.call.side_effect = Exception("RPC error")
    w3_mock = _make_w3_mock(router_mock)

    with patch("app.services.stargate_service.get_w3", return_value=w3_mock), \
         patch("app.services.stargate_service.get_consumer_pool_address",
               return_value="0x1234567890123456789012345678901234567890"):
        with pytest.raises(RuntimeError, match="Could not get Stargate bridge quote"):
            get_bridge_quote(Decimal("100"))


# ---------------------------------------------------------------------------
# execute_bridge
# ---------------------------------------------------------------------------


def test_execute_bridge_returns_tx_hash():
    from app.services.stargate_service import execute_bridge

    router_mock = _make_router_mock()
    w3_mock = _make_w3_mock(router_mock)
    raw_signed = b"\xde\xad\xbe\xef"

    with patch("app.services.stargate_service.get_w3", return_value=w3_mock), \
         patch("app.services.stargate_service.get_consumer_pool_address",
               return_value="0x1234567890123456789012345678901234567890"), \
         patch("app.services.stargate_service.sign_transaction_with_kms", return_value=raw_signed):
        result = execute_bridge(
            Decimal("500"),
            "0xAbCdEf0123456789012345678901234567890123",
        )

    assert "tx_hash" in result
    assert "layerzero_scan_url" in result
    assert "amount_usdt" in result
    assert result["amount_usdt"] == 500.0


def test_execute_bridge_includes_layerzero_scan_url():
    from app.services.stargate_service import execute_bridge, LAYERZERO_SCAN_BASE

    router_mock = _make_router_mock()
    w3_mock = _make_w3_mock(router_mock)
    raw_signed = b"\xde\xad\xbe\xef"

    with patch("app.services.stargate_service.get_w3", return_value=w3_mock), \
         patch("app.services.stargate_service.get_consumer_pool_address",
               return_value="0x1234567890123456789012345678901234567890"), \
         patch("app.services.stargate_service.sign_transaction_with_kms", return_value=raw_signed):
        result = execute_bridge(Decimal("100"), "0xAbCdEf0123456789012345678901234567890123")

    assert result["layerzero_scan_url"].startswith(LAYERZERO_SCAN_BASE)
    assert result["tx_hash"] in result["layerzero_scan_url"]


def test_execute_bridge_applies_slippage_tolerance():
    """min_amount_ld must be <= 99.5% of amount_ld."""
    from app.services.stargate_service import execute_bridge

    router_mock = _make_router_mock()
    w3_mock = _make_w3_mock(router_mock)

    captured_args = {}

    def capture_swap(*args, **kwargs):
        captured_args["args"] = args
        captured_args["kwargs"] = kwargs
        return router_mock.functions.swap.return_value

    router_mock.functions.swap = capture_swap

    with patch("app.services.stargate_service.get_w3", return_value=w3_mock), \
         patch("app.services.stargate_service.get_consumer_pool_address",
               return_value="0x1234567890123456789012345678901234567890"), \
         patch("app.services.stargate_service.sign_transaction_with_kms", return_value=b"\x00"):
        execute_bridge(Decimal("1000"), "0xAbCdEf0123456789012345678901234567890123")

    amount_ld = captured_args["args"][4]   # _amountLD positional
    min_amount_ld = captured_args["args"][5]  # _minAmountLD positional
    assert min_amount_ld <= amount_ld * 0.995 + 1  # allow 1 unit rounding


def test_execute_bridge_amount_ld_uses_6_decimals():
    """USDT has 6 decimals — amount_ld = amount * 1_000_000."""
    from app.services.stargate_service import execute_bridge

    router_mock = _make_router_mock()
    w3_mock = _make_w3_mock(router_mock)

    captured_args = {}

    def capture_swap(*args, **kwargs):
        captured_args["args"] = args
        captured_args["kwargs"] = kwargs
        return router_mock.functions.swap.return_value

    router_mock.functions.swap = capture_swap

    with patch("app.services.stargate_service.get_w3", return_value=w3_mock), \
         patch("app.services.stargate_service.get_consumer_pool_address",
               return_value="0x1234567890123456789012345678901234567890"), \
         patch("app.services.stargate_service.sign_transaction_with_kms", return_value=b"\x00"):
        execute_bridge(Decimal("250"), "0xAbCdEf0123456789012345678901234567890123")

    amount_ld = captured_args["args"][4]
    assert amount_ld == 250 * 1_000_000


# ---------------------------------------------------------------------------
# get_bridge_status
# ---------------------------------------------------------------------------


def test_get_bridge_status_delivered():
    from app.services.stargate_service import get_bridge_status

    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {"messages": [{"status": "DELIVERED"}]}

    mock_client = MagicMock()
    mock_client.__enter__ = MagicMock(return_value=mock_client)
    mock_client.__exit__ = MagicMock(return_value=False)
    mock_client.get.return_value = mock_response

    with patch("app.services.stargate_service.httpx.Client", return_value=mock_client):
        result = get_bridge_status("0xdeadbeef")

    assert result["status"] == "DELIVERED"
    assert result["tx_hash"] == "0xdeadbeef"


def test_get_bridge_status_no_messages_returns_pending():
    from app.services.stargate_service import get_bridge_status

    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {"messages": []}

    mock_client = MagicMock()
    mock_client.__enter__ = MagicMock(return_value=mock_client)
    mock_client.__exit__ = MagicMock(return_value=False)
    mock_client.get.return_value = mock_response

    with patch("app.services.stargate_service.httpx.Client", return_value=mock_client):
        result = get_bridge_status("0xdeadbeef")

    assert result["status"] == "pending"


def test_get_bridge_status_network_error_returns_unknown():
    from app.services.stargate_service import get_bridge_status

    mock_client = MagicMock()
    mock_client.__enter__ = MagicMock(return_value=mock_client)
    mock_client.__exit__ = MagicMock(return_value=False)
    mock_client.get.side_effect = Exception("timeout")

    with patch("app.services.stargate_service.httpx.Client", return_value=mock_client):
        result = get_bridge_status("0xdeadbeef")

    assert result["status"] == "unknown"
    assert result["tx_hash"] == "0xdeadbeef"


def test_get_bridge_status_non_200_returns_unknown():
    from app.services.stargate_service import get_bridge_status

    mock_response = MagicMock()
    mock_response.status_code = 404

    mock_client = MagicMock()
    mock_client.__enter__ = MagicMock(return_value=mock_client)
    mock_client.__exit__ = MagicMock(return_value=False)
    mock_client.get.return_value = mock_response

    with patch("app.services.stargate_service.httpx.Client", return_value=mock_client):
        result = get_bridge_status("0xdeadbeef")

    assert result["status"] == "unknown"
