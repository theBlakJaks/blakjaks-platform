"""Polygon blockchain service using Cloud KMS for treasury signing.

The Polygon RPC provider is Infura (configured via BLOCKCHAIN_POLYGON_NODE_URL).
The WebSocket provider is configured via BLOCKCHAIN_POLYGON_NODE_WS_URL.
Both work identically whether the backend URL points to Infura or a self-hosted node.

Treasury wallet addresses are loaded from settings, which are populated at runtime
from Secret Manager (GKE) or environment variables (local dev).
"""

import logging
from decimal import Decimal

from eth_account._utils.signing import to_standard_v  # noqa: F401 (kept for signing utility)
from web3 import Web3

from app.core.config import settings
from app.services import kms_service

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Treasury pool allocation constants (percentages of gross profit)
# ---------------------------------------------------------------------------

CONSUMER_POOL = Decimal("50")   # 50% of GP to consumer comp pool
AFFILIATE_POOL = Decimal("5")   # 5% of GP to affiliate pool
WHOLESALE_POOL = Decimal("5")   # 5% of GP to wholesale pool
COMPANY_RETAINED = Decimal("40")  # 40% of GP retained for OpEx + profit

# ---------------------------------------------------------------------------
# Pool name to KMS key mapping
# ---------------------------------------------------------------------------

POOL_KEY_MAP = {
    "consumer": "KMS_CONSUMER_KEY",
    "affiliate": "KMS_AFFILIATE_KEY",
    "wholesale": "KMS_WHOLESALE_KEY",
}

# ---------------------------------------------------------------------------
# Web3 providers — initialised lazily to avoid import-time connection errors
# ---------------------------------------------------------------------------

_w3_http: Web3 | None = None
_w3_ws: Web3 | None = None


def get_w3() -> Web3:
    """Return the HTTP Web3 provider, initialised from settings.BLOCKCHAIN_POLYGON_NODE_URL."""
    global _w3_http
    if _w3_http is None:
        if not settings.BLOCKCHAIN_POLYGON_NODE_URL or "YOUR_INFURA_KEY" in settings.BLOCKCHAIN_POLYGON_NODE_URL:
            logger.warning(
                "BLOCKCHAIN_POLYGON_NODE_URL is not configured. "
                "Create an Infura project at infura.io, enable Polygon, and set the endpoint."
            )
        _w3_http = Web3(Web3.HTTPProvider(settings.BLOCKCHAIN_POLYGON_NODE_URL))
    return _w3_http


def get_w3_ws() -> Web3:
    """Return the WebSocket Web3 provider, initialised from settings.BLOCKCHAIN_POLYGON_NODE_WS_URL."""
    global _w3_ws
    if _w3_ws is None:
        if not settings.BLOCKCHAIN_POLYGON_NODE_WS_URL or "YOUR_INFURA_KEY" in settings.BLOCKCHAIN_POLYGON_NODE_WS_URL:
            logger.warning(
                "BLOCKCHAIN_POLYGON_NODE_WS_URL is not configured. "
                "Set the Infura WebSocket endpoint to enable real-time event subscriptions."
            )
        _w3_ws = Web3(Web3.WebsocketProvider(settings.BLOCKCHAIN_POLYGON_NODE_WS_URL))
    return _w3_ws


# ---------------------------------------------------------------------------
# ERC-20 minimal ABI (balanceOf + transfer + decimals)
# ---------------------------------------------------------------------------

ERC20_ABI = [
    {
        "constant": True,
        "inputs": [{"name": "_owner", "type": "address"}],
        "name": "balanceOf",
        "outputs": [{"name": "balance", "type": "uint256"}],
        "type": "function",
    },
    {
        "constant": False,
        "inputs": [
            {"name": "_to", "type": "address"},
            {"name": "_value", "type": "uint256"},
        ],
        "name": "transfer",
        "outputs": [{"name": "", "type": "bool"}],
        "type": "function",
    },
    {
        "constant": True,
        "inputs": [],
        "name": "decimals",
        "outputs": [{"name": "", "type": "uint8"}],
        "type": "function",
    },
]

# ---------------------------------------------------------------------------
# Node health
# ---------------------------------------------------------------------------


