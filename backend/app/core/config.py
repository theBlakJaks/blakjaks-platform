from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # -------------------------------------------------------------------------
    # Core
    # -------------------------------------------------------------------------
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/blakjaks"
    SECRET_KEY: str = "change-me-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30
    RESET_TOKEN_EXPIRE_MINUTES: int = 60
    ENVIRONMENT: str = "development"
    CORS_ORIGINS: list[str] = ["*"]

    # -------------------------------------------------------------------------
    # Redis
    # -------------------------------------------------------------------------
    REDIS_URL: str = "redis://localhost:6379/0"
    REDIS_CLUSTER_ENABLED: bool = False
    REDIS_SSL_ENABLED: bool = False

    # -------------------------------------------------------------------------
    # Celery
    # -------------------------------------------------------------------------
    CELERY_BROKER_URL: str = "redis://localhost:6379/1"
    CELERY_RESULT_BACKEND: str = "redis://localhost:6379/2"

    # -------------------------------------------------------------------------
    # Polygon / blockchain
    # -------------------------------------------------------------------------
    POLYGON_RPC_URL: str = "https://polygon-amoy.infura.io/v3/YOUR_KEY"
    POLYGON_NETWORK: str = "amoy"
    POLYGON_CHAIN_ID: int = 80002  # Amoy testnet; 137 for mainnet

    # Infura Polygon endpoints
    # Where to get: infura.io → Create Project → Polygon network → copy HTTPS and WebSocket endpoints
    BLOCKCHAIN_POLYGON_NODE_URL: str = "https://polygon-amoy.infura.io/v3/YOUR_INFURA_KEY"
    BLOCKCHAIN_POLYGON_NODE_WS_URL: str = "wss://polygon-amoy.infura.io/ws/v3/YOUR_INFURA_KEY"

    # Treasury wallet addresses (derived from KMS keys, stored in Secret Manager)
    BLOCKCHAIN_MEMBER_TREASURY_ADDRESS: str = ""
    BLOCKCHAIN_AFFILIATE_TREASURY_ADDRESS: str = ""
    BLOCKCHAIN_WHOLESALE_TREASURY_ADDRESS: str = ""

    # USDT contract addresses
    USDT_CONTRACT_ADDRESS_MAINNET: str = "0xc2132D05D31c914a87C6611C10748AEb04B58e8F"
    USDT_CONTRACT_ADDRESS_AMOY: str = ""

    # -------------------------------------------------------------------------
    # Cloud KMS (treasury signing)
    # -------------------------------------------------------------------------
    KMS_PROJECT_ID: str = "blakjaks-production"
    KMS_LOCATION: str = "us-central1"
    KMS_KEYRING: str = "blakjaks-crypto"
    KMS_KEY_NAME: str = "treasury-signer"
    KMS_KEY_VERSION: int = 1

    # Pool-specific KMS key names
    KMS_CONSUMER_KEY: str = "treasury-signer"
    KMS_AFFILIATE_KEY: str = "affiliate-pool-signer"
    KMS_WHOLESALE_KEY: str = "wholesale-pool-signer"

    # GCP KMS aliases (used by kms_service.py)
    GCP_PROJECT_ID: str = "blakjaks-production"
    GCP_KMS_LOCATION: str = "us-central1"
    GCP_KMS_KEY_RING: str = "blakjaks-crypto"
    GCP_KMS_KEY_NAME: str = "treasury-signer"

    # -------------------------------------------------------------------------
    # Google Cloud Storage
    # -------------------------------------------------------------------------
    GCS_PROJECT_ID: str = "blakjaks-production"
    GCS_BUCKET_AVATARS: str = "blakjaks-user-avatars"
    GCS_BUCKET_ASSETS: str = "blakjaks-static-assets"
    GCS_BUCKET_QR: str = "blakjaks-qr-codes"

    # -------------------------------------------------------------------------
    # Sentry
    # -------------------------------------------------------------------------
    SENTRY_DSN: str = ""
    SENTRY_ENVIRONMENT: str = "development"
    SENTRY_RELEASE: str = ""
    SENTRY_TRACES_SAMPLE_RATE: float = 0.1

    # -------------------------------------------------------------------------
    # Teller.io (bank sync)
    # -------------------------------------------------------------------------
    TELLER_CERT_PATH: str = ""
    TELLER_KEY_PATH: str = ""
    TELLER_ENV: str = "sandbox"
    TELLER_ACCOUNT_IDS: list[str] = []

    # -------------------------------------------------------------------------
    # APNs (iOS push notifications — native, no Firebase)
    # -------------------------------------------------------------------------
    APNS_KEY_ID: str = ""
    APNS_TEAM_ID: str = ""
    APNS_BUNDLE_ID: str = "com.blakjaks.app"
    APNS_CERT_PATH: str = ""

    # -------------------------------------------------------------------------
    # FCM (Android push notifications only)
    # -------------------------------------------------------------------------
    FCM_SERVER_KEY: str = ""

    # -------------------------------------------------------------------------
    # OpenAI
    # -------------------------------------------------------------------------
    OPENAI_API_KEY: str = ""

    # -------------------------------------------------------------------------
    # 7TV / Giphy (chat media)
    # -------------------------------------------------------------------------
    SEVEN_TV_EMOTE_SET_ID: str = ""
    GIPHY_API_KEY: str = ""

    # -------------------------------------------------------------------------
    # Intercom (in-app support chat)
    # -------------------------------------------------------------------------
    INTERCOM_APP_ID: str = ""
    INTERCOM_API_KEY: str = ""
    INTERCOM_IDENTITY_VERIFICATION_SECRET: str = ""
    INTERCOM_IOS_API_KEY: str = ""
    INTERCOM_ANDROID_API_KEY: str = ""

    # -------------------------------------------------------------------------
    # Google Cloud Translation
    # -------------------------------------------------------------------------
    TRANSLATION_GOOGLE_PROJECT_ID: str = "blakjaks-production"
    TRANSLATION_GOOGLE_CREDENTIALS_PATH: str = ""
    TRANSLATION_ENABLED: bool = True
    TRANSLATION_SUPPORTED_LANGUAGES: list[str] = [
        "en", "es", "fr", "de", "pt", "it", "ja", "ko", "zh", "ar",
    ]
    TRANSLATION_CACHE_TTL: int = 86400  # 24 hours in seconds

    # -------------------------------------------------------------------------
    # Google Analytics
    # -------------------------------------------------------------------------
    GA4_MEASUREMENT_ID: str = ""

    # -------------------------------------------------------------------------
    # Tax (Kintsugi)
    # -------------------------------------------------------------------------
    KINTSUGI_API_KEY: str = ""
    KINTSUGI_API_URL: str = "https://api.kintsugi.tech/v1"

    # -------------------------------------------------------------------------
    # Age verification (AgeChecker.net)
    # -------------------------------------------------------------------------
    AGECHECKER_API_KEY: str = ""

    # -------------------------------------------------------------------------
    # Email (Brevo / Sendinblue)
    # -------------------------------------------------------------------------
    BREVO_API_KEY: str = ""

    # -------------------------------------------------------------------------
    # Payment processor (TBD — pluggable)
    # -------------------------------------------------------------------------
    PAYMENT_PROCESSOR: str = ""  # "stripe" | "square" | "authorize"
    PAYMENT_SECRET_KEY: str = ""
    PAYMENT_PUBLISHABLE_KEY: str = ""
    PAYMENT_WEBHOOK_SECRET: str = ""

    # -------------------------------------------------------------------------
    # Oobit (crypto payment widget)
    # -------------------------------------------------------------------------
    OOBIT_API_KEY: str = ""
    OOBIT_SECRET_KEY: str = ""
    OOBIT_WIDGET_URL: str = "https://widget.oobit.com"

    # -------------------------------------------------------------------------
    # Third-party integrations
    # -------------------------------------------------------------------------
    STREAMYARD_API_KEY: str = ""
    SELERY_API_KEY: str = ""
    GOOGLE_TRANSLATE_API_KEY: str = ""

    model_config = {"env_file": ".env", "extra": "ignore"}


settings = Settings()
