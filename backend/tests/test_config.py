"""Tests for Task A2 — Environment Configuration.

Verifies:
- Settings() loads with all fields defaulting correctly (no missing required fields)
- New variable groups are present with correct defaults
- Settings reads correctly from environment variables
"""

import os

import pytest

from app.core.config import Settings, settings


def test_settings_loads_without_env_file():
    """Settings() must be constructible with no .env — all fields have defaults."""
    s = Settings()
    assert s is not None


def test_core_defaults():
    s = Settings()
    assert s.ACCESS_TOKEN_EXPIRE_MINUTES == 15
    assert s.REFRESH_TOKEN_EXPIRE_DAYS == 30
    assert s.ALGORITHM == "HS256"


def test_redis_defaults():
    s = Settings()
    assert s.REDIS_URL == "redis://localhost:6379/0"
    assert s.REDIS_CLUSTER_ENABLED is False
    assert s.REDIS_SSL_ENABLED is False


def test_celery_defaults():
    s = Settings()
    assert s.CELERY_BROKER_URL == "redis://localhost:6379/0"
    assert s.CELERY_RESULT_BACKEND == "redis://localhost:6379/0"


def test_gcs_defaults():
    s = Settings()
    assert s.GCS_BUCKET_AVATARS == "blakjaks-user-avatars"
    assert s.GCS_BUCKET_ASSETS == "blakjaks-assets"
    assert s.GCS_BUCKET_QR == "blakjaks-qr-codes"
    assert s.GCS_PROJECT_ID == "blakjaks-production"


def test_teller_defaults():
    s = Settings()
    assert s.TELLER_ENV == "sandbox"
    assert s.TELLER_CERT_PATH == ""
    assert s.TELLER_KEY_PATH == ""
    assert s.TELLER_ACCOUNT_IDS == ""


def test_blockchain_defaults():
    s = Settings()
    assert s.POLYGON_CHAIN_ID == 80002
    assert "polygon-node" in s.BLOCKCHAIN_POLYGON_NODE_URL
    assert "polygon-node" in s.BLOCKCHAIN_POLYGON_NODE_WS_URL
    assert s.BLOCKCHAIN_MEMBER_TREASURY_ADDRESS == ""
    assert s.BLOCKCHAIN_AFFILIATE_TREASURY_ADDRESS == ""
    assert s.BLOCKCHAIN_WHOLESALE_TREASURY_ADDRESS == ""


def test_apns_defaults():
    s = Settings()
    assert s.APNS_BUNDLE_ID == "com.blakjaks.app"
    assert s.APNS_KEY_ID == ""
    assert s.APNS_TEAM_ID == ""


def test_sentry_defaults():
    s = Settings()
    assert s.SENTRY_DSN == ""
    assert s.SENTRY_ENVIRONMENT == "development"
    assert s.SENTRY_TRACES_SAMPLE_RATE == 0.1


def test_intercom_defaults():
    s = Settings()
    assert s.INTERCOM_APP_ID == ""
    assert s.INTERCOM_API_KEY == ""
    assert s.INTERCOM_IDENTITY_VERIFICATION_SECRET == ""


def test_translation_defaults():
    s = Settings()
    assert s.TRANSLATION_ENABLED is False
    assert "en" in s.TRANSLATION_SUPPORTED_LANGUAGES
    assert s.TRANSLATION_CACHE_TTL == 86400


def test_kintsugi_defaults():
    s = Settings()
    assert s.KINTSUGI_API_URL == "https://api.kintsugi.io"
    assert s.KINTSUGI_API_KEY == ""


def test_payment_processor_defaults():
    s = Settings()
    assert s.PAYMENT_PROCESSOR == ""
    assert s.PAYMENT_SECRET_KEY == ""
    assert s.PAYMENT_PUBLISHABLE_KEY == ""
    assert s.PAYMENT_WEBHOOK_SECRET == ""


def test_settings_reads_from_env(monkeypatch):
    """Settings must read values from environment variables."""
    monkeypatch.setenv("REDIS_URL", "redis://custom-host:6380/1")
    monkeypatch.setenv("SENTRY_DSN", "https://test@sentry.io/123")
    monkeypatch.setenv("SEVEN_TV_EMOTE_SET_ID", "abc123")

    s = Settings()
    assert s.REDIS_URL == "redis://custom-host:6380/1"
    assert s.SENTRY_DSN == "https://test@sentry.io/123"
    assert s.SEVEN_TV_EMOTE_SET_ID == "abc123"


def test_all_new_variable_groups_present():
    """Smoke test — ensure all new variable group attributes exist on Settings."""
    required_attrs = [
        # Redis
        "REDIS_URL", "REDIS_CLUSTER_ENABLED", "REDIS_SSL_ENABLED",
        # Celery
        "CELERY_BROKER_URL", "CELERY_RESULT_BACKEND",
        # GCS
        "GCS_BUCKET_AVATARS", "GCS_BUCKET_ASSETS", "GCS_BUCKET_QR", "GCS_PROJECT_ID",
        # KMS
        "GCP_KMS_KEY_RING", "GCP_KMS_KEY_NAME", "GCP_KMS_LOCATION",
        # Blockchain
        "POLYGON_CHAIN_ID", "BLOCKCHAIN_POLYGON_NODE_URL", "BLOCKCHAIN_POLYGON_NODE_WS_URL",
        "BLOCKCHAIN_MEMBER_TREASURY_ADDRESS", "BLOCKCHAIN_AFFILIATE_TREASURY_ADDRESS",
        "BLOCKCHAIN_WHOLESALE_TREASURY_ADDRESS",
        # Teller
        "TELLER_CERT_PATH", "TELLER_KEY_PATH", "TELLER_ENV", "TELLER_ACCOUNT_IDS",
        # OpenAI
        "OPENAI_API_KEY",
        # 7TV / Giphy
        "SEVEN_TV_EMOTE_SET_ID", "GIPHY_API_KEY",
        # APNs
        "APNS_KEY_ID", "APNS_TEAM_ID", "APNS_BUNDLE_ID", "APNS_CERT_PATH",
        # FCM
        "FCM_SERVER_KEY",
        # Sentry
        "SENTRY_DSN", "SENTRY_ENVIRONMENT", "SENTRY_RELEASE", "SENTRY_TRACES_SAMPLE_RATE",
        # Intercom
        "INTERCOM_APP_ID", "INTERCOM_API_KEY", "INTERCOM_IDENTITY_VERIFICATION_SECRET",
        "INTERCOM_IOS_API_KEY", "INTERCOM_ANDROID_API_KEY",
        # Translation
        "TRANSLATION_GOOGLE_PROJECT_ID", "TRANSLATION_GOOGLE_CREDENTIALS_PATH",
        "TRANSLATION_ENABLED", "TRANSLATION_SUPPORTED_LANGUAGES", "TRANSLATION_CACHE_TTL",
        # GA4
        "GA4_MEASUREMENT_ID",
        # Kintsugi
        "KINTSUGI_API_KEY", "KINTSUGI_API_URL",
        # Payment
        "PAYMENT_PROCESSOR", "PAYMENT_SECRET_KEY", "PAYMENT_PUBLISHABLE_KEY",
        "PAYMENT_WEBHOOK_SECRET",
        # StreamYard / Selery
        "STREAMYARD_API_KEY", "SELERY_API_KEY",
    ]
    s = Settings()
    for attr in required_attrs:
        assert hasattr(s, attr), f"Missing config field: {attr}"