def get_node_health() -> dict:
    """Return the connection status and current state of the Polygon node.

    Works identically whether the provider is Infura or self-hosted.

    Returns:
        dict with keys:
            - connected (bool): True if node responds to eth_blockNumber
            - block_number (int | None): Latest block number
            - syncing (bool | dict): False if fully synced, dict if syncing
            - provider_url (str): Sanitised provider URL (key redacted)
    """
    w3 = get_w3()
    # Redact Infura project key from URL for safe logging/display
    raw_url = settings.BLOCKCHAIN_POLYGON_NODE_URL
    safe_url = raw_url.split("/v3/")[0] + "/v3/[REDACTED]" if "/v3/" in raw_url else raw_url

    try:
        block_number = w3.eth.block_number
        syncing = w3.eth.syncing
        return {
            "connected": True,
            "block_number": block_number,
            "syncing": syncing,
            "provider_url": safe_url,
        }
    except Exception as exc:
        logger.warning("Polygon node health check failed: %s", exc)
        return {
            "connected": False,
            "block_number": None,
            "syncing": None,
            "provider_url": safe_url,
        }


# ---------------------------------------------------------------------------
# KMS key path
# ---------------------------------------------------------------------------


def _kms_key_version_path(key_name: str | None = None) -> str:
    """Build the full KMS key version resource path."""
    name = key_name or settings.KMS_KEY_NAME
    return (
        f"projects/{settings.KMS_PROJECT_ID}"
        f"/locations/{settings.KMS_LOCATION}"
        f"/keyRings/{settings.KMS_KEYRING}"
        f"/cryptoKeys/{name}"
        f"/cryptoKeyVersions/{settings.KMS_KEY_VERSION}"
    )


# ---------------------------------------------------------------------------
# KMS public key retrieval
# ---------------------------------------------------------------------------


def get_kms_public_key(key_name: str | None = None) -> bytes:
    """Retrieve the uncompressed public key from Cloud KMS."""
    return kms_service.get_public_key(key_name=key_name)


def kms_public_key_to_eth_address(pub_key_bytes: bytes) -> str:
    """Derive an Ethereum/Polygon address from an uncompressed secp256k1 public key."""
    raw_pub = pub_key_bytes[1:] if len(pub_key_bytes) == 65 else pub_key_bytes
    address_bytes = Web3.keccak(raw_pub)[-20:]
    return Web3.to_checksum_address(address_bytes)


def get_treasury_address(key_name: str | None = None) -> str:
    """Get the Polygon wallet address derived from a KMS key."""
    pub_key = get_kms_public_key(key_name)
    return kms_public_key_to_eth_address(pub_key)


# ---------------------------------------------------------------------------
# Treasury addresses — loaded from config (Secret Manager in GKE)
# ---------------------------------------------------------------------------


def get_consumer_pool_address() -> str:
    """Return the consumer pool wallet address from config, falling back to KMS derivation."""
    if settings.BLOCKCHAIN_MEMBER_TREASURY_ADDRESS:
        return Web3.to_checksum_address(settings.BLOCKCHAIN_MEMBER_TREASURY_ADDRESS)
    return get_treasury_address(settings.KMS_CONSUMER_KEY)


def get_affiliate_pool_address() -> str:
    """Return the affiliate pool wallet address from config, falling back to KMS derivation."""
    if settings.BLOCKCHAIN_AFFILIATE_TREASURY_ADDRESS:
        return Web3.to_checksum_address(settings.BLOCKCHAIN_AFFILIATE_TREASURY_ADDRESS)
    return get_treasury_address(settings.KMS_AFFILIATE_KEY)


def get_wholesale_pool_address() -> str:
    """Return the wholesale pool wallet address from config, falling back to KMS derivation."""
    if settings.BLOCKCHAIN_WHOLESALE_TREASURY_ADDRESS:
        return Web3.to_checksum_address(settings.BLOCKCHAIN_WHOLESALE_TREASURY_ADDRESS)
    return get_treasury_address(settings.KMS_WHOLESALE_KEY)


def get_all_pool_addresses() -> dict[str, str]:
    """Return dict of all three pool wallet addresses."""
    return {
        "consumer": get_consumer_pool_address(),
        "affiliate": get_affiliate_pool_address(),
        "wholesale": get_wholesale_pool_address(),
    }


# ---------------------------------------------------------------------------
# Balance queries
# ---------------------------------------------------------------------------


def get_wallet_balance(address: str) -> Decimal:
    """Get native MATIC/POL balance for an address (in Ether units)."""
    w3 = get_w3()
    checksum = Web3.to_checksum_address(address)
    balance_wei = w3.eth.get_balance(checksum)
    return Decimal(str(Web3.from_wei(balance_wei, "ether")))


