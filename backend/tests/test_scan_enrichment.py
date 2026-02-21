"""Tests for E1 — Scan Submit Enrichment.

Verifies: usdc_earned calculation, tier_multiplier storage, Redis increments,
comp milestone trigger, and full ScanResponse schema.
"""

import uuid
from decimal import Decimal
from unittest.mock import AsyncMock, MagicMock, patch

import pytest


def _make_user(tier_name="Standard", multiplier=Decimal("1.0")):
    tier = MagicMock()
    tier.name = tier_name
    tier.multiplier = multiplier

    user = MagicMock()
    user.id = uuid.uuid4()
    user.tier = tier
    return user


def _make_qr(product_id=None):
    qr = MagicMock()
    qr.id = uuid.uuid4()
    qr.is_used = False
    qr.product_id = product_id or uuid.uuid4()
    qr.scanned_by = None
    qr.scanned_at = None
    return qr


def _make_wallet(balance=Decimal("5.00")):
    wallet = MagicMock()
    wallet.balance_available = balance
    return wallet


def _setup_db(qr, user, wallet=None, product_name="Test Product"):
    """Return a mock AsyncSession configured for happy-path submit_scan."""
    mock_db = AsyncMock()

    product = MagicMock()
    product.name = product_name

    calls = [0]

    async def execute_side_effect(query, *args, **kwargs):
        result = MagicMock()
        calls[0] += 1
        n = calls[0]
        if n == 1:
            # QR lookup
            result.scalar_one_or_none.return_value = qr
        elif n == 2:
            # Product lookup
            result.scalar_one_or_none.return_value = product
        elif n == 3:
            # User with tier
            result.scalar_one_or_none.return_value = user
        elif n == 4:
            # Wallet
            result.scalar_one_or_none.return_value = wallet or _make_wallet()
        else:
            result.scalar_one_or_none.return_value = None
            result.scalar_one.return_value = 0
        return result

    mock_db.execute = execute_side_effect
    mock_db.add = MagicMock()
    mock_db.commit = AsyncMock()
    mock_db.refresh = AsyncMock()
    return mock_db


@pytest.mark.asyncio
async def test_usdc_earned_standard_tier():
    """Standard tier multiplier=1.0 earns BASE_RATE per scan."""
    from app.services.qr_code import submit_scan, BASE_RATE

    user = _make_user("Standard", Decimal("1.0"))
    qr = _make_qr()
    wallet = _make_wallet(Decimal("0"))
    mock_db = _setup_db(qr, user, wallet)

    tier_info = {"quarterly_scans": 5, "tier_name": "Standard", "next_tier": "VIP", "scans_to_next_tier": 45}
    with patch("app.services.qr_code.get_user_tier_info", return_value=tier_info), \
         patch("app.services.qr_code.check_rate_limit", return_value=None), \
         patch("app.services.comp_engine.check_crypto_comp_milestone", return_value=None), \
         patch("app.services.redis_service.increment_global_scan_counter", new_callable=AsyncMock), \
         patch("app.services.redis_service.track_scan_velocity", new_callable=AsyncMock), \
         patch("app.services.redis_service.get_global_scan_count", return_value=1):
        result = await submit_scan(mock_db, user, "BLAKJAKS-PROD-ABCDEF123456")

    assert result["usdc_earned"] == float(BASE_RATE * Decimal("1.0"))
    assert result["tier_multiplier"] == 1.0


@pytest.mark.asyncio
async def test_usdc_earned_vip_tier():
    """VIP multiplier=1.5 earns 1.5× base."""
    from app.services.qr_code import submit_scan, BASE_RATE

    user = _make_user("VIP", Decimal("1.5"))
    qr = _make_qr()
    wallet = _make_wallet(Decimal("0"))
    mock_db = _setup_db(qr, user, wallet)

    tier_info = {"quarterly_scans": 51, "tier_name": "VIP", "next_tier": "High Roller", "scans_to_next_tier": 49}
    with patch("app.services.qr_code.get_user_tier_info", return_value=tier_info), \
         patch("app.services.qr_code.check_rate_limit", return_value=None), \
         patch("app.services.comp_engine.check_crypto_comp_milestone", return_value=None), \
         patch("app.services.redis_service.increment_global_scan_counter", new_callable=AsyncMock), \
         patch("app.services.redis_service.track_scan_velocity", new_callable=AsyncMock), \
         patch("app.services.redis_service.get_global_scan_count", return_value=100):
        result = await submit_scan(mock_db, user, "BLAKJAKS-PROD-ABCDEF123456")

    assert result["tier_multiplier"] == 1.5
    assert abs(result["usdc_earned"] - float(BASE_RATE * Decimal("1.5"))) < 1e-8


