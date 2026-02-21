"""Stargate Finance bridge service — bridges USDC from Ethereum to Polygon.

Admin-only operation. Uses Bus mode (batched) for gas efficiency.
Transactions are signed via Cloud KMS and broadcast via the Polygon Web3 provider.

LayerZero chain IDs:
  Ethereum mainnet: 101
  Polygon mainnet:  109
  Goerli testnet:   10121
  Mumbai testnet:   10109

Stargate Router address (Polygon):
  Mainnet: 0x45A01E4e04F14f7A4a6702c74187c5F6222033cd
  Mumbai:  0x817436a076060D158204d955E5403b6Ed0A5fac0
"""

import logging
from decimal import Decimal

from web3 import Web3

from app.core.config import settings
from app.services.blockchain import get_consumer_pool_address, get_w3, sign_transaction_with_kms

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Stargate contract addresses
# ---------------------------------------------------------------------------

STARGATE_ROUTER_POLYGON_MAINNET = "0x45A01E4e04F14f7A4a6702c74187c5F6222033cd"
STARGATE_ROUTER_POLYGON_MUMBAI = "0x817436a076060D158204d955E5403b6Ed0A5fac0"

LAYERZERO_CHAIN_ID_ETHEREUM = 101
LAYERZERO_CHAIN_ID_POLYGON = 109
LAYERZERO_CHAIN_ID_GOERLI = 10121
LAYERZERO_CHAIN_ID_MUMBAI = 10109

# Stargate pool IDs for USDC
STARGATE_USDT_POOL_ID_ETHEREUM = 2
STARGATE_USDT_POOL_ID_POLYGON = 2

# LAYERZERO scan URL
LAYERZERO_SCAN_BASE = "https://layerzeroscan.com/tx"

# ---------------------------------------------------------------------------
# Minimal Stargate Router ABI (swap + quoteLayerZeroFee)
# ---------------------------------------------------------------------------

STARGATE_ROUTER_ABI = [
    {
        "name": "swap",
        "type": "function",
        "inputs": [
            {"name": "_dstChainId", "type": "uint16"},
            {"name": "_srcPoolId", "type": "uint256"},
            {"name": "_dstPoolId", "type": "uint256"},
            {"name": "_refundAddress", "type": "address"},
            {"name": "_amountLD", "type": "uint256"},
            {"name": "_minAmountLD", "type": "uint256"},
            {"name": "_lzTxParams", "type": "tuple", "components": [
                {"name": "dstGasForCall", "type": "uint256"},
                {"name": "dstNativeAmount", "type": "uint256"},
                {"name": "dstNativeAddr", "type": "bytes"},
            ]},
            {"name": "_to", "type": "bytes"},
            {"name": "_payload", "type": "bytes"},
        ],
        "outputs": [],
    },
    {
        "name": "quoteLayerZeroFee",
        "type": "function",
        "inputs": [
            {"name": "_dstChainId", "type": "uint16"},
            {"name": "_functionType", "type": "uint8"},
            {"name": "_toAddress", "type": "bytes"},
            {"name": "_transferAndCallPayload", "type": "bytes"},
            {"name": "_lzTxParams", "type": "tuple", "components": [
                {"name": "dstGasForCall", "type": "uint256"},
                {"name": "dstNativeAmount", "type": "uint256"},
                {"name": "dstNativeAddr", "type": "bytes"},
            ]},
        ],
        "outputs": [
            {"name": "nativeFee", "type": "uint256"},
            {"name": "zroFee", "type": "uint256"},
        ],
    },
]


def _get_router_address() -> str:
    """Return the appropriate Stargate router address for the current network."""
    if settings.POLYGON_NETWORK == "mainnet":
        return STARGATE_ROUTER_POLYGON_MAINNET
    return STARGATE_ROUTER_POLYGON_MUMBAI


def _get_destination_chain_id() -> int:
    """Return the LayerZero chain ID for the destination (Ethereum side)."""
    if settings.POLYGON_NETWORK == "mainnet":
        return LAYERZERO_CHAIN_ID_ETHEREUM
    return LAYERZERO_CHAIN_ID_GOERLI


