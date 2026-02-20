# BlakJaks Platform — Environment Variables Reference

**Version:** 2.0
**Date:** February 19, 2026
**Purpose:** Complete reference for all environment variables required across all BlakJaks platform services

**Changelog (v1.0 → v2.0):**
- Added Teller.io integration variables
- Added 7TV emote integration variables
- Added avatar/image storage variables
- Added notification service variables (APNs, FCM)
- Added Insights dashboard variables (treasury snapshots, reconciliation, Teller sync)
- Consolidated and cleaned formatting from v1.0

---

## Table of Contents

1. [Environment Setup Guidelines](#environment-setup-guidelines)
2. [Database Configuration](#database-configuration)
3. [Blockchain & Crypto](#blockchain--crypto)
4. [Authentication & Security](#authentication--security)
5. [Third-Party API Keys](#third-party-api-keys)
6. [Google Cloud Services](#google-cloud-services)
7. [Mobile Push Notifications](#mobile-push-notifications)
8. [Application Configuration](#application-configuration)
9. [Monitoring & Logging](#monitoring--logging)
10. [Environment-Specific Variables](#environment-specific-variables)
11. [Payment Processing (TBD)](#payment-processing-tbd)
12. [Kubernetes Secrets (Production)](#kubernetes-secrets-production)
13. [Environment Variables Checklist](#environment-variables-checklist)
14. [Security Reminders](#security-reminders)

---

## Environment Setup Guidelines

### File Structure

**Backend (Python/FastAPI)**

```
/backend
  ├── .env.development
  ├── .env.staging
  ├── .env.production
  └── .env.example
```

**Frontend (React/Next.js)**

```
/frontend
  ├── .env.local
  ├── .env.development
  ├── .env.staging
  ├── .env.production
  └── .env.example
```

**Mobile Apps**

* iOS: Use Xcode build configurations + environment plist files
* Android: Use gradle build variants + build config fields

### Security Best Practices

1. **Never commit .env files to version control** (add to .gitignore)
2. **Use Google Secret Manager** for production secrets
3. **Rotate API keys quarterly** (automated via script)
4. **Separate credentials per environment** (dev, staging, prod)
5. **Use least privilege** for service accounts
6. **Encrypt sensitive values** in CI/CD pipelines

### Variable Naming Convention

```
FORMAT: SERVICE_SUBSYSTEM_PURPOSE

Examples:
- DATABASE_POSTGRES_URL
- BLOCKCHAIN_POLYGON_RPC_URL
- EMAIL_BREVO_API_KEY
- AUTH_JWT_SECRET_KEY
```

---

## Database Configuration

### PostgreSQL (Primary Database)

```shell
# Database Connection
DATABASE_POSTGRES_HOST=localhost
DATABASE_POSTGRES_PORT=5432
DATABASE_POSTGRES_NAME=blakjaks_production
DATABASE_POSTGRES_USER=blakjaks_user
DATABASE_POSTGRES_PASSWORD=<strong_password_here>

# Connection String (Alternative)
DATABASE_URL=postgresql://user:password@host:port/database

# Cloud SQL (Production)
DATABASE_CLOUD_SQL_CONNECTION_NAME=project:region:instance
DATABASE_SSL_MODE=require

# Connection Pooling
DATABASE_POOL_SIZE=20
DATABASE_MAX_OVERFLOW=10
DATABASE_POOL_TIMEOUT=30
DATABASE_POOL_RECYCLE=3600

# Read Replica (Optional)
DATABASE_POSTGRES_READ_REPLICA_HOST=replica-host
DATABASE_POSTGRES_READ_REPLICA_PORT=5432
```

**Where to get:**

* Development: Local PostgreSQL installation
* Production: Google Cloud SQL instance details

**Required for:** Backend API, Background Workers

---

### Redis (Cache & Session Store)

```shell
# Redis Connection
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=<redis_password>
REDIS_DB=0

# Connection String
REDIS_URL=redis://:<password>@host:port/db

# Google Cloud Memorystore (Production)
REDIS_MEMORYSTORE_IP=<memorystore_ip>
REDIS_SSL_ENABLED=true

# Clustering (Production)
REDIS_CLUSTER_ENABLED=true
REDIS_CLUSTER_NODES=node1:6379,node2:6379,node3:6379
```

**Where to get:**

* Development: Local Redis installation
* Production: Google Cloud Memorystore instance IP (<memorystore_ip>:6379, us-central1, Basic tier, 1GB)

**Required for:** Backend API, Background Workers, WebSocket Server, Scan Velocity

---

### TimescaleDB Configuration

```shell
# TimescaleDB Extension (uses same PostgreSQL connection)
TIMESCALE_ENABLED=true
TIMESCALE_RETENTION_DAYS_FINANCIAL=2555  # 7 years
TIMESCALE_RETENTION_DAYS_ANALYTICS=730   # 2 years
TIMESCALE_RETENTION_DAYS_SOCIAL=90       # 90 days
TIMESCALE_RETENTION_DAYS_TREASURY=90     # 90 days (sparkline data) [NEW v2]
```

**Where to get:** Configuration only (uses PostgreSQL connection)

**Required for:** Backend API, Analytics Workers, Insights API

---

## Blockchain & Crypto

### Polygon Node

```shell
# Self-Hosted Polygon Node
BLOCKCHAIN_POLYGON_NODE_URL=http://polygon-node:8545
BLOCKCHAIN_POLYGON_NODE_WS_URL=ws://polygon-node:8546

# Network
BLOCKCHAIN_POLYGON_NETWORK=mainnet  # or mumbai for testnet
BLOCKCHAIN_POLYGON_CHAIN_ID=137     # 80001 for mumbai

# Node Monitoring
BLOCKCHAIN_NODE_SYNC_CHECK_INTERVAL=60
BLOCKCHAIN_NODE_MAX_PEER_COUNT=50
```

**Where to get:**

* Self-hosted Polygon node (internal GKE service URL)

**Required for:** Backend API, Blockchain Worker

---

### Google Cloud KMS (Private Key Management)

```shell
# KMS Configuration
BLOCKCHAIN_KMS_PROJECT_ID=blakjaks-production
BLOCKCHAIN_KMS_LOCATION=us-central1
BLOCKCHAIN_KMS_KEYRING=treasury-keys

# Treasury Wallet Key IDs
BLOCKCHAIN_KMS_MEMBER_TREASURY_KEY=member-treasury-key
BLOCKCHAIN_KMS_AFFILIATE_TREASURY_KEY=affiliate-treasury-key
BLOCKCHAIN_KMS_WHOLESALE_TREASURY_KEY=wholesale-treasury-key

# Service Account for KMS Access
BLOCKCHAIN_KMS_SERVICE_ACCOUNT_JSON=<path_to_service_account_json>
```

**Where to get:**

* Google Cloud Console → Security → Key Management
* Create keyring and keys for each treasury
* Download service account JSON with KMS permissions

**Required for:** Backend API, Blockchain Worker

---

### Treasury Wallet Addresses

```shell
# Public Wallet Addresses (Polygon)
BLOCKCHAIN_MEMBER_TREASURY_ADDRESS=0x1234567890abcdef1234567890abcdef12345678
BLOCKCHAIN_AFFILIATE_TREASURY_ADDRESS=0xabcdef1234567890abcdef1234567890abcdef12
BLOCKCHAIN_WHOLESALE_TREASURY_ADDRESS=0x7890abcdef1234567890abcdef1234567890abcd

# Treasury Monitoring
BLOCKCHAIN_TREASURY_BALANCE_WARNING_THRESHOLD=10000  # USDT
BLOCKCHAIN_TREASURY_ALERT_EMAIL=treasury@blakjaks.com
```

**Where to get:**

* Generated when creating KMS keys
* Public addresses derived from private keys in KMS

**Required for:** Backend API, Blockchain Worker, Frontend (for display)

---

### USDT Token Contract

```shell
# USDT Contract on Polygon
BLOCKCHAIN_USDT_CONTRACT_ADDRESS=0xc2132D05D31c914a87C6611C10748AEb04B58e8F  # Polygon mainnet
BLOCKCHAIN_USDT_DECIMALS=6

# Gas Settings
BLOCKCHAIN_GAS_PRICE_MULTIPLIER=1.2
BLOCKCHAIN_MAX_GAS_PRICE=100  # GWEI
BLOCKCHAIN_GAS_LIMIT_TRANSFER=100000
```

**Where to get:**

* USDT contract address: Public (Polygon mainnet)
* Gas settings: Configuration values

**Required for:** Backend API, Blockchain Worker

---

### MetaMask Embedded Wallets SDK (formerly Web3Auth)

```shell
# MetaMask Embedded Wallets SDK
METAMASK_EMBEDDED_WALLETS_CLIENT_ID=<metamask_client_id>
METAMASK_EMBEDDED_WALLETS_NETWORK=sapphire_mainnet  # or sapphire_testnet
METAMASK_EMBEDDED_WALLETS_SECRET_KEY=<metamask_secret_key>

# Infura (RPC Fallback)
METAMASK_INFURA_API_KEY=<infura_api_key>
METAMASK_INFURA_RPC_URL=https://polygon-mainnet.infura.io/v3/<infura_api_key>

# Mobile App Configuration
METAMASK_IOS_BUNDLE_ID=com.blakjaks.app
METAMASK_ANDROID_PACKAGE_NAME=com.blakjaks.app
METAMASK_REDIRECT_URL=blakjaks://auth
METAMASK_SDK_APP_ID=blakjaks-app

# Blockchain Configuration (Polygon)
METAMASK_CHAIN_ID=137  # Polygon mainnet
METAMASK_RPC_URL=https://api.web3auth.io/infura-service/v1/0x89/<metamask_client_id>
```

**Where to get:**

* Dashboard: https://dashboard.web3auth.io
* Infura: https://infura.io dashboard (for RPC fallback)
* iOS SDK Docs: https://docs.metamask.io/embedded-wallets/sdk/ios/
* Android SDK Docs: https://docs.metamask.io/embedded-wallets/sdk/android/
* App bundle IDs from mobile app configuration

**Required for:** Mobile Apps (iOS, Android), Backend API (wallet address storage)

---

### Oobit Integration

```shell
# Oobit API
OOBIT_API_KEY=<oobit_api_key>
OOBIT_API_SECRET=<oobit_api_secret>
OOBIT_API_URL=https://v2.prod-api-oobit.com

# Oobit Widget Configuration
OOBIT_WIDGET_AUTH_ENDPOINT=/v1/widget/auth/create-token
OOBIT_TOKEN_EXPIRY_MINUTES=60
```

**Where to get:**

* Oobit dashboard (apply for API access)
* API documentation: https://docs.oobit.com

**Required for:** Backend API, Mobile Apps

---

## Authentication & Security

### JWT Configuration

```shell
# JWT Secrets (CRITICAL: Use strong random keys)
AUTH_JWT_SECRET_KEY=<256-bit-random-key>
AUTH_JWT_ALGORITHM=RS256
AUTH_JWT_ACCESS_TOKEN_EXPIRE_MINUTES=15
AUTH_JWT_REFRESH_TOKEN_EXPIRE_DAYS=30

# JWT Key Pair (RS256)
AUTH_JWT_PRIVATE_KEY_PATH=/secrets/jwt-private-key.pem
AUTH_JWT_PUBLIC_KEY_PATH=/secrets/jwt-public-key.pem
```

**How to generate:**

```shell
# Generate RS256 key pair
openssl genrsa -out jwt-private-key.pem 2048
openssl rsa -in jwt-private-key.pem -pubout -out jwt-public-key.pem

# Or use Python for a random secret
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

**Required for:** Backend API, All Frontends

---

### Argon2id Password Hashing

```shell
# Argon2id Configuration
AUTH_PASSWORD_HASH_ALGORITHM=argon2id
AUTH_PASSWORD_HASH_TIME_COST=3
AUTH_PASSWORD_HASH_MEMORY_COST=65536  # 64MB
AUTH_PASSWORD_HASH_PARALLELISM=4
AUTH_PASSWORD_HASH_LENGTH=32
AUTH_PASSWORD_SALT_LENGTH=16
```

**Where to get:** Configuration values (no external source)

**Required for:** Backend API

---

### Encryption Keys

```shell
# AES-256 Encryption (for sensitive PII)
ENCRYPTION_AES_KEY=<256-bit-hex-key>
ENCRYPTION_AES_IV=<128-bit-hex-key>

# Field-Level Encryption
ENCRYPTION_FIELDS_ENABLED=true
ENCRYPTION_KEY_ROTATION_DAYS=365
```

**How to generate:**

```shell
# Generate AES-256 key
openssl rand -hex 32

# Generate IV
openssl rand -hex 16
```

**Required for:** Backend API

---

### CORS Configuration

```shell
# CORS Allowed Origins
SECURITY_CORS_ALLOWED_ORIGINS=https://blakjaks.com,https://www.blakjaks.com,https://admin.blakjaks.com,https://wholesale.blakjaks.com,https://affiliate.blakjaks.com
SECURITY_CORS_ALLOW_CREDENTIALS=true
SECURITY_CORS_MAX_AGE=3600
```

**Where to get:** Configuration based on domain setup

**Required for:** Backend API

---

### Rate Limiting

```shell
# Rate Limit Configuration
SECURITY_RATE_LIMIT_ENABLED=true
SECURITY_RATE_LIMIT_GENERAL=1000/hour
SECURITY_RATE_LIMIT_SCAN=60/hour
SECURITY_RATE_LIMIT_WALLET=30/hour
SECURITY_RATE_LIMIT_AUTH=10/hour
SECURITY_RATE_LIMIT_ADMIN=10000/hour
SECURITY_RATE_LIMIT_AVATAR_UPLOAD=5/hour  # [NEW v2]

# Redis Storage for Rate Limiting
SECURITY_RATE_LIMIT_REDIS_PREFIX=rate_limit:
```

**Where to get:** Configuration values

**Required for:** Backend API

---

### IP Whitelisting (Admin Access)

```shell
# Admin IP Whitelist
SECURITY_ADMIN_IP_WHITELIST=203.0.113.0/24,198.51.100.42

# Bypass for Development
SECURITY_IP_WHITELIST_ENABLED=true  # false in dev
```

**Where to get:** Your office/admin IP addresses

**Required for:** Backend API, Admin Portal

---

## Third-Party API Keys

### Brevo (Email)

```shell
# Brevo API
EMAIL_BREVO_API_KEY=<brevo_api_key>
EMAIL_BREVO_SENDER_EMAIL=support@blakjaks.com
EMAIL_BREVO_SENDER_NAME=BlakJaks

# Email Templates
EMAIL_BREVO_TEMPLATE_WELCOME=1
EMAIL_BREVO_TEMPLATE_VERIFICATION=2
EMAIL_BREVO_TEMPLATE_PASSWORD_RESET=3
EMAIL_BREVO_TEMPLATE_ORDER_CONFIRMATION=4
EMAIL_BREVO_TEMPLATE_COMP_AWARDED=5
```

**Where to get:**

* Brevo dashboard → Settings → API Keys
* Create sender email and verify domain

**Required for:** Backend API, Email Worker

---

### AgeChecker.net (Age Verification)

```shell
# AgeChecker Client API (JavaScript Popup)
AGECHECKER_CLIENT_API_KEY=<agechecker_client_api_key>
AGECHECKER_POPUP_SCRIPT_URL=https://cdn.agechecker.net/static/popup/v1/popup.js

# Popup Configuration
AGECHECKER_MODE=auto
AGECHECKER_ELEMENT_SELECTOR=#checkout-button
AGECHECKER_MINIMUM_AGE=21
AGECHECKER_CALL_EVENTS=true
AGECHECKER_RENAME_ELEMENT=true

# Customization (Optional)
AGECHECKER_BACKGROUND=rgba(0,0,0,0.7)
AGECHECKER_ACCENT_COLOR=linear-gradient(135deg, #FFD700 0%, #000000 100%)
AGECHECKER_FONT='Muli', 'Arial', 'Helvetica', sans-serif
AGECHECKER_LOGO_URL=https://cdn.blakjaks.com/logo.png
AGECHECKER_LOGO_HEIGHT=60px

# Field Mapping (Custom Checkout Integration)
AGECHECKER_FIELD_FIRST_NAME=#checkout-first-name
AGECHECKER_FIELD_LAST_NAME=#checkout-last-name
AGECHECKER_FIELD_ADDRESS=#checkout-address
AGECHECKER_FIELD_CITY=#checkout-city
AGECHECKER_FIELD_STATE=#checkout-state
AGECHECKER_FIELD_ZIP=#checkout-zip
AGECHECKER_FIELD_COUNTRY=#checkout-country
AGECHECKER_FIELD_EMAIL=#checkout-email
AGECHECKER_FIELD_COMMENTS=#order-notes

# Behavior Settings
AGECHECKER_REQUIRE_EMAIL=true
AGECHECKER_ADD_COMMENT=true
AGECHECKER_COMMENT_DETAILS=true
AGECHECKER_DISABLE_FIELDS=true
AGECHECKER_SHOW_CLOSE=false
AGECHECKER_SCROLL_INTO_VIEW=true
AGECHECKER_DEFER_SUBMIT=false
```

**Where to get:**

* AgeChecker.net dashboard → API Keys
* Enhanced Verification Rules: Set in dashboard under "Verification Rules"
* Recommended rule: "Unverified Only from Website / API Key" (first-time customers verified, returning auto-pass)

**Client-Side Integration Example:**

```javascript
var AgeCheckerConfig = {
  key: process.env.AGECHECKER_CLIENT_API_KEY,
  element: "#checkout-button",
  mode: "auto",
  fields: {
    first_name: "#checkout-first-name",
    last_name: "#checkout-last-name",
    address: "#checkout-address",
    city: "#checkout-city",
    state: "#checkout-state",
    zip: "#checkout-zip",
    country: "#checkout-country",
    contact_email: "#checkout-email",
    comments: "#order-notes"
  },
  background: "rgba(0,0,0,0.7)",
  accent_color: "linear-gradient(135deg, #FFD700 0%, #000000 100%)",
  logo_url: "https://cdn.blakjaks.com/logo.png",
  oncreated: function(verification, cancel) {
    document.getElementById('verification-uuid').value = verification.uuid;
  },
  onstatuschanged: function(verification) {
    if (verification.status === "denied") {
      alert("Age verification failed. You must be 21+ to purchase.");
      cancel();
    }
  },
  onclosed: function(done) {
    submitOrder();
  }
};
```

**Server-Side (Store UUID):**

```python
order = Order(
    user_id=user.id,
    age_verified=True,
    age_verification_id=request.form.get('verification_uuid'),
    # ... other order fields
)
```

**Verification Flow:**

1. User fills out checkout form (name, address, email, DOB)
2. User clicks "Place Order" button
3. AgeChecker popup appears with pre-filled data from checkout form
4. User confirms their information and submits
5. AgeChecker validates against government databases
6. If approved: Popup closes, verification UUID stored, order proceeds
7. If signature/ID required: Additional steps shown in popup
8. If denied: Order blocked, user notified

**Required for:** Frontend (Checkout Page), Backend API (store UUID)

---

### Kintsugi (Sales Tax Automation)

```shell
# Kintsugi API
KINTSUGI_API_KEY=<kintsugi_api_key>
KINTSUGI_API_URL=https://api.trykintsugi.com/v1
KINTSUGI_ENVIRONMENT=production  # production or sandbox

# Organization Configuration
KINTSUGI_ORGANIZATION_ID=<your_organization_id>
KINTSUGI_ORGANIZATION_ADDRESS_LINE1=<your_business_address>
KINTSUGI_ORGANIZATION_CITY=<city>
KINTSUGI_ORGANIZATION_STATE=<state>
KINTSUGI_ORGANIZATION_ZIP=<zip>
KINTSUGI_ORGANIZATION_COUNTRY=US

# Product Configuration
KINTSUGI_PRODUCT_CATEGORY=tobacco_products
KINTSUGI_PRODUCT_TAX_CODE=40030000
KINTSUGI_AUTO_CLASSIFY_PRODUCTS=true

# Tax Calculation Settings
KINTSUGI_VALIDATE_ADDRESSES=true
KINTSUGI_ROOFTOP_ACCURACY=true
KINTSUGI_INCLUDE_CITY_TAX=true
KINTSUGI_INCLUDE_COUNTY_TAX=true
KINTSUGI_INCLUDE_STATE_TAX=true
KINTSUGI_INCLUDE_SPECIAL_TAX=true

# Transaction Reporting
KINTSUGI_AUTO_CREATE_TRANSACTIONS=true
KINTSUGI_TRANSACTION_TYPE=sale

# Filing & Compliance
KINTSUGI_AUTO_FILE_ENABLED=true
KINTSUGI_AUTO_REGISTER_NEXUS=true
KINTSUGI_HANDLE_PHYSICAL_MAIL=true

# Exemption Management
KINTSUGI_HANDLE_EXEMPTIONS=true
KINTSUGI_VALIDATE_EXEMPTION_CERTIFICATES=true

# Webhooks (Optional)
KINTSUGI_WEBHOOK_URL=https://api.blakjaks.com/webhooks/kintsugi
KINTSUGI_WEBHOOK_SECRET=<webhook_secret>
KINTSUGI_WEBHOOK_EVENTS=transaction.created,filing.completed,nexus.detected

# SDK Configuration
KINTSUGI_SDK_TIMEOUT=30  # seconds
KINTSUGI_SDK_RETRY_ATTEMPTS=3
```

**Where to get:**

* API Key: Kintsugi Dashboard → Profile → Account → Organization API Keys
* Organization ID: Kintsugi Dashboard → Organization Settings
* Dashboard: https://app.trykintsugi.com
* API Documentation: https://docs.trykintsugi.com
* API Reference: https://api-docs.trykintsugi.com

**Integration Workflow:**

1. **Product Sync (One-time):** Register BlakJaks products — POST /v1/products
2. **Tax Estimation (Checkout):** Calculate tax — POST /v1/tax/estimate
3. **Transaction Reporting (Post-purchase):** Record sale — POST /v1/transactions

**Key Features:**
- AI-Powered automatic product classification, nexus detection
- Rooftop accuracy: Precise location-based tax rates
- Auto-Filing: Files returns and remits taxes automatically
- Nexus Monitoring: Real-time tracking of tax obligations across states
- Address Validation: Validates and cleans customer addresses
- Exemption Management: Handles tax-exempt customers and certificates
- Kintsugi Mail: Virtual mailbox handles government notices

**SDKs Available:** Python (`pip install kintsugi`), TypeScript/Node (`npm install @kintsugi/node`), Java, PHP, Ruby

**Required for:** Backend API, Checkout Flow, Tax Compliance

---

### Intercom (Customer Support)

```shell
# Intercom Configuration
INTERCOM_APP_ID=<intercom_app_id>
INTERCOM_API_KEY=<intercom_api_key>
INTERCOM_IDENTITY_VERIFICATION_SECRET=<intercom_secret>

# Mobile SDKs
INTERCOM_IOS_API_KEY=<intercom_ios_sdk_key>
INTERCOM_ANDROID_API_KEY=<intercom_android_sdk_key>

# Features
INTERCOM_FIN_AI_ENABLED=true
```

**Where to get:**

* Intercom dashboard → Settings → Installation
* Mobile SDK keys from platform-specific settings

**Required for:** Backend API, Mobile Apps, Web Frontend

---

### Google Cloud Translation API

```shell
# Translation API
TRANSLATION_GOOGLE_PROJECT_ID=<google_cloud_project_id>
TRANSLATION_GOOGLE_CREDENTIALS_PATH=/secrets/translation-service-account.json

# Translation Settings
TRANSLATION_ENABLED=true
TRANSLATION_DEFAULT_LANGUAGE=en
TRANSLATION_SUPPORTED_LANGUAGES=en,es,pt

# Caching
TRANSLATION_CACHE_TTL=604800  # 7 days in seconds
```

**Where to get:**

* Google Cloud Console → APIs & Services → Translation API
* Create service account with Translation API permissions

**Required for:** Backend API, Social Hub

---

### Selery (Order Fulfillment)

```shell
# Selery API
FULFILLMENT_SELERY_API_KEY=<selery_api_key>
FULFILLMENT_SELERY_API_URL=https://api.selery.com/v1
FULFILLMENT_SELERY_WAREHOUSE_ID=<warehouse_id>

# Webhooks
FULFILLMENT_SELERY_WEBHOOK_SECRET=<webhook_secret>
FULFILLMENT_SELERY_WEBHOOK_URL=https://api.blakjaks.com/webhooks/selery

# Inventory Sync
FULFILLMENT_INVENTORY_SYNC_INTERVAL=3600  # 1 hour
```

**Where to get:**

* Selery dashboard → API Settings
* Configure webhook URL in Selery dashboard

**Required for:** Backend API, Order Worker

---

### Giphy (GIF Integration)

```shell
# Giphy API
GIPHY_API_KEY=<giphy_api_key>
GIPHY_RATING=pg-13
GIPHY_LIMIT=25
```

**Where to get:**

* Giphy Developers: https://developers.giphy.com/
* Free tier available

**Required for:** Mobile Apps, Web Frontend (Social Hub)

---

### 7TV (Animated Emotes) [NEW v2]

```shell
# 7TV API
SEVENTV_EMOTE_SET_ID=<emote_set_id>
SEVENTV_API_BASE_URL=https://7tv.io/v3

# Caching
SEVENTV_CACHE_TTL=3600  # 1 hour — refresh emote set from 7TV API
SEVENTV_CDN_BASE_URL=https://cdn.7tv.app  # 7TV serves emote images from their CDN
```

**Where to get:**

* 7TV: https://7tv.io — create account and emote set in dashboard
* Emote set ID from 7TV dashboard after creating/selecting a set
* API docs: https://7tv.io/docs

**Required for:** Backend API (emote set cache), Mobile Apps, Web Frontend (Social Hub)

---

### OpenAI (Chat Moderation)

```shell
# OpenAI Moderation API
OPENAI_API_KEY=<openai_api_key>
OPENAI_MODERATION_MODEL=text-moderation-latest
OPENAI_MODERATION_ENABLED=true
```

**Where to get:**

* OpenAI Platform: https://platform.openai.com/api-keys
* Create API key under your OpenAI account

**Required for:** Backend API (Social Hub chat moderation — filters profanity, hate speech, spam)

---

### StreamYard (Live Streaming)

```shell
# StreamYard Configuration
STREAMING_RTMP_SERVER_URL=rtmp://stream.blakjaks.com/live
STREAMING_RTMP_SECRET_KEY=<rtmp_stream_key>

# HLS Configuration
STREAMING_HLS_OUTPUT_PATH=/var/www/hls
STREAMING_HLS_SEGMENT_DURATION=6
STREAMING_HLS_PLAYLIST_LENGTH=5

# CDN
STREAMING_CDN_URL=https://cdn.blakjaks.com/live
```

**Where to get:**

* Configure RTMP server (Nginx + RTMP module)
* Generate stream keys for security

**Required for:** Backend API, RTMP Server, Admin Portal

---

### Teller.io (Bank Balance Transparency) [NEW v2]

```shell
# Teller.io API (mTLS certificate-based auth — no API secret)
TELLER_APPLICATION_ID=<teller_application_id>
TELLER_CERT_PATH=/secrets/teller_cert.pem
TELLER_PRIVATE_KEY_PATH=/secrets/teller_private_key.pem
TELLER_ENV=production  # sandbox | production

# Webhook verification
TELLER_WEBHOOK_SECRET=<teller_webhook_secret>

# Sync Schedule
TELLER_BALANCE_SYNC_INTERVAL=21600  # 6 hours in seconds
```

**Where to get:**

* Teller Dashboard: https://app.teller.io
* Application ID generated when creating your application in dashboard
* Certificate + private key generated in Teller dashboard → Application Settings → Certificates
* Store cert + key files in Google Secret Manager

**Setup Process:**

1. Create Teller developer account at https://app.teller.io
2. Generate application certificate and private key in dashboard
3. Store cert + key in Google Secret Manager
4. Use Teller Connect (JavaScript widget) in admin portal to connect BlakJaks bank accounts (one-time)
5. Teller Connect returns `access_token` + `enrollment_id` — store encrypted in `teller_connections` table
6. Celery scheduled task fetches balances every 6 hours via `GET /accounts/{id}/balances` (mTLS)

**Security Notes:**

* Read-only access (balance only, no transaction history)
* Access tokens encrypted at rest (AES-256-GCM)
* Bank credentials never touch BlakJaks servers (handled by Teller Connect)
* Teller.io is SOC 2 Type II certified
* mTLS ensures mutual authentication — no shared secret transmitted

**Cost:** Subscription-based — see https://teller.io/pricing for current rates

**Required for:** Backend API (treasury endpoint), Admin Portal (Teller Connect setup)

---

## Google Cloud Services

### General Configuration

```shell
# Google Cloud Project
GOOGLE_CLOUD_PROJECT_ID=blakjaks-production
GOOGLE_CLOUD_PROJECT_NUMBER=752012521116
GOOGLE_CLOUD_REGION=us-central1
GOOGLE_CLOUD_ZONE=us-central1-a

# Service Account
GOOGLE_APPLICATION_CREDENTIALS=/secrets/gcp-service-account.json
```

**Where to get:**

* Google Cloud Console → IAM & Admin → Service Accounts
* Create service account with appropriate permissions

**Required for:** All Backend Services

---

### Google Cloud Storage

```shell
# Storage Buckets
STORAGE_GCS_USER_DOCUMENTS_BUCKET=blakjaks-user-documents
STORAGE_GCS_EMAIL_TEMPLATES_BUCKET=blakjaks-email-templates
STORAGE_GCS_QR_CODES_BUCKET=blakjaks-qr-codes
STORAGE_GCS_ADMIN_UPLOADS_BUCKET=blakjaks-admin-uploads
STORAGE_GCS_BACKUPS_BUCKET=blakjaks-backups
STORAGE_GCS_USER_AVATARS_BUCKET=blakjaks-user-avatars  # [NEW v2]

# CDN
STORAGE_CDN_URL=https://cdn.blakjaks.com
```

**Where to get:**

* Google Cloud Console → Storage → Browser
* Create buckets with appropriate lifecycle policies

**Required for:** Backend API, Admin Portal

---

### Avatar Storage [NEW v2]

```shell
# Avatar-specific configuration (bucket defined in GCS section above as STORAGE_GCS_USER_AVATARS_BUCKET)
AVATAR_MAX_SIZE_MB=5
AVATAR_ALLOWED_TYPES=image/jpeg,image/png
AVATAR_RESIZE_DIMENSIONS=256,512  # Generate 256x256 and 512x512 versions
AVATAR_CDN_BASE_URL=https://cdn.blakjaks.com/avatars
AVATAR_STRIP_EXIF=true
```

**Where to get:** Configuration values

**Required for:** Backend API (upload endpoint), Mobile Apps, Web Frontend

---

### Google Secret Manager

```shell
# Secret Manager Configuration
SECRETS_MANAGER_ENABLED=true
SECRETS_MANAGER_PROJECT_ID=blakjaks-production

# Secrets to Store:
# - Database passwords
# - API keys (Brevo, Kintsugi, AgeChecker, Teller.io, Oobit, Giphy, 7TV)
# - JWT keys
# - Encryption keys
# - KMS keys
# - Teller.io access tokens
```

**Where to get:**

* Google Cloud Console → Security → Secret Manager
* Store all sensitive credentials here

**Required for:** Backend API (Production)

---

## Mobile Push Notifications

### Apple Push Notification Service (APNs)

```shell
# APNs Configuration
APNS_KEY_ID=<apns_key_id>
APNS_TEAM_ID=<apple_team_id>
APNS_BUNDLE_ID=com.blakjaks.app
APNS_KEY_PATH=/secrets/apns_key.p8

# Environment
APNS_ENVIRONMENT=production  # or sandbox
```

**Where to get:**

* Apple Developer Portal → Certificates, IDs & Profiles → Keys
* Create APNs authentication key
* Download .p8 file

**Required for:** Backend API (iOS Push Notifications)

---

### Firebase Cloud Messaging (FCM)

```shell
# FCM Configuration
FCM_PROJECT_ID=blakjaks-android
FCM_SERVICE_ACCOUNT_PATH=/secrets/fcm_service_account.json
FCM_SERVER_KEY=<fcm_server_key>

# Android Package
FCM_PACKAGE_NAME=com.blakjaks.app
```

**Where to get:**

* Firebase Console → Project Settings → Cloud Messaging
* Download service account JSON

**Required for:** Backend API (Android Push Notifications)

---

## Application Configuration

### Backend API

```shell
# Application
APP_NAME=BlakJaks
APP_VERSION=2.0.0
APP_ENVIRONMENT=production  # development, staging, production

# Server
API_HOST=0.0.0.0
API_PORT=8000
API_WORKERS=4
API_RELOAD=false  # true only in development

# Base URLs
API_BASE_URL=https://api.blakjaks.com
API_DOCS_URL=/docs  # Disable in production: set to null
API_REDOC_URL=/redoc  # Disable in production

# HTTPS/TLS
API_SSL_ENABLED=true
API_SSL_CERT_PATH=/secrets/ssl-cert.pem
API_SSL_KEY_PATH=/secrets/ssl-key.pem
```

**Where to get:** Configuration values

**Required for:** Backend API

---

### Frontend Web Applications

```shell
# Next.js Configuration
NEXT_PUBLIC_API_URL=https://api.blakjaks.com
NEXT_PUBLIC_WS_URL=wss://api.blakjaks.com
NEXT_PUBLIC_CDN_URL=https://cdn.blakjaks.com

# Public Keys (safe to expose)
NEXT_PUBLIC_GOOGLE_ANALYTICS_ID=G-XXXXXXXXXX
NEXT_PUBLIC_SENTRY_DSN=https://xxx@sentry.io/xxx

# Environment
NEXT_PUBLIC_ENVIRONMENT=production
```

**Where to get:**

* API URL: Your backend deployment URL
* Analytics ID: Google Analytics dashboard
* Sentry DSN: Sentry.io project settings

**Required for:** All Web Frontends

---

### Mobile Apps Configuration

**iOS (Info.plist / .xcconfig)**

```
API_BASE_URL = https://api.blakjaks.com
WS_URL = wss://api.blakjaks.com
ENVIRONMENT = production
APP_VERSION = 1.0.0
BUILD_NUMBER = 1
```

**Android (build.gradle)**

```groovy
buildConfigField "String", "API_BASE_URL", "\"https://api.blakjaks.com\""
buildConfigField "String", "WS_URL", "\"wss://api.blakjaks.com\""
buildConfigField "String", "ENVIRONMENT", "\"production\""
```

**Required for:** iOS App, Android App

---

### Background Workers (Celery)

```shell
# Celery Configuration
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/1

# Task Queues
CELERY_TASK_DEFAULT_QUEUE=default
CELERY_TASK_QUEUES=default,crypto,email,analytics,insights

# Worker Settings
CELERY_WORKER_CONCURRENCY=4
CELERY_WORKER_PREFETCH_MULTIPLIER=4
CELERY_TASK_TIME_LIMIT=300  # 5 minutes
CELERY_TASK_SOFT_TIME_LIMIT=240  # 4 minutes

# Scheduled Tasks
CELERY_BEAT_ENABLED=true
CELERY_BEAT_SCHEDULE_FILE=/var/run/celerybeat-schedule
```

**Where to get:** Configuration values (uses Redis URL)

**Required for:** Background Workers

---

### WebSocket Server (Socket.io)

```shell
# Socket.io Configuration
SOCKETIO_ASYNC_MODE=asyncio
SOCKETIO_CORS_ALLOWED_ORIGINS=*  # Restrict in production
SOCKETIO_PING_TIMEOUT=60
SOCKETIO_PING_INTERVAL=25

# Redis Adapter (for multi-server)
SOCKETIO_REDIS_URL=redis://redis:6379/2
SOCKETIO_MESSAGE_QUEUE=redis://redis:6379/2

# Scaling
SOCKETIO_MAX_HTTP_BUFFER_SIZE=1000000  # 1MB
SOCKETIO_MAX_CONNECTIONS=10000
```

**Where to get:** Configuration values

**Required for:** WebSocket Server

---

### Insights Dashboard Configuration [NEW v2]

```shell
# Treasury Snapshots
INSIGHTS_TREASURY_SNAPSHOT_INTERVAL=3600  # 1 hour in seconds

# Teller Balance Sync
INSIGHTS_TELLER_SYNC_INTERVAL=21600  # 6 hours in seconds

# Daily Reconciliation
INSIGHTS_RECONCILIATION_HOUR=5  # UTC hour (5AM UTC)
INSIGHTS_RECONCILIATION_TOLERANCE=10.00  # USD tolerance (±$10)

# Scan Velocity
INSIGHTS_SCAN_VELOCITY_WINDOW=60  # seconds (1-minute window)
INSIGHTS_SCAN_VELOCITY_REDIS_PREFIX=scan_velocity:

# Activity Feed
INSIGHTS_FEED_MAX_ITEMS=100  # Max items in paginated feed
INSIGHTS_FEED_WS_NAMESPACE=/insights/live
```

**Where to get:** Configuration values

**Required for:** Backend API, Celery Workers, Insights WebSocket

---

## Monitoring & Logging

### Sentry (Error Tracking)

```shell
# Sentry Configuration
SENTRY_DSN=https://xxx@sentry.io/xxx
SENTRY_ENVIRONMENT=production
SENTRY_RELEASE=blakjaks@2.0.0
SENTRY_TRACES_SAMPLE_RATE=0.1  # 10% of transactions

# Error Filtering
SENTRY_IGNORE_ERRORS=KeyboardInterrupt,SystemExit
```

**Where to get:**

* Sentry.io dashboard → Settings → Client Keys (DSN)

**Required for:** Backend API, Mobile Apps, Web Frontends

---

### Prometheus

```shell
# Prometheus Configuration
PROMETHEUS_ENABLED=true
PROMETHEUS_PORT=9090
PROMETHEUS_METRICS_PATH=/metrics

# Metric Retention
PROMETHEUS_RETENTION_TIME=30d
```

**Where to get:** Configuration values

**Required for:** Backend API, Infrastructure

---

### Grafana

```shell
# Grafana Configuration
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=<strong_password>
GRAFANA_PORT=3000

# Data Sources
GRAFANA_DATASOURCE_PROMETHEUS=http://prometheus:9090
GRAFANA_DATASOURCE_POSTGRES=postgres://...
```

**Where to get:** Configuration values

**Required for:** Monitoring Infrastructure

---

### Google Cloud Logging

```shell
# Cloud Logging
LOGGING_LEVEL=INFO  # DEBUG, INFO, WARNING, ERROR, CRITICAL
LOGGING_FORMAT=json
LOGGING_GCP_ENABLED=true

# Log Retention
LOGGING_RETENTION_DAYS=90
LOGGING_AUDIT_RETENTION_DAYS=2555  # 7 years
```

**Where to get:** Configuration values

**Required for:** All Backend Services

---

## Environment-Specific Variables

### Development Environment

```shell
# Development-Only Variables
DEBUG=true
TESTING=false
RELOAD=true
LOG_LEVEL=DEBUG

# Local Services
DATABASE_POSTGRES_HOST=localhost
REDIS_HOST=localhost
BLOCKCHAIN_POLYGON_NETWORK=mumbai  # Testnet

# Disable Security Features (Dev Only)
SECURITY_IP_WHITELIST_ENABLED=false
SECURITY_RATE_LIMIT_ENABLED=false
AUTH_JWT_ACCESS_TOKEN_EXPIRE_MINUTES=1440  # 24 hours (for easier testing)

# Test Mode
EMAIL_SEND_ENABLED=false  # Don't send real emails
PUSH_NOTIFICATIONS_ENABLED=false  # Don't send real push
BLOCKCHAIN_TESTNET_MODE=true

# Teller Sandbox
TELLER_ENV=sandbox
```

---

### Staging Environment

```shell
# Staging Configuration
DEBUG=false
TESTING=true
LOG_LEVEL=INFO

# Staging Services
DATABASE_POSTGRES_HOST=staging-db-host
BLOCKCHAIN_POLYGON_NETWORK=mumbai  # Still testnet

# Moderate Security
SECURITY_IP_WHITELIST_ENABLED=false
SECURITY_RATE_LIMIT_ENABLED=true

# Test Mode
EMAIL_SEND_ENABLED=true  # Send to test emails only
BLOCKCHAIN_TESTNET_MODE=true
BLOCKCHAIN_TESTNET_FAUCET_URL=https://faucet.polygon.technology

# Teller Sandbox
TELLER_ENV=sandbox
```

---

### Production Environment

```shell
# Production Configuration
DEBUG=false
TESTING=false
LOG_LEVEL=WARNING

# Production Services
DATABASE_POSTGRES_HOST=production-db-host
BLOCKCHAIN_POLYGON_NETWORK=mainnet  # Real money!

# Full Security
SECURITY_IP_WHITELIST_ENABLED=true
SECURITY_RATE_LIMIT_ENABLED=true
AUTH_JWT_ACCESS_TOKEN_EXPIRE_MINUTES=15

# Production Mode
EMAIL_SEND_ENABLED=true
PUSH_NOTIFICATIONS_ENABLED=true
BLOCKCHAIN_TESTNET_MODE=false

# Teller Production
TELLER_ENV=production
```

---

## Payment Processing (TBD)

```shell
# Payment Processor Variables
# NOTE: Specific variables depend on chosen processor
# Examples below for common processors:

# Stripe (Example)
PAYMENT_STRIPE_SECRET_KEY=sk_live_...
PAYMENT_STRIPE_PUBLISHABLE_KEY=pk_live_...
PAYMENT_STRIPE_WEBHOOK_SECRET=whsec_...

# Square (Example)
PAYMENT_SQUARE_ACCESS_TOKEN=...
PAYMENT_SQUARE_LOCATION_ID=...

# Authorize.net (Example)
PAYMENT_AUTHORIZE_API_LOGIN_ID=...
PAYMENT_AUTHORIZE_TRANSACTION_KEY=...
```

**Where to get:** TBD based on payment processor selection

**Required for:** Backend API, Checkout Flow

---

## Kubernetes Secrets (Production)

### Creating Kubernetes Secrets

```shell
# Create secret from literal values
kubectl create secret generic database-credentials \
  --from-literal=username=blakjaks_user \
  --from-literal=password=<password> \
  --namespace=production

# Create secret from env file
kubectl create secret generic api-secrets \
  --from-env-file=.env.production \
  --namespace=production

# Create secret from file (service account)
kubectl create secret generic gcp-credentials \
  --from-file=key.json=/path/to/service-account.json \
  --namespace=production
```

### Mounting Secrets in Pods

```yaml
# Example: deployment.yaml
spec:
  containers:
  - name: api
    envFrom:
    - secretRef:
        name: api-secrets
    volumeMounts:
    - name: gcp-credentials
      mountPath: /secrets
      readOnly: true
  volumes:
  - name: gcp-credentials
    secret:
      secretName: gcp-credentials
```

---

## Environment Variables Checklist

### Required for Launch

**Backend API:**

* [ ] Database connection (PostgreSQL, Redis)
* [ ] JWT secret keys
* [ ] Blockchain KMS keys
* [ ] Treasury wallet addresses
* [ ] Brevo API key
* [ ] AgeChecker API key
* [ ] Kintsugi API key
* [ ] Intercom API key
* [ ] OpenAI API key (chat moderation)
* [ ] Google Cloud credentials
* [ ] Sentry DSN
* [ ] Teller.io credentials (application ID, cert, private key) [NEW v2]
* [ ] 7TV emote set ID [NEW v2]
* [ ] Insights configuration [NEW v2]

**Mobile Apps:**

* [ ] API base URL
* [ ] WebSocket URL
* [ ] MetaMask Embedded Wallets SDK configuration
* [ ] Oobit configuration
* [ ] APNs credentials (iOS)
* [ ] FCM credentials (Android)
* [ ] Intercom app ID
* [ ] Giphy API key
* [ ] Sentry DSN

**Web Frontends:**

* [ ] API base URL
* [ ] WebSocket URL
* [ ] Google Analytics ID
* [ ] Sentry DSN

**Infrastructure:**

* [ ] GKE cluster credentials
* [ ] Cloud SQL connection
* [ ] Memorystore Redis IP
* [ ] Google Cloud Storage buckets (including avatars bucket) [UPDATED v2]
* [ ] Prometheus/Grafana credentials

---

## Security Reminders

1. **Rotate secrets quarterly** (automated via cron job)
2. **Never log sensitive variables** (passwords, API keys, tokens)
3. **Use Secret Manager in production** (not plain .env files)
4. **Separate credentials per environment** (dev/staging/prod)
5. **Audit access to secrets** (who viewed what, when)
6. **Revoke compromised keys immediately** (have rotation procedure)
7. **Test disaster recovery** (can you restore from backups?)
8. **Document all variables** (update this file when adding new services)
9. **Encrypt Teller.io access tokens at rest** (AES-256-GCM) [NEW v2]

---

## Variable Management Tools

### Recommended Tools

1. **Google Secret Manager** (production secrets)
2. **dotenv** (local development)
3. **docker-compose.yml** (local services)
4. **Kubernetes Secrets** (GKE deployments)
5. **GitHub Secrets** (CI/CD pipeline)

### Secret Rotation Script

```shell
#!/bin/bash
# rotate-secrets.sh

# Rotate JWT keys
python scripts/rotate_jwt_keys.py

# Rotate API keys
python scripts/rotate_api_keys.py

# Update Kubernetes secrets
kubectl apply -f k8s/secrets/

# Restart deployments to pick up new secrets
kubectl rollout restart deployment/api-server -n production
```

---

**End of Environment Variables Reference v2.0**
