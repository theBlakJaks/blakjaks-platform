# BlakJaks GitHub Secrets Reference

All secrets below must be added to **Settings → Secrets and variables → Actions** in the GitHub repository.
Secrets marked **Required for CI** must be present before the test/deploy pipelines can run.
Secrets marked **Required for runtime** must be present before the service can function in production.

---

## GCP / Infrastructure

| Secret | Required for | Where to get |
|--------|-------------|--------------|
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | CI deploy | GCP Console → IAM → Workload Identity → pool provider resource name |
| `GCP_SERVICE_ACCOUNT` | CI deploy | GCP Console → IAM → Service Accounts → email of deploy SA |

---

## Database

| Secret | Required for | Where to get |
|--------|-------------|--------------|
| `DATABASE_URL` | CI + runtime | GCP Cloud SQL connection string: `postgresql+asyncpg://user:pass@/dbname?host=/cloudsql/project:region:instance` |

---

## Authentication

| Secret | Required for | Where to get |
|--------|-------------|--------------|
| `SECRET_KEY` | CI + runtime | Generate: `openssl rand -hex 32` |
| `JWT_SECRET_KEY` | Runtime | Same as SECRET_KEY or separate 256-bit hex string |

---

## Email (Brevo)

| Secret | Required for | Where to get |
|--------|-------------|--------------|
| `BREVO_API_KEY` | Runtime | Brevo dashboard → Settings → API Keys |

---

## Blockchain

| Secret | Required for | Where to get |
|--------|-------------|--------------|
| `BLOCKCHAIN_POLYGON_NODE_URL` | Runtime | Internal GKE service URL after Task C2 deployed: `http://polygon-node:8545` |
| `BLOCKCHAIN_POLYGON_NODE_WS_URL` | Runtime | `ws://polygon-node:8546` |
| `BLOCKCHAIN_MEMBER_TREASURY_ADDRESS` | Runtime | Wallet address from GCP KMS-derived key |
| `BLOCKCHAIN_AFFILIATE_TREASURY_ADDRESS` | Runtime | Wallet address from GCP KMS-derived key |
| `BLOCKCHAIN_WHOLESALE_TREASURY_ADDRESS` | Runtime | Wallet address from GCP KMS-derived key |

---

## Google Cloud KMS

| Secret | Required for | Where to get |
|--------|-------------|--------------|
| `GCP_PROJECT_ID` | Runtime | GCP Console → Project ID |
| `GCP_KMS_KEY_RING` | Runtime | Name of key ring created in GCP KMS |
| `GCP_KMS_KEY_NAME` | Runtime | Name of asymmetric signing key |
| `GCP_KMS_LOCATION` | Runtime | GCP region (e.g. `us-central1`) |

---

## Google Cloud Storage

| Secret | Required for | Where to get |
|--------|-------------|--------------|
| `GCS_PROJECT_ID` | Runtime | Same as `GCP_PROJECT_ID` |
| `GCS_BUCKET_AVATARS` | Runtime | Name of user-avatars GCS bucket |
| `GCS_BUCKET_ASSETS` | Runtime | Name of assets GCS bucket |
| `GCS_BUCKET_QR` | Runtime | Name of QR codes GCS bucket |

---

## Redis

| Secret | Required for | Where to get |
|--------|-------------|--------------|
| `REDIS_URL` | Runtime | Redis connection URL, e.g. `redis://redis:6379/0` (docker-compose) or Cloud Memorystore URL |

---

## Celery

| Secret | Required for | Where to get |
|--------|-------------|--------------|
| `CELERY_BROKER_URL` | Runtime | Same as `REDIS_URL` |
| `CELERY_RESULT_BACKEND` | Runtime | Same as `REDIS_URL` |

---

## Teller.io (Bank Sync)

| Secret | Required for | Where to get |
|--------|-------------|--------------|
| `TELLER_CERT_PATH` | Runtime | Path to mTLS cert file (download from teller.io dashboard) |
| `TELLER_KEY_PATH` | Runtime | Path to mTLS private key file |
| `TELLER_ENV` | Runtime | `sandbox` (testing) or `production` |
| `TELLER_ACCOUNT_IDS` | Runtime | Comma-separated Teller account IDs for Operating, Reserve, Comp Pool accounts |