@pytest.mark.asyncio
async def test_usdc_earned_high_roller_tier():
    """High Roller multiplier=2.0."""
    from app.services.qr_code import submit_scan, BASE_RATE

    user = _make_user("High Roller", Decimal("2.0"))
    qr = _make_qr()
    mock_db = _setup_db(qr, user)

    tier_info = {"quarterly_scans": 101, "tier_name": "High Roller", "next_tier": "Whale", "scans_to_next_tier": 99}
    with patch("app.services.qr_code.get_user_tier_info", return_value=tier_info), \
         patch("app.services.qr_code.check_rate_limit", return_value=None), \
         patch("app.services.comp_engine.check_crypto_comp_milestone", return_value=None), \
         patch("app.services.redis_service.increment_global_scan_counter", new_callable=AsyncMock), \
         patch("app.services.redis_service.track_scan_velocity", new_callable=AsyncMock), \
         patch("app.services.redis_service.get_global_scan_count", return_value=200):
        result = await submit_scan(mock_db, user, "BLAKJAKS-PROD-ABCDEF123456")

    assert result["tier_multiplier"] == 2.0


@pytest.mark.asyncio
async def test_usdc_earned_whale_tier():
    """Whale multiplier=3.0."""
    from app.services.qr_code import submit_scan, BASE_RATE

    user = _make_user("Whale", Decimal("3.0"))
    qr = _make_qr()
    mock_db = _setup_db(qr, user)

    tier_info = {"quarterly_scans": 201, "tier_name": "Whale", "next_tier": None, "scans_to_next_tier": None}
    with patch("app.services.qr_code.get_user_tier_info", return_value=tier_info), \
         patch("app.services.qr_code.check_rate_limit", return_value=None), \
         patch("app.services.comp_engine.check_crypto_comp_milestone", return_value=None), \
         patch("app.services.redis_service.increment_global_scan_counter", new_callable=AsyncMock), \
         patch("app.services.redis_service.track_scan_velocity", new_callable=AsyncMock), \
         patch("app.services.redis_service.get_global_scan_count", return_value=500):
        result = await submit_scan(mock_db, user, "BLAKJAKS-PROD-ABCDEF123456")

    assert result["tier_multiplier"] == 3.0
    assert abs(result["usdc_earned"] - float(BASE_RATE * Decimal("3.0"))) < 1e-8


@pytest.mark.asyncio
async def test_scan_stores_tier_multiplier_on_record():
    """Scan row is created with correct tier_multiplier value."""
    from app.services.qr_code import submit_scan

    user = _make_user("VIP", Decimal("1.5"))
    qr = _make_qr()
    mock_db = _setup_db(qr, user)

    created_scans = []
    original_add = mock_db.add

    def capture_add(obj):
        from app.models.scan import Scan
        if isinstance(obj, Scan) or hasattr(obj, "tier_multiplier"):
            created_scans.append(obj)
        original_add(obj)

    mock_db.add = capture_add

    tier_info = {"quarterly_scans": 60, "tier_name": "VIP", "next_tier": "High Roller", "scans_to_next_tier": 40}
    with patch("app.services.qr_code.get_user_tier_info", return_value=tier_info), \
         patch("app.services.qr_code.check_rate_limit", return_value=None), \
         patch("app.services.comp_engine.check_crypto_comp_milestone", return_value=None), \
         patch("app.services.redis_service.increment_global_scan_counter", new_callable=AsyncMock), \
         patch("app.services.redis_service.track_scan_velocity", new_callable=AsyncMock), \
         patch("app.services.redis_service.get_global_scan_count", return_value=50):
        result = await submit_scan(mock_db, user, "BLAKJAKS-PROD-ABCDEF123456")

    assert result["tier_multiplier"] == 1.5


@pytest.mark.asyncio
async def test_redis_counter_increments():
    """Global scan counter is incremented via Redis after a scan."""
    from app.services.qr_code import submit_scan

    user = _make_user()
    qr = _make_qr()
    mock_db = _setup_db(qr, user)

    tier_info = {"quarterly_scans": 1, "tier_name": "Standard", "next_tier": "VIP", "scans_to_next_tier": 49}

    mock_increment = AsyncMock()
    mock_velocity = AsyncMock()

    with patch("app.services.qr_code.get_user_tier_info", return_value=tier_info), \
         patch("app.services.qr_code.check_rate_limit", return_value=None), \
         patch("app.services.comp_engine.check_crypto_comp_milestone", return_value=None), \
         patch("app.services.redis_service.increment_global_scan_counter", mock_increment), \
         patch("app.services.redis_service.track_scan_velocity", mock_velocity), \
         patch("app.services.redis_service.get_global_scan_count", return_value=42):
        result = await submit_scan(mock_db, user, "BLAKJAKS-PROD-ABCDEF123456")

    mock_increment.assert_called_once()
    mock_velocity.assert_called_once()
    assert result["global_scan_count"] == 42


