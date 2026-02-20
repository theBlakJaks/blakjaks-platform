from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # --- Core ---
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/blakjaks"
    SECRET_KEY: str = "change-me-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30
    RESET_TOKEN_EXPIRE_MINUTES: int = 60
    ENVIRONMENT: str = "development"
    CORS_ORIGINS: list[str] = ["*"]

    # --- Redis ---
    REDIS_URL: str = "redis://localhost:6379/0"
    REDIS_CLUSTER_ENABLED: bool = False
    REDIS_SSL_ENABLED: bool = False

    # --- Celery ---
    CELERY_BROKER_URL: str = "redis://localhost:6379/0"
    CELERY_RESULT_BACKEND: str = "redis://localhost:6379/0"

    # --- Google Cloud Storage ---
    GCS_BUCKET_AVATARS: str = "blakjaks-user-avatars"
    GCS_BUCKET_ASSETS: str = "blakjaks-assets"
    GCS_BUCKET_QR: str = "blakjaks-qr-codes"
    GCS_PROJECT_ID: str = "blakjaks-production"

    # --- Google Cloud KMS ---
    GCP_PROJECT_ID: str = "blakjaks-production"
    GCP_KMS_KEY_RING: str = "blakjaks-crypto"
    GCP_KMS_KEY_NAME: str = "treasury-signer"
    GCP_KMS_LOCATION: str = "us-central1"
    # Legacy aliases kept for backwards compat with existing KMS references
    KMS_PROJECT_ID: str = "blakjaks-production"
    KMS_LOCATION: str = "us-central1"
    KMS_KEYRING: str = "blakjaks-crypto"
    KMS_KEY_NAME: str = "treasury-signer"
    KMS_KEY_VERSION: int = 1
    KMS_CONSUMER_KEY: str = "treasury-signer"
    KMS_AFFILIATE_KEY: str = "affiliate-pool-signer"
    KMS_WHOLESALE_KEY: str = "wholesale-pool-signer"

    # --- Blockchain (Polygon) ---
    POLYGON_CHAIN_ID: int = 80002  # Amoy testnet; mainnet = 137
    BLOCKCHAIN_POLYGON_NODE_URL: str = "http://polygon-node:8545"
    BLOCKCHAIN_POLYGON_NODE_WS_URL: str = "ws://polygon-node:8546"
    BLOCKCHAIN_MEMBER_TREASURY_ADDRESS: str = ""
    BLOCKCHAIN_AFFILIATE_TREASURY_ADDRESS: str = ""
    BLOCKCHAIN_WHOLESALE_TREASURY_ADDRESS: str = ""
    # Legacy — remove after Task C2 complete
    POLYGON_RPC_URL: str = "https://polygon-amoy.infura.io/v3/YOUR_KEY"
    POLYGON_NETWORK: str = "amoy"
    USDT_CONTRACT_ADDRESS_MAINNET: str = "0xc2132D05D31c914a87C6611C10748AEb04B58e8F"
    USDT_CONTRACT_ADDRESS_AMOY: str = ""

    # --- Teller.io (Bank Sync) ---
    TELLER_CERT_PATH: str = ""
    TELLER_KEY_PATH: str = ""
    TELLER_ENV: str = "sandbox"
    TELLER_ACCOUNT_IDS: str = ""  # comma-separated: operating,reserve,comp_pool

    # --- OpenAI ---
    OPENAI_API_KEY: str = ""

    # --- 7TV / Giphy ---
    SEVEN_TV_EMOTE_SET_ID: str = ""
    GIPHY_API_KEY: str = ""

    # --- APNs (iOS — native, no Firebase) ---
    APNS_KEY_ID: str = ""
    APNS_TEAM_ID: str = ""
    APNS_BUNDLE_ID: str = "com.blakjaks.app"
    APNS_CERT_PATH: str = ""

    # --- FCM (Android only) ---
    FCM_SERVER_KEY: str = ""

    # --- Sentry ---
    SENTRY_DSN: str = ""
    SENTRY_ENVIRONMENT: str = "development"
    SENTRY_RELEASE: str = ""
    SENTRY_TRACES_SAMPLE_RATE: float = 0.1

    # --- Intercom ---
    INTERCOM_APP_ID: str = ""
    INTERCOM_API_KEY: str = ""
    INTERCOM_IDENTITY_VERIFICATION_SECRET: str = ""
    INTERCOM_IOS_API_KEY: str = ""
    INTERCOM_ANDROID_API_KEY: str = ""

    # --- Google Cloud Translation ---
    TRANSLATION_GOOGLE_PROJECT_ID: str = ""
    TRANSLATION_GOOGLE_CREDENTIALS_PATH: str = ""
    TRANSLATION_ENABLED: bool = False
    TRANSLATION_SUPPORTED_LANGUAGES: str = "en,es,fr,de,ja,zh,pt,ar,ko,ru"
    TRANSLATION_CACHE_TTL: int = 86400  # seconds

    # --- Google Analytics ---
    GA4_MEASUREMENT_ID: str = ""

    # --- Kintsugi (Tax) ---
    KINTSUGI_API_KEY: str = ""
    KINTSUGI_API_URL: str = "https://api.kintsugi.io"

    # --- Payment Processor (TBD — pluggable) ---
    PAYMENT_PROCESSOR: str = ""  # stripe | square | authorize
    PAYMENT_SECRET_KEY: str = ""
    PAYMENT_PUBLISHABLE_KEY: str = ""
    PAYMENT_WEBHOOK_SECRET: str = ""

    # --- StreamYard / Selery ---
    STREAMYARD_API_KEY: str = ""
    SELERY_API_KEY: str = ""

    # --- Third-party (legacy) ---
    AGECHECKER_API_KEY: str = ""
    BREVO_API_KEY: str = ""
    GOOGLE_TRANSLATE_API_KEY: str = ""  # legacy — prefer TRANSLATION_GOOGLE_CREDENTIALS_PATH

    model_config = {"env_file": ".env", "extra": "ignore"}


settings = Settings()
