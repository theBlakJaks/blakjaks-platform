import logging
import re
import uuid
from datetime import datetime, timedelta, timezone
from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.product import Product
from app.models.qr_code import QRCode
from app.models.scan import Scan
from app.models.user import User
from app.models.wallet import Wallet
from app.services.tier import get_all_tiers, get_quarterly_scan_count, get_user_tier_info

logger = logging.getLogger(__name__)

# Base USDC earn rate per scan (before tier multiplier)
BASE_RATE = Decimal("0.01")

QR_PATTERN = re.compile(r"^BLAKJAKS-([A-Za-z0-9_]+)-([A-Za-z0-9]+)$")
RATE_LIMIT_WINDOW = timedelta(minutes=1)
RATE_LIMIT_MAX = 10


def parse_qr_code(raw: str) -> tuple[str, str]:
    """Parse a QR code string. Returns (product_code, unique_id) or raises."""
    match = QR_PATTERN.match(raw.strip())
    if not match:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Invalid QR code format. Expected BLAKJAKS-[PRODUCT_CODE]-[UNIQUE_ID]",
        )
    return match.group(1), match.group(2)


async def check_rate_limit(db: AsyncSession, user_id: uuid.UUID) -> None:
    """Reject if user has exceeded 10 scans in the last minute."""
    cutoff = datetime.now(timezone.utc) - RATE_LIMIT_WINDOW
    result = await db.execute(
        select(func.count())
        .select_from(Scan)
        .where(Scan.user_id == user_id, Scan.created_at >= cutoff)
    )
    count = result.scalar_one()
    if count >= RATE_LIMIT_MAX:
        raise HTTPException(
            status.HTTP_429_TOO_MANY_REQUESTS,
            "Rate limit exceeded. Max 10 scans per minute.",
        )


async def submit_scan(db: AsyncSession, user: User, raw_qr: str) -> dict:
    """Validate QR, record scan, return rich result dict."""
    product_code, unique_id = parse_qr_code(raw_qr)

    # Rate limit
    await check_rate_limit(db, user.id)

    # Build the full unique_id stored in DB
    full_unique_id = f"BLAKJAKS-{product_code}-{unique_id}"

    # Look up QR code — acquire row-level lock to prevent double-scan
    result = await db.execute(
        select(QRCode).where(QRCode.unique_id == full_unique_id).with_for_update()
    )
    qr = result.scalar_one_or_none()
    if qr is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "QR code not found")

    # Already scanned?
    if qr.is_used:
        raise HTTPException(status.HTTP_409_CONFLICT, "QR code has already been scanned")

    # Get product name
    product_name = "Unknown"
    if qr.product_id:
        prod_result = await db.execute(select(Product).where(Product.id == qr.product_id))
        product = prod_result.scalar_one_or_none()
        if product:
            product_name = product.name

    # Load user with tier (for multiplier)
    user_result = await db.execute(
        select(User).options(selectinload(User.tier)).where(User.id == user.id)
    )
    user_with_tier = user_result.scalar_one_or_none() or user
    tier = getattr(user_with_tier, "tier", None)
    tier_multiplier = Decimal(str(tier.multiplier)) if tier and tier.multiplier else Decimal("1.0")
    tier_name = tier.name if tier else "Standard"

    # Calculate earnings
    usdc_earned = BASE_RATE * tier_multiplier

    # Record the scan
    scan = Scan(
        user_id=user.id,
        qr_code_id=qr.id,
        usdc_earned=usdc_earned,
        tier_multiplier=tier_multiplier,
        streak_day=0,
    )
    db.add(scan)

    # Mark QR as used
    qr.is_used = True
    qr.scanned_by = user.id
    qr.scanned_at = datetime.now(timezone.utc)

    # Credit wallet
    wallet_result = await db.execute(
        select(Wallet).where(Wallet.user_id == user.id)
    )
    wallet = wallet_result.scalar_one_or_none()
    wallet_balance = Decimal("0")
    if wallet:
        wallet.balance_available += usdc_earned
        wallet_balance = wallet.balance_available

    await db.commit()

    # Get updated tier info (post-scan quarterly count)
    tier_info = await get_user_tier_info(db, user.id)
    quarterly_scans = tier_info.get("quarterly_scans", 0)

    # Determine quarter label
    now = datetime.now(timezone.utc)
    quarter = f"Q{(now.month - 1) // 3 + 1} {now.year}"

    # Check comp milestone (fire-and-forget — never break scan on comp failure)
    comp_earned = None
    milestone_hit = False
    try:
        from app.services.comp_engine import award_crypto_comp, check_crypto_comp_milestone
        milestone = await check_crypto_comp_milestone(db, user.id)
        if milestone:
            milestone_hit = True
            txn = await award_crypto_comp(db, user.id, milestone["amount"])
            comp_earned = {
                "id": txn.id,
                "amount": float(milestone["amount"]),
                "status": "pending_choice",
                "requires_payout_choice": True,
            }
    except Exception as exc:
        logger.warning("Comp milestone check failed for user %s: %s", user.id, exc)

    # Increment Redis counters (global counter + velocity; leaderboard removed from scope)
    global_scan_count = 0
    try:
        from app.services.redis_service import (
            get_global_scan_count,
            increment_global_scan_counter,
            track_scan_velocity,
        )
        await increment_global_scan_counter()
        await track_scan_velocity()
        global_scan_count = await get_global_scan_count()
    except Exception as exc:
        logger.warning("Redis scan counter update failed: %s", exc)

    return {
        "success": True,
        "product_name": product_name,
        "usdc_earned": float(usdc_earned),
        "tier_multiplier": float(tier_multiplier),
        "tier_progress": {
            "quarter": quarter,
            "current_count": quarterly_scans,
            "next_tier": tier_info.get("next_tier"),
            "scans_required": tier_info.get("scans_to_next_tier"),
        },
        "comp_earned": comp_earned,
        "milestone_hit": milestone_hit,
        "wallet_balance": float(wallet_balance),
        "global_scan_count": global_scan_count,
    }


async def generate_qr_codes(
    db: AsyncSession, product_id: uuid.UUID, quantity: int
) -> list[str]:
    """Generate bulk QR codes for a product. Returns list of full code strings."""
    # Verify product exists
    result = await db.execute(select(Product).where(Product.id == product_id))
    product = result.scalar_one_or_none()
    if product is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Product not found")

    # Derive a short product code from the product name
    product_code = re.sub(r"[^A-Za-z0-9]", "", product.name).upper()[:10]
    if not product_code:
        product_code = "PROD"

    codes = []
    for _ in range(quantity):
        short_uuid = uuid.uuid4().hex[:12].upper()
        full_code = f"BLAKJAKS-{product_code}-{short_uuid}"
        qr = QRCode(
            product_code=product_code,
            unique_id=full_code,
            product_id=product_id,
        )
        db.add(qr)
        codes.append(full_code)

    await db.commit()
    return codes