def get_bridge_quote(amount_usdc: Decimal) -> dict:
    """Get a fee estimate for bridging USDC from Ethereum to Polygon.

    Uses Stargate's quoteLayerZeroFee() to estimate native gas fees.

    Args:
        amount_usdc: Amount of USDC to bridge (human-readable).

    Returns:
        dict with keys: native_fee_wei, native_fee_eth, amount_usdc
    """
    w3 = get_w3()
    router_addr = Web3.to_checksum_address(_get_router_address())
    router = w3.eth.contract(address=router_addr, abi=STARGATE_ROUTER_ABI)

    destination_pool_address = get_consumer_pool_address()
    to_address_bytes = bytes.fromhex(destination_pool_address[2:])

    lz_tx_params = {
        "dstGasForCall": 0,
        "dstNativeAmount": 0,
        "dstNativeAddr": b"\x00",
    }

    try:
        native_fee, _ = router.functions.quoteLayerZeroFee(
            _get_destination_chain_id(),
            1,  # function type 1 = swap
            to_address_bytes,
            b"",  # empty payload
            lz_tx_params,
        ).call()

        return {
            "native_fee_wei": native_fee,
            "native_fee_eth": float(Web3.from_wei(native_fee, "ether")),
            "amount_usdc": float(amount_usdc),
        }
    except Exception as exc:
        logger.error("Stargate fee quote failed: %s", exc)
        raise RuntimeError(f"Could not get Stargate bridge quote: {exc}") from exc


def execute_bridge(amount_usdc: Decimal, destination_address: str) -> dict:
    """Bridge USDC from Ethereum treasury to Polygon.

    Builds the Stargate swap() transaction, signs via Cloud KMS, broadcasts.

    Args:
        amount_usdc: USDC amount to bridge.
        destination_address: Polygon recipient address.

    Returns:
        dict with: tx_hash, layerzero_scan_url, amount_usdc
    """
    w3 = get_w3()
    router_addr = Web3.to_checksum_address(_get_router_address())
    router = w3.eth.contract(address=router_addr, abi=STARGATE_ROUTER_ABI)

    amount_ld = int(amount_usdc * Decimal("1000000"))  # USDC 6 decimals
    min_amount_ld = int(amount_ld * Decimal("0.995"))  # 0.5% slippage tolerance

    destination_pool_address = get_consumer_pool_address()
    checksum_dest = Web3.to_checksum_address(destination_address)
    to_address_bytes = bytes.fromhex(checksum_dest[2:])

    lz_tx_params = {
        "dstGasForCall": 0,
        "dstNativeAmount": 0,
        "dstNativeAddr": b"\x00",
    }

    # Quote fee to include as msg.value
    native_fee, _ = router.functions.quoteLayerZeroFee(
        _get_destination_chain_id(),
        1,
        to_address_bytes,
        b"",
        lz_tx_params,
    ).call()

    from_address = destination_pool_address
    nonce = w3.eth.get_transaction_count(Web3.to_checksum_address(from_address))

    tx = router.functions.swap(
        _get_destination_chain_id(),
        STARGATE_USDT_POOL_ID_ETHEREUM,
        STARGATE_USDT_POOL_ID_POLYGON,
        from_address,
        amount_ld,
        min_amount_ld,
        lz_tx_params,
        to_address_bytes,
        b"",
    ).build_transaction({
        "from": from_address,
        "value": native_fee,
        "nonce": nonce,
        "gas": 500_000,
        "gasPrice": w3.eth.gas_price,
        "chainId": w3.eth.chain_id,
    })

    signed_raw = sign_transaction_with_kms(tx, settings.KMS_CONSUMER_KEY)
    tx_hash = w3.eth.send_raw_transaction(signed_raw)
    tx_hash_hex = tx_hash.hex()

    logger.info(
        "Stargate bridge initiated: amount=%s dest=%s tx=%s",
        amount_usdc, destination_address, tx_hash_hex,
    )

    return {
        "tx_hash": tx_hash_hex,
        "layerzero_scan_url": f"{LAYERZERO_SCAN_BASE}/{tx_hash_hex}",
        "amount_usdc": float(amount_usdc),
    }


def get_bridge_status(tx_hash: str) -> dict:
    """Poll LayerZero for the status of a bridge transaction.

    Args:
        tx_hash: The transaction hash returned by execute_bridge().

    Returns:
        dict with: tx_hash, scan_url, status (pending/delivered/failed)
    """
    import httpx

    scan_url = f"{LAYERZERO_SCAN_BASE}/{tx_hash}"
    api_url = f"https://api-mainnet.layerzero-scan.com/tx/{tx_hash}"

    try:
        with httpx.Client(timeout=10) as client:
            response = client.get(api_url)
            if response.status_code == 200:
                data = response.json()
                messages = data.get("messages", [])
                status = messages[0].get("status", "pending") if messages else "pending"
                return {"tx_hash": tx_hash, "scan_url": scan_url, "status": status}
    except Exception as exc:
        logger.warning("LayerZero status check failed for %s: %s", tx_hash, exc)

    return {"tx_hash": tx_hash, "scan_url": scan_url, "status": "unknown"}
