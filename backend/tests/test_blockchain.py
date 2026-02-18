import uuid
from decimal import Decimal
from unittest.mock import MagicMock, patch

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from web3 import Web3

from app.services.blockchain import (
    AFFILIATE_POOL,
    COMPANY_RETAINED,
    CONSUMER_POOL,
    ERC20_ABI,
    WHOLESALE_POOL,
    _kms_key_version_path,
    get_wallet_balance,
    get_usdt_balance,
    kms_public_key_to_eth_address,
    w3,
)
from app.services.wallet_service import (
    create_user_wallet,
    get_user_wallet_balance,
    record_transaction,
)
from tests.conftest import SIGNUP_PAYLOAD

pytestmark = pytest.mark.asyncio


# ── Web3 connection ─────────────────────────────────────────────────


def test_web3_initializes():
    """Web3 instance should exist and have a provider configured."""
    assert w3 is not None
    assert w3.provider is not None


# ── Treasury pool constants ─────────────────────────────────────────


def test_treasury_pool_constants():
    assert CONSUMER_POOL == Decimal("50")
    assert AFFILIATE_POOL == Decimal("5")
    assert WHOLESALE_POOL == Decimal("5")
    assert COMPANY_RETAINED == Decimal("40")
    assert CONSUMER_POOL + AFFILIATE_POOL + WHOLESALE_POOL + COMPANY_RETAINED == Decimal("100")


# ── USDT contract address ───────────────────────────────────────────


def test_usdt_mainnet_address_is_valid():
    from app.core.config import settings

    addr = settings.USDT_CONTRACT_ADDRESS_MAINNET
    assert addr.startswith("0x")
    assert len(addr) == 42
    # Should be checksummed
    assert Web3.to_checksum_address(addr) == addr


# ── KMS key path ────────────────────────────────────────────────────


def test_kms_key_version_path():
    path = _kms_key_version_path()
    assert "blakjaks-crypto" in path
    assert "treasury-signer" in path
    assert path.endswith("/cryptoKeyVersions/1")


# ── KMS public key to Ethereum address ──────────────────────────────


def test_kms_public_key_to_eth_address():
    """Test derivation with a known uncompressed public key."""
    # Well-known test vector: random 65-byte uncompressed secp256k1 public key
    # 0x04 + 32 bytes X + 32 bytes Y
    fake_pub = b"\x04" + b"\x01" * 32 + b"\x02" * 32
    address = kms_public_key_to_eth_address(fake_pub)
    assert address.startswith("0x")
    assert len(address) == 42
    # Should be checksummed
    assert Web3.to_checksum_address(address) == address


def test_get_treasury_address_with_mock():
    """Mock KMS and verify get_treasury_address returns a valid Ethereum address."""
    # Create a fake 65-byte uncompressed public key
    fake_pub = b"\x04" + b"\xab" * 32 + b"\xcd" * 32

    with patch("app.services.blockchain.get_kms_public_key", return_value=fake_pub):
        from app.services.blockchain import get_treasury_address

        address = get_treasury_address()
        assert address.startswith("0x")
        assert len(address) == 42
        assert Web3.to_checksum_address(address) == address


# ── get_wallet_balance with mock ─────────────────────────────────────


def test_get_wallet_balance_with_mock():
    """Mock web3 and test get_wallet_balance returns a Decimal."""
    fake_address = "0x" + "a1" * 20

    with patch.object(w3.eth, "get_balance", return_value=1_000_000_000_000_000_000):
        balance = get_wallet_balance(fake_address)
        assert isinstance(balance, Decimal)
        assert balance == Decimal("1")


def test_get_usdt_balance_no_contract_on_testnet():
    """On amoy with no contract address, should return 0."""
    with patch("app.services.blockchain.settings") as mock_settings:
        mock_settings.POLYGON_NETWORK = "amoy"
        mock_settings.USDT_CONTRACT_ADDRESS_AMOY = ""
        mock_settings.USDT_CONTRACT_ADDRESS_MAINNET = "0xc2132D05D31c914a87C6611C10748AEb04B58e8F"
        balance = get_usdt_balance("0x" + "a1" * 20)
        assert balance == Decimal("0")


# ── ERC20 ABI ────────────────────────────────────────────────────────


def test_erc20_abi_has_required_functions():
    fn_names = {item["name"] for item in ERC20_ABI}
    assert "balanceOf" in fn_names
    assert "transfer" in fn_names
    assert "decimals" in fn_names


# ── Wallet service (DB) ─────────────────────────────────────────────


async def test_create_user_wallet(registered_user, db: AsyncSession):
    user_id = uuid.UUID(registered_user["user"]["id"])
    wallet = await create_user_wallet(db, user_id)
    assert wallet.address.startswith("0x")
    assert len(wallet.address) == 42
    assert wallet.balance_available == Decimal("0")
    assert wallet.balance_pending == Decimal("0")


async def test_get_user_wallet_balance_no_wallet(db: AsyncSession):
    fake_id = uuid.uuid4()
    result = await get_user_wallet_balance(db, fake_id)
    assert result["address"] is None
    assert result["balance_available"] == Decimal("0")


async def test_get_user_wallet_balance_with_wallet(registered_user, db: AsyncSession):
    user_id = uuid.UUID(registered_user["user"]["id"])
    await create_user_wallet(db, user_id)
    result = await get_user_wallet_balance(db, user_id)
    assert result["address"] is not None
    assert result["address"].startswith("0x")


async def test_record_transaction(registered_user, db: AsyncSession):
    user_id = uuid.UUID(registered_user["user"]["id"])
    txn = await record_transaction(
        db,
        user_id=user_id,
        type="comp_award",
        amount=Decimal("10.00"),
        tx_hash="0xabc123",
        status="completed",
    )
    assert txn.type == "comp_award"
    assert txn.amount == Decimal("10.00")
    assert txn.status == "completed"
    assert txn.tx_hash == "0xabc123"
