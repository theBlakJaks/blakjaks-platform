#!/usr/bin/env python3
"""
Generate a throwaway Polygon wallet for testnet treasury signing.
FOR LOCAL DEV AND TESTNET ONLY. Never use for mainnet funds.

Usage:
    pip install eth-account
    python scripts/generate_testnet_wallet.py
"""
import secrets
from eth_account import Account

print("\n⚠️  TESTNET WALLET GENERATOR — LOCAL DEV ONLY ⚠️")
print("Never send real MATIC or mainnet assets to this address.\n")

private_key = "0x" + secrets.token_hex(32)
account = Account.from_key(private_key)

print(f"Private key : {private_key}")
print(f"Address     : {account.address}")
print()
print("Add these lines to backend/.env (never commit .env to git):")
print(f"  BLOCKCHAIN_DEV_PRIVATE_KEY={private_key}")
print(f"  BLOCKCHAIN_DEV_TREASURY_ADDRESS={account.address}")
print()
print("Then fund this address:")
print("  MATIC  -> https://faucet.polygon.technology")
print("  USDC   -> https://faucet.circle.com  (select Polygon Amoy)")
print(f"  Verify -> https://amoy.polygonscan.com/address/{account.address}")