---

## Push Notifications

| Secret | Required for | Where to get |
|--------|-------------|--------------|
| `APNS_KEY_ID` | Runtime | Apple Developer Portal → Certificates, Identifiers & Profiles → Keys |
| `APNS_TEAM_ID` | Runtime | Apple Developer Portal → Account → Membership |
| `APNS_BUNDLE_ID` | Runtime | `com.blakjaks.app` |
| `APNS_CERT_PATH` | Runtime | Path to downloaded `.p8` key file |
| `FCM_SERVER_KEY` | Runtime | Firebase Console → Project Settings → Cloud Messaging → Server key |

---

## OpenAI

| Secret | Required for | Where to get |
|--------|-------------|--------------|
| `OPENAI_API_KEY` | Runtime | platform.openai.com → API Keys |

---

## 7TV / Giphy

| Secret | Required for | Where to get |
|--------|-------------|--------------|
| `SEVEN_TV_EMOTE_SET_ID` | Runtime | 7TV dashboard → your emote set ID |
| `GIPHY_API_KEY` | Runtime | developers.giphy.com → Create an App |

---

## Sentry

| Secret | Required for | Where to get |
|--------|-------------|--------------|
| `SENTRY_DSN` | Runtime | sentry.io → Project → Settings → Client Keys (DSN) |
| `SENTRY_ENVIRONMENT` | Runtime | `production` or `staging` |
| `SENTRY_RELEASE` | Runtime | Set automatically in CI via `$GITHUB_SHA` |
| `SENTRY_TRACES_SAMPLE_RATE` | Runtime | Float 0.0–1.0, e.g. `0.1` |

---

## Intercom

| Secret | Required for | Where to get |
|--------|-------------|--------------|
| `INTERCOM_APP_ID` | Runtime | Intercom dashboard → Settings → Installation |
| `INTERCOM_API_KEY` | Runtime | Intercom dashboard → Settings → API Keys |
| `INTERCOM_IDENTITY_VERIFICATION_SECRET` | Runtime | Intercom dashboard → Settings → Identity Verification |
| `INTERCOM_IOS_API_KEY` | Runtime | Intercom dashboard → iOS SDK key |
| `INTERCOM_ANDROID_API_KEY` | Runtime | Intercom dashboard → Android SDK key |

---

## Google Cloud Translation

| Secret | Required for | Where to get |
|--------|-------------|--------------|
| `TRANSLATION_GOOGLE_PROJECT_ID` | Runtime | GCP Console → Project ID |
| `TRANSLATION_GOOGLE_CREDENTIALS_PATH` | Runtime | Path to service account JSON with Cloud Translation API access |

---

## Kintsugi (Tax)

| Secret | Required for | Where to get |
|--------|-------------|--------------|
| `KINTSUGI_API_KEY` | Runtime | Kintsugi dashboard → API Keys |
| `KINTSUGI_API_URL` | Runtime | `https://api.kintsugi.io` |

---

## Payment Processor (TBD)

| Secret | Required for | Where to get |
|--------|-------------|--------------|
| `PAYMENT_PROCESSOR` | Runtime | Choose: `stripe`, `square`, or `authorize` |
| `PAYMENT_SECRET_KEY` | Runtime | Processor dashboard → API Keys → Secret key |
| `PAYMENT_PUBLISHABLE_KEY` | Runtime | Processor dashboard → API Keys → Publishable key |
| `PAYMENT_WEBHOOK_SECRET` | Runtime | Processor dashboard → Webhooks → signing secret |

---

## AgeChecker

| Secret | Required for | Where to get |
|--------|-------------|--------------|
| `AGECHECKER_API_KEY` | Runtime | agechecker.net → API access |

---

## Google Analytics

| Secret | Required for | Where to get |
|--------|-------------|--------------|
| `GA4_MEASUREMENT_ID` | Runtime | Google Analytics → Admin → Data Streams → Web stream → Measurement ID |

---

*Created by Task A3. Actual secret values must be added manually by Joshua — never commit secret values to the repository.*