def get_usdt_balance(address: str) -> Decimal:
    """Get USDT (ERC-20) token balance for an address."""
    w3 = get_w3()
    contract_addr = (
        settings.USDT_CONTRACT_ADDRESS_MAINNET
        if settings.POLYGON_NETWORK == "mainnet"
        else settings.USDT_CONTRACT_ADDRESS_AMOY
    )
    if not contract_addr:
        logger.warning("No USDT contract address configured for network %s", settings.POLYGON_NETWORK)
        return Decimal("0")

    checksum = Web3.to_checksum_address(contract_addr)
    contract = w3.eth.contract(address=checksum, abi=ERC20_ABI)
    raw_balance = contract.functions.balanceOf(Web3.to_checksum_address(address)).call()
    return Decimal(raw_balance) / Decimal(10**6)


# ---------------------------------------------------------------------------
# KMS transaction signing
# ---------------------------------------------------------------------------


def sign_transaction_with_kms(tx: dict, key_name: str | None = None) -> bytes:
    """Sign a raw transaction dict using a Cloud KMS secp256k1 key.

    Returns the signed raw transaction bytes ready for broadcast.
    """
    from eth_account import Account
    from eth_account._utils.legacy_transactions import (
        serializable_unsigned_transaction_from_dict,
    )

    unsigned_tx = serializable_unsigned_transaction_from_dict(tx)
    tx_hash = unsigned_tx.hash()

    der_signature = kms_service.sign_transaction(tx_hash_bytes=tx_hash, key_name=key_name)

    from cryptography.hazmat.primitives.asymmetric.utils import decode_dss_signature

    r, s = decode_dss_signature(der_signature)

    SECP256K1_N = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
    if s > SECP256K1_N // 2:
        s = SECP256K1_N - s

    signer_addr = get_treasury_address(key_name)
    for v_candidate in (0, 1):
        try:
            recovered = Account._recover_hash(tx_hash, vrs=(v_candidate + 27, r, s))
            if recovered.lower() == signer_addr.lower():
                v = v_candidate + 27
                break
        except Exception:
            continue
    else:
        raise RuntimeError("Failed to recover correct v value from KMS signature")

    if "chainId" in tx:
        v = v + tx["chainId"] * 2 + 8

    from rlp import encode as rlp_encode

    signed_tx_bytes = rlp_encode(unsigned_tx.as_signed_transaction((v, r, s)))
    return signed_tx_bytes


def send_usdt_transfer(to_address: str, amount: Decimal) -> str:
    """Build, sign via KMS, and broadcast a USDT transfer from the consumer treasury."""
    return send_usdt_from_pool("consumer", to_address, amount)


def send_usdt_from_pool(pool_name: str, to_address: str, amount: Decimal) -> str:
    """Build, sign via KMS, and broadcast a USDT transfer from a specific pool.

    Args:
        pool_name: One of "consumer", "affiliate", "wholesale".
        to_address: Recipient Polygon address.
        amount: USDT amount (human-readable, e.g. Decimal("10.50")).

    Returns:
        Transaction hash hex string.
    """
    if pool_name not in POOL_KEY_MAP:
        raise ValueError(f"Unknown pool: {pool_name}. Must be one of {list(POOL_KEY_MAP.keys())}")

    w3 = get_w3()
    key_attr = POOL_KEY_MAP[pool_name]
    key_name = getattr(settings, key_attr)

    contract_addr = (
        settings.USDT_CONTRACT_ADDRESS_MAINNET
        if settings.POLYGON_NETWORK == "mainnet"
        else settings.USDT_CONTRACT_ADDRESS_AMOY
    )
    if not contract_addr:
        raise RuntimeError(f"No USDT contract address for network {settings.POLYGON_NETWORK}")

    pool_address = get_treasury_address(key_name)
    checksum_contract = Web3.to_checksum_address(contract_addr)
    checksum_to = Web3.to_checksum_address(to_address)

    contract = w3.eth.contract(address=checksum_contract, abi=ERC20_ABI)
    raw_amount = int(amount * Decimal(10**6))

    nonce = w3.eth.get_transaction_count(Web3.to_checksum_address(pool_address))
    tx = contract.functions.transfer(checksum_to, raw_amount).build_transaction(
        {
            "from": pool_address,
            "nonce": nonce,
            "gas": 100_000,
            "gasPrice": w3.eth.gas_price,
            "chainId": w3.eth.chain_id,
        }
    )

    signed_raw = sign_transaction_with_kms(tx, key_name)
    tx_hash = w3.eth.send_raw_transaction(signed_raw)

    logger.info(
        "USDT transfer from %s pool: %s -> %s, amount=%s, tx=%s",
        pool_name, pool_address, to_address, amount, tx_hash.hex(),
    )
    return tx_hash.hex()
