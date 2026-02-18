"""Polygon blockchain service using Cloud KMS for treasury signing."""

import hashlib
import logging
from decimal import Decimal

from eth_account._utils.signing import to_standard_v
from google.cloud import kms
from web3 import Web3

from app.core.config import settings

logger = logging.getLogger(__name__)

# --- Treasury pool allocation constants (percentages of gross profit) ---
CONSUMER_POOL = Decimal("50")   # 50% of GP to consumer comp pool
AFFILIATE_POOL = Decimal("5")   # 5% of GP to affiliate pool (note: 21% is the reward MATCHING rate, not pool allocation)
WHOLESALE_POOL = Decimal("5")   # 5% of GP to wholesale pool
COMPANY_RETAINED = Decimal("40")  # 40% of GP retained for OpEx + profit (not a treasury pool)

# --- Web3 connection ---

w3 = Web3(Web3.HTTPProvider(settings.POLYGON_RPC_URL))

# --- ERC-20 minimal ABI (balanceOf + transfer + decimals) ---

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

# --- KMS key path ---


def _kms_key_version_path() -> str:
    return (
        f"projects/{settings.KMS_PROJECT_ID}"
        f"/locations/{settings.KMS_LOCATION}"
        f"/keyRings/{settings.KMS_KEYRING}"
        f"/cryptoKeys/{settings.KMS_KEY_NAME}"
        f"/cryptoKeyVersions/{settings.KMS_KEY_VERSION}"
    )


# --- KMS public key retrieval ---


def get_kms_public_key() -> bytes:
    """Retrieve the DER-encoded public key from Cloud KMS."""
    client = kms.KeyManagementServiceClient()
    response = client.get_public_key(request={"name": _kms_key_version_path()})
    # response.pem contains the PEM-encoded public key
    from cryptography.hazmat.primitives.serialization import load_pem_public_key

    pub_key = load_pem_public_key(response.pem.encode())
    from cryptography.hazmat.primitives.serialization import Encoding, PublicFormat

    return pub_key.public_bytes(Encoding.X962, PublicFormat.UncompressedPoint)


def kms_public_key_to_eth_address(pub_key_bytes: bytes) -> str:
    """Derive an Ethereum/Polygon address from an uncompressed secp256k1 public key.

    The input should be 65 bytes (0x04 prefix + 32-byte X + 32-byte Y).
    Ethereum address = last 20 bytes of keccak256(X || Y).
    """
    # Strip the 0x04 uncompressed point prefix
    raw_pub = pub_key_bytes[1:] if len(pub_key_bytes) == 65 else pub_key_bytes
    address_bytes = Web3.keccak(raw_pub)[-20:]
    return Web3.to_checksum_address(address_bytes)


def get_treasury_address() -> str:
    """Get the Polygon wallet address derived from the KMS treasury key."""
    pub_key = get_kms_public_key()
    return kms_public_key_to_eth_address(pub_key)


# --- Balance queries ---


def get_wallet_balance(address: str) -> Decimal:
    """Get native MATIC/POL balance for an address (in Ether units)."""
    checksum = Web3.to_checksum_address(address)
    balance_wei = w3.eth.get_balance(checksum)
    return Decimal(str(Web3.from_wei(balance_wei, "ether")))


def get_usdt_balance(address: str) -> Decimal:
    """Get USDT (ERC-20) token balance for an address."""
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
    # USDT on Polygon has 6 decimals
    return Decimal(raw_balance) / Decimal(10**6)


# --- KMS transaction signing ---


def sign_transaction_with_kms(tx: dict) -> bytes:
    """Sign a raw transaction dict using the Cloud KMS secp256k1 key.

    Returns the signed raw transaction bytes ready for broadcast.
    """
    from eth_account import Account
    from eth_account._utils.legacy_transactions import (
        serializable_unsigned_transaction_from_dict,
    )

    unsigned_tx = serializable_unsigned_transaction_from_dict(tx)
    tx_hash = unsigned_tx.hash()

    # Sign the hash with KMS
    client = kms.KeyManagementServiceClient()
    sign_response = client.asymmetric_sign(
        request={
            "name": _kms_key_version_path(),
            "digest": {"sha256": tx_hash},
        }
    )

    # Parse DER signature into r, s components
    from cryptography.hazmat.primitives.asymmetric.utils import decode_dss_signature

    r, s = decode_dss_signature(sign_response.signature)

    # Ensure low-s (EIP-2) — secp256k1 order
    SECP256K1_N = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
    if s > SECP256K1_N // 2:
        s = SECP256K1_N - s

    # Recover the v value by trying both recovery IDs
    treasury_addr = get_treasury_address()
    for v_candidate in (0, 1):
        try:
            recovered = Account._recover_hash(tx_hash, vrs=(v_candidate + 27, r, s))
            if recovered.lower() == treasury_addr.lower():
                v = v_candidate + 27
                break
        except Exception:
            continue
    else:
        raise RuntimeError("Failed to recover correct v value from KMS signature")

    # Apply chain ID if present (EIP-155)
    if "chainId" in tx:
        v = v + tx["chainId"] * 2 + 8

    # Encode signed transaction
    from rlp import encode as rlp_encode

    signed_tx_bytes = rlp_encode(unsigned_tx.as_signed_transaction((v, r, s)))
    return signed_tx_bytes


def send_usdt_transfer(to_address: str, amount: Decimal) -> str:
    """Build, sign via KMS, and broadcast a USDT transfer.

    Args:
        to_address: Recipient Polygon address.
        amount: USDT amount (human-readable, e.g. Decimal("10.50")).

    Returns:
        Transaction hash hex string.
    """
    contract_addr = (
        settings.USDT_CONTRACT_ADDRESS_MAINNET
        if settings.POLYGON_NETWORK == "mainnet"
        else settings.USDT_CONTRACT_ADDRESS_AMOY
    )
    if not contract_addr:
        raise RuntimeError(f"No USDT contract address for network {settings.POLYGON_NETWORK}")

    treasury = get_treasury_address()
    checksum_contract = Web3.to_checksum_address(contract_addr)
    checksum_to = Web3.to_checksum_address(to_address)

    contract = w3.eth.contract(address=checksum_contract, abi=ERC20_ABI)

    # USDT has 6 decimals on Polygon
    raw_amount = int(amount * Decimal(10**6))

    # Build the transaction
    nonce = w3.eth.get_transaction_count(Web3.to_checksum_address(treasury))
    tx = contract.functions.transfer(checksum_to, raw_amount).build_transaction(
        {
            "from": treasury,
            "nonce": nonce,
            "gas": 100_000,
            "gasPrice": w3.eth.gas_price,
            "chainId": w3.eth.chain_id,
        }
    )

    # Sign and broadcast
    signed_raw = sign_transaction_with_kms(tx)
    tx_hash = w3.eth.send_raw_transaction(signed_raw)

    logger.info("USDT transfer sent: %s -> %s, amount=%s, tx=%s", treasury, to_address, amount, tx_hash.hex())
    return tx_hash.hex()