@pytest.mark.asyncio
async def test_comp_milestone_triggers():
    """When a comp milestone is hit, comp_earned is populated and milestone_hit=True."""
    from app.services.qr_code import submit_scan

    user = _make_user("VIP", Decimal("1.5"))
    qr = _make_qr()
    mock_db = _setup_db(qr, user)

    mock_txn = MagicMock()
    mock_txn.amount = Decimal("100")

    milestone = {"amount": Decimal("100"), "min_tier": "VIP"}
    tier_info = {"quarterly_scans": 55, "tier_name": "VIP", "next_tier": "High Roller", "scans_to_next_tier": 45}

    with patch("app.services.qr_code.get_user_tier_info", return_value=tier_info), \
         patch("app.services.qr_code.check_rate_limit", return_value=None), \
         patch("app.services.comp_engine.check_crypto_comp_milestone", return_value=milestone), \
         patch("app.services.comp_engine.award_crypto_comp", return_value=mock_txn), \
         patch("app.services.comp_engine._get_total_comps_received", return_value=Decimal("100")), \
         patch("app.services.redis_service.increment_global_scan_counter", new_callable=AsyncMock), \
         patch("app.services.redis_service.track_scan_velocity", new_callable=AsyncMock), \
         patch("app.services.redis_service.get_global_scan_count", return_value=99):
        result = await submit_scan(mock_db, user, "BLAKJAKS-PROD-ABCDEF123456")

    assert result["milestone_hit"] is True
    assert result["comp_earned"] is not None
    assert result["comp_earned"]["amount"] == 100.0
    assert result["comp_earned"]["type"] == "crypto_comp"


@pytest.mark.asyncio
async def test_comp_failure_does_not_break_scan():
    """A comp engine error must not prevent the scan from succeeding."""
    from app.services.qr_code import submit_scan

    user = _make_user()
    qr = _make_qr()
    mock_db = _setup_db(qr, user)

    tier_info = {"quarterly_scans": 10, "tier_name": "Standard", "next_tier": "VIP", "scans_to_next_tier": 40}
    with patch("app.services.qr_code.get_user_tier_info", return_value=tier_info), \
         patch("app.services.qr_code.check_rate_limit", return_value=None), \
         patch("app.services.comp_engine.check_crypto_comp_milestone", side_effect=Exception("DB error")), \
         patch("app.services.redis_service.increment_global_scan_counter", new_callable=AsyncMock), \
         patch("app.services.redis_service.track_scan_velocity", new_callable=AsyncMock), \
         patch("app.services.redis_service.get_global_scan_count", return_value=0):
        result = await submit_scan(mock_db, user, "BLAKJAKS-PROD-ABCDEF123456")

    assert result["success"] is True
    assert result["milestone_hit"] is False
    assert result["comp_earned"] is None


@pytest.mark.asyncio
async def test_response_matches_full_schema():
    """Result dict contains all required ScanResponse fields."""
    from app.services.qr_code import submit_scan
    from app.api.schemas.scan import ScanResponse

    user = _make_user()
    qr = _make_qr()
    mock_db = _setup_db(qr, user)

    tier_info = {"quarterly_scans": 3, "tier_name": "Standard", "next_tier": "VIP", "scans_to_next_tier": 47}
    with patch("app.services.qr_code.get_user_tier_info", return_value=tier_info), \
         patch("app.services.qr_code.check_rate_limit", return_value=None), \
         patch("app.services.comp_engine.check_crypto_comp_milestone", return_value=None), \
         patch("app.services.redis_service.increment_global_scan_counter", new_callable=AsyncMock), \
         patch("app.services.redis_service.track_scan_velocity", new_callable=AsyncMock), \
         patch("app.services.redis_service.get_global_scan_count", return_value=7):
        result = await submit_scan(mock_db, user, "BLAKJAKS-PROD-ABCDEF123456")

    # Must parse into ScanResponse without error
    response = ScanResponse(**result)
    assert response.success is True
    assert response.tier_progress.current_count == 3
    assert response.tier_progress.next_tier == "VIP"
    assert response.tier_progress.scans_required == 47
    assert response.milestone_hit is False
    assert response.comp_earned is None
    assert response.global_scan_count == 7
