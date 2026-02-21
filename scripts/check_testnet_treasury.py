#!/usr/bin/env python3
"""
Check testnet treasury MATIC and USDC balances. Prints faucet links if low.

Usage:
    python scripts/check_testnet_treasury.py
"""
import os, sys
from decimal import Decimal
from dotenv import load_dotenv
from web3 import Web3

load_dotenv(dotenv_path="backend/.env")

AMOY_RPC      = os.getenv("BLOCKCHAIN_POLYGON_NODE_URL", "https://rpc-amoy.polygon.technology")
TREASURY_ADDR = os.getenv("BLOCKCHAIN_DEV_TREASURY_ADDRESS", "")
USDC_CONTRACT = "0x41E94Eb019C0762f9Bfcf9Fb1E58725BfB0e7582"

ERC20_ABI = [
    {"constant": True, "inputs": [{"name": "_owner", "type": "address"}],
     "name": "balanceOf", "outputs": [{"name": "balance", "type": "uint256"}], "type": "function"},
]

def main():
    if not TREASURY_ADDR:
        print("ERROR: BLOCKCHAIN_DEV_TREASURY_ADDRESS not set in backend/.env")
        print("Run: python scripts/generate_testnet_wallet.py")
        sys.exit(1)

    w3 = Web3(Web3.HTTPProvider(AMOY_RPC))
    if not w3.is_connected():
        print(f"ERROR: Cannot connect to {AMOY_RPC}")
        sys.exit(1)

    addr = Web3.to_checksum_address(TREASURY_ADDR)
    print(f"\n=== BlakJaks Dev Treasury -- Polygon Amoy ===")
    print(f"Address  : {addr}")
    print(f"Explorer : https://amoy.polygonscan.com/address/{addr}\n")

    matic = Decimal(str(Web3.from_wei(w3.eth.get_balance(addr), "ether")))
    matic_ok = matic >= Decimal("0.1")
    print(f"MATIC : {matic:.4f} POL  {'OK' if matic_ok else 'LOW'}")
    if not matic_ok:
        print("        -> https://faucet.polygon.technology")
        print("        -> https://faucets.chain.link/polygon-amoy")

    contract = w3.eth.contract(address=Web3.to_checksum_address(USDC_CONTRACT), abi=ERC20_ABI)
    usdc = Decimal(contract.functions.balanceOf(addr).call()) / Decimal(10**6)
    usdc_ok = usdc >= Decimal("10")
    print(f"USDC  : {usdc:.2f}       {'OK' if usdc_ok else 'LOW'}")
    if not usdc_ok:
        print("        -> https://faucet.circle.com  (select Polygon Amoy)")

    print()
    if matic_ok and usdc_ok:
        print("Treasury ready -- start the backend and test comp payouts.")
    else:
        print("Fund the wallet above, then re-run this script to verify.")

if __name__ == "__main__":
    main()
