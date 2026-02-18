from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/blakjaks"
    SECRET_KEY: str = "change-me-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    RESET_TOKEN_EXPIRE_MINUTES: int = 60
    ENVIRONMENT: str = "development"
    CORS_ORIGINS: list[str] = ["*"]

    # Polygon / blockchain
    POLYGON_RPC_URL: str = "https://polygon-amoy.infura.io/v3/YOUR_KEY"
    POLYGON_NETWORK: str = "amoy"

    # Cloud KMS
    KMS_PROJECT_ID: str = "blakjaks-production"
    KMS_LOCATION: str = "us-central1"
    KMS_KEYRING: str = "blakjaks-crypto"
    KMS_KEY_NAME: str = "treasury-signer"
    KMS_KEY_VERSION: int = 1

    # Pool-specific KMS keys
    KMS_CONSUMER_KEY: str = "treasury-signer"
    KMS_AFFILIATE_KEY: str = "affiliate-pool-signer"
    KMS_WHOLESALE_KEY: str = "wholesale-pool-signer"

    # Third-party API keys (placeholders)
    KINTSUGI_API_KEY: str = ""
    AGECHECKER_API_KEY: str = ""
    BREVO_API_KEY: str = ""
    INTERCOM_API_KEY: str = ""

    # USDT contract addresses
    USDT_CONTRACT_ADDRESS_MAINNET: str = "0xc2132D05D31c914a87C6611C10748AEb04B58e8F"
    USDT_CONTRACT_ADDRESS_AMOY: str = ""

    model_config = {"env_file": ".env", "extra": "ignore"}


settings = Settings()
