# **BlakJaks Platform — Comprehensive Execution Plan**

**Version:** 2.0
**Date:** February 19, 2026
**Owner:** Joshua Dunn
**Purpose:** Complete technical specification for Claude Code AI agents to build the BlakJaks loyalty rewards platform. Updated to align with the iOS Master Strategy & Design Brief v5 and incorporate all resolved feature decisions.

**Changelog (v1.0 → v2.0):**
- Added formal REST API endpoint contract (aligned with iOS Brief)
- Added Insights API (6 REST endpoints + 1 WebSocket)
- Added In-App Notifications system
- Added Member ID generation
- Added richer scan response format
- Added Teller.io integration (bank account balances for transparency)
- Added 7TV animated emotes alongside Giphy in chat
- Added user avatar/profile picture support
- Added 12mg product strength
- Updated shipping to $2.99 flat rate, free over $50+
- Formalized reconciliation, payout pipeline, and scan velocity APIs
- Removed Hype Train references (confirmed: no gamification during live events)

---

## **Table of Contents**

1. [Executive Summary](#executive-summary)
2. [Technology Stack](#technology-stack)
3. [System Architecture](#system-architecture)
4. [REST API Contract](#rest-api-contract)
5. [Database Schema](#database-schema)
6. [Feature Specifications](#feature-specifications)
7. [Security Requirements](#security-requirements)
8. [Infrastructure & DevOps](#infrastructure--devops)
9. [Third-Party Integrations](#third-party-integrations)
10. [Testing & Quality Assurance](#testing--quality-assurance)
11. [Deployment Strategy](#deployment-strategy)
12. [Agent Orchestration Workflow](#agent-orchestration-workflow)
13. [Development Phases](#development-phases)
14. [Environment Variables & Secrets](#environment-variables--secrets)

---

## **Executive Summary**

### **Project Overview**

BlakJaks is a premium nicotine pouch brand with an integrated loyalty rewards platform that returns 50%+ of gross profit to customers through casino-style comps. The platform features:

* **Tier-based loyalty system** (Standard, VIP, High Roller, Whale)
* **Cryptocurrency rewards** ($100, $1K, $10K USDT on Polygon)
* **Trip comps** (21 luxury experiences worth $65K-$200K)
* **Casino comps** (Bellagio suite packages ~$5K value)
* **Affiliate program** (21% reward matching, permanent tier status)
* **Real-time social hub** (Discord-style channels + Twitch-style live events)
* **Multi-language support** (real-time chat translation)
* **Transparency dashboard** (public treasury visibility with on-chain verification + Teller.io bank balances)
* **In-app notification center** (system, social, comp, order notifications)

### **Business Model**

* **Revenue:** Direct-to-consumer nicotine pouch sales
* **Comp Distribution:** 50% Consumer Pool, 5% Affiliate Pool, 5% Wholesale Pool
* **Unique Value:** Only nicotine brand with crypto rewards and luxury experiences
* **Target Market:** 21+ nicotine users, crypto-savvy consumers, high-volume users

### **Technical Scope**

**Platforms:**

* Native iOS app (Swift/SwiftUI)
* Native Android app (Kotlin/Jetpack Compose)
* Web application (React + Next.js)
* Admin portal (React + Next.js)
* Wholesale portal (React + Next.js)
* Affiliate portal (React + Next.js)

**Core Systems:**

* Authentication & user management
* QR code generation & scanning
* Tier tracking & comp distribution
* Crypto wallet integration (MetaMask Embedded Wallets SDK + Oobit)
* E-commerce & order fulfillment
* Real-time social platform (with translation, Giphy, 7TV animated emotes)
* Affiliate tracking & payouts
* Transparency dashboard (Insights API)
* Governance & voting
* In-app notification center
* Bank account transparency (Teller.io integration)

---

## **Technology Stack**

### **Mobile Applications**

**iOS App**

* **Language:** Swift 5.9+
* **UI Framework:** SwiftUI
* **Architecture:** MVVM + Clean Architecture
* **Networking:** Alamofire / URLSession
* **State Management:** Combine (SDK interop only — async/await is default for all app code)
* **Local Storage:** CoreData + Keychain
* **Camera/QR:** AVFoundation
* **Push Notifications:** APNs (Apple Push Notification service) — native only, no Firebase on iOS
* **Biometrics:** LocalAuthentication (Face ID / Touch ID)
* **Crypto Wallet:** MetaMask Embedded Wallets SDK for iOS (formerly Web3Auth)
* **Real-Time:** Socket.io-client-swift (Socket.io compatible)

**Android App**

* **Language:** Kotlin 1.9+
* **UI Framework:** Jetpack Compose
* **Architecture:** MVVM + Clean Architecture
* **Networking:** Retrofit + OkHttp
* **State Management:** StateFlow + LiveData
* **Local Storage:** Room Database + EncryptedSharedPreferences
* **Camera/QR:** CameraX + ML Kit Barcode Scanning
* **Push Notifications:** FCM (Firebase Cloud Messaging)
* **Biometrics:** BiometricPrompt
* **Crypto Wallet:** MetaMask Embedded Wallets SDK for Android (formerly Web3Auth)
* **Real-Time:** Socket.io-client-java (Socket.io compatible)

### **Backend**

**API Server**

* **Language:** Python 3.11+
* **Framework:** FastAPI
* **Async Runtime:** uvicorn + asyncio
* **ORM:** SQLAlchemy 2.0 (async)
* **Validation:** Pydantic v2
* **Authentication:** JWT (PyJWT) + OAuth2
* **Task Queue:** Celery + Redis
* **Caching:** Redis
* **WebSockets:** Socket.io (python-socketio)

**Blockchain Infrastructure**

* **Node:** Self-hosted Polygon full node (Geth)
* **Web3 Library:** web3.py
* **Key Management:** Google Cloud KMS
* **RPC:** Custom Polygon node endpoint (no third-party)

### **Frontend Web**

**Technology**

* **Framework:** React 18+ with Next.js 14+
* **Language:** TypeScript
* **Styling:** Tailwind CSS
* **State Management:** Zustand
* **Forms:** React Hook Form + Zod validation
* **API Client:** Axios with React Query
* **Real-time:** Socket.io client
* **Charts:** Recharts
* **Animation:** Framer Motion

**Applications**

* Main website (marketing + social hub web access)
* Admin portal
* Wholesale portal
* Affiliate portal

### **Databases**

**Primary Database**

* **System:** PostgreSQL 15+
* **Hosting:** Google Cloud SQL (managed)
* **Replication:** Multi-region (us-central1 primary, us-east1 replica)
* **Extensions:** pgcrypto, uuid-ossp
* **Connection Pooling:** PgBouncer

**Time-Series Data**

* **System:** PostgreSQL native RANGE partitioning (monthly partitions on timestamp column)
* **Purpose:** Analytics, metrics, treasury snapshots, scan velocity
* **Retention:** Managed by Celery monthly job that drops old partitions (90 days for treasury snapshots, 2 years for analytics metrics)
* **Query pattern:** `date_trunc()` + `GROUP BY` for time-bucketed sparkline queries

**Cache & Session Store**

* **System:** Redis 7+
* **Hosting:** Google Cloud Memorystore
* **Clustering:** Redis Cluster for high availability
* **Use Cases:** Sessions, rate limiting, real-time counters, cache, scan velocity tracking

### **Infrastructure**

**Container Orchestration**

* **Platform:** Google Kubernetes Engine (GKE)
* **Regions:** us-central1 (primary), us-east1 (failover)
* **Node Pools:** Separate pools for API, workers, Polygon node
* **Scaling:** Horizontal Pod Autoscaler (HPA)

**CI/CD**

* **Version Control:** GitHub
* **Pipeline:** GitHub Actions
* **Container Registry:** Google Container Registry (GCR)
* **Deployment:** Automatic on test pass (main branch)

**Monitoring & Logging**

* **Metrics:** Google Cloud Monitoring + Prometheus + Grafana
* **Logging:** Google Cloud Logging
* **Error Tracking:** Sentry
* **APM:** Custom dashboards
* **Alerts:** Email notifications via AlertManager

**Storage**

* **Object Storage:** Google Cloud Storage
* **Buckets:** user-documents, email-templates, qr-codes, admin-uploads, user-avatars
* **CDN:** Cloud CDN for static assets + user avatars

### **Third-Party Services**

**Communications**

* **Email:** Brevo (transactional + marketing)
* **Push Notifications:** APNs (iOS) + FCM (Android)
* **Live Chat:** Intercom

**Payments & Verification**

* **Age Verification:** AgeChecker.net API
* **Payment Processing:** TBD (pluggable architecture)
* **Tax Calculation:** Kintsugi API (AI-powered sales tax automation)

**Crypto & Wallets**

* **Wallet SDK:** MetaMask Embedded Wallets SDK (formerly Web3Auth — auto-creates wallets)
* **Spend Card:** Oobit Plug & Pay SDK
* **DEX Bridge:** Stargate Finance (for cross-chain USDT swaps)

**Banking & Transparency**

* **Bank Balances:** Teller.io API (read-only balance access for transparency dashboard)

**Translation**

* **Service:** Google Cloud Translation API
* **Languages:** English, Spanish, Portuguese (initial), expandable

**Live Streaming**

* **Platform:** StreamYard (RTMP to custom endpoint)

**Order Fulfillment**

* **Provider:** Selery (or configurable alternative)

**Chat Media**

* **GIFs:** Giphy API + Giphy SDK (iOS/Android/Web)
* **Animated Emotes:** 7TV API (animated emote sets for chat)

**Analytics**

* **Platform:** Google Analytics 4

---

## **System Architecture**

### **High-Level Architecture**

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENT LAYER                             │
├─────────────┬─────────────┬─────────────┬──────────────────────┤
│   iOS App   │ Android App │  Web App    │  Admin/Portals       │
│   (Swift)   │  (Kotlin)   │ (Next.js)   │  (Next.js)           │
└─────────────┴─────────────┴─────────────┴──────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                       API GATEWAY                                │
│              (Load Balancer + Rate Limiting)                     │
└─────────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
┌──────────────┐  ┌──────────────────┐  ┌──────────────┐
│  FastAPI     │  │  WebSocket       │  │  Background  │
│  REST API    │  │  Server          │  │  Workers     │
│              │  │  (Socket.io)     │  │  (Celery)    │
└──────────────┘  └──────────────────┘  └──────────────┘
        │                   │                   │
        └───────────────────┼───────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      DATA LAYER                                  │
├───────────────┬──────────────┬──────────────┬──────────────────┤
│  PostgreSQL   │  TimescaleDB │    Redis     │   GCS (Files)    │
│  (Primary DB) │  (Analytics) │   (Cache)    │   (Documents)    │
└───────────────┴──────────────┴──────────────┴──────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
┌──────────────┐  ┌──────────────────┐  ┌──────────────┐
│  Polygon     │  │  External APIs   │  │  Monitoring  │
│  Full Node   │  │  (Brevo, Oobit,  │  │  & Logging   │
│  (Self-host) │  │  Teller, Intercom)│  │  (Sentry)    │
└──────────────┘  └──────────────────┘  └──────────────┘
```

### **Service Architecture**

**API Server (FastAPI)**

* RESTful API endpoints
* JWT authentication
* Request validation (Pydantic)
* Business logic layer
* Database operations (SQLAlchemy)

**WebSocket Server (Socket.io)**

* Real-time chat (social hub channels)
* Live activity feeds (Insights dashboard)
* Scan notifications
* Comp award notifications
* Social hub events
* Real-time counter updates (global scan counter, treasury balances)

**Background Workers (Celery)**

* Crypto comp payouts
* Affiliate calculations
* Weekly pool distributions
* Email sending
* QR code generation
* Analytics aggregation
* Tier recalculations
* Treasury balance snapshots (hourly)
* Reconciliation jobs (daily 5AM UTC)
* Notification creation

**Polygon Node**

* Blockchain synchronization
* Transaction broadcasting
* Wallet balance queries
* Event monitoring
* Treasury management

### **Data Flow Examples**

**Scan Flow (Updated — Rich Response)**

```
User scans QR → Mobile app → POST /scans/submit →
API validates code → Check if used → Mark as used →
Calculate tier → Check milestone → Award comp if triggered →
Update wallet → Create notification → WebSocket notification →
Return rich response (product_name, tier_progress, comp_earned, wallet_balance) →
UI update (scan confirmation modal)
```

**Crypto Payout Flow**

```
Comp awarded → Background worker picks up task →
Fetch treasury private key from KMS →
Sign transaction on Polygon node →
Broadcast to network → Monitor confirmation →
Update database → Create notification → Send email →
Update transparency dashboard → WebSocket event to Insights feed
```

**Affiliate Payout Flow**

```
Sunday midnight → Celery scheduled task →
Calculate all affiliate earnings for week →
Generate payout transactions → Admin approval (or auto) →
Batch process USDT transfers → Update records →
Create notifications → Send confirmation emails →
Update affiliate dashboards
```

**Insights Live Update Flow**

```
Scan recorded → Increment Redis counter (scans/minute) →
WebSocket broadcast to /insights/live subscribers →
Global scan counter ticks up → Activity feed item created →
Treasury balance snapshot (hourly Celery job) →
Insights API serves aggregated data on demand
```

---

## **REST API Contract**

**Base URL:** `https://api.blakjaks.com/v1`
**WebSocket:** `wss://api.blakjaks.com`
**Authentication:** Bearer JWT token in `Authorization` header (except public endpoints)

### **Authentication**

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/auth/signup` | Create new account + auto-create wallet | No |
| POST | `/auth/login` | Email + password login, returns JWT | No |
| POST | `/auth/refresh` | Refresh access token | Refresh token |
| POST | `/auth/reset-password` | Request password reset email | No |
| POST | `/auth/reset-password/confirm` | Set new password with reset code | No |
| POST | `/auth/logout` | Invalidate current tokens | Yes |

### **Users**

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/users/me` | Full user profile (name, email, tier, member_id, wallet_address) | Yes |
| GET | `/users/me/profile` | Profile display data (avatar, username, tier badge, stats) | Yes |
| PUT | `/users/me/profile` | Update profile (name, username, email) | Yes |
| POST | `/users/me/avatar` | Upload profile picture (multipart) | Yes |
| GET | `/users/me/stats` | Tier progress, scan counts, quarter info | Yes |
| GET | `/users/me/wallet` | Wallet balance, address, network info | Yes |
| GET | `/users/me/comps` | Comp vault history (filterable: crypto/trips/gold_chips) | Yes |
| GET | `/users/me/orders` | Order history (paginated) | Yes |

### **Scanning**

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/scans/submit` | Submit QR scan (code, timestamp, location) | Yes |
| GET | `/scans/recent` | User's recent scan history (paginated) | Yes |

**Scan Submit Response Format:**

```json
{
  "success": true,
  "product_name": "BlakJaks Mint Ice",
  "usdt_earned": 4.50,
  "tier_multiplier": 1.0,
  "tier_progress": {
    "current_tier": "high_roller",
    "current_count": 18,
    "next_tier": "whale",
    "next_tier_threshold": 30,
    "quarter_label": "Q1 2026"
  },
  "comp_earned": {
    "amount": 4.50,
    "type": "crypto",
    "lifetime_comps": 1250.00,
    "wallet_balance": 847.50,
    "gold_chips": 42
  },
  "milestone_hit": null
}
```

### **Wallet & Transactions**

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/transactions` | Wallet transaction history (filterable: all/deposits/withdrawals) | Yes |
| POST | `/wallet/withdraw` | Withdraw USDT to external address | Yes |

### **Shop & Orders**

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/shop/products` | All products (flavors, strengths, prices, stock) | Yes |
| POST | `/cart/add` | Add item (product_id, flavor, strength, quantity) | Yes |
| GET | `/cart` | Get current cart contents | Yes |
| PUT | `/cart/update` | Update item quantity (item_id, quantity) | Yes |
| DELETE | `/cart/remove` | Remove item from cart (item_id) | Yes |
| POST | `/orders/create` | Create order (shipping, payment, age verification) | Yes |
| POST | `/tax/estimate` | Estimate tax via Kintsugi (shipping address, items) | Yes |

### **Insights (Transparency Dashboard)**

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/insights/overview` | Global scan count, key vitals, milestones, recent feed | Yes |
| GET | `/insights/treasury` | Treasury wallet balances, bank balances (Teller.io), reconciliation, payout ledger, 90-day history | Yes |
| GET | `/insights/systems` | Budget health, payout pipeline, scan velocity, vault economy, tier distribution, reconciliation status | Yes |
| GET | `/insights/comps` | Prize tier stats, milestone progress, trip comp section, guarantee stats, tier eligibility | Yes |
| GET | `/insights/partners` | Affiliate metrics, sunset status, weekly pool, wholesale stats, partner treasuries, partner feed | Yes |
| GET | `/insights/feed` | Live activity events (paginated) | Yes |
| WSS | `/insights/live` | Real-time: counter ticks, feed events, balance updates | Yes |

### **Social Hub**

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/social/channels` | Channel list with categories, tier restrictions, unread counts | Yes |
| GET | `/social/channels/:id/messages` | Chat history for channel (paginated) | Yes |
| POST | `/social/channels/:id/messages` | Send message (text, GIF URL, emote) | Yes |
| GET | `/social/channels/:id/pins` | Pinned messages for channel | Yes |
| POST | `/social/messages/:id/react` | Add emoji reaction to message | Yes |
| POST | `/social/messages/:id/report` | Report a message | Yes |
| POST | `/social/messages/:id/translate` | Request translation of message to target language | Yes |
| WSS | `/social/ws` | Real-time chat (Socket.io namespace) | Yes |

### **Streaming & Live Events**

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/streaming/live` | Current live streams (status, title, host, viewers) | Yes |
| GET | `/streaming/schedule` | Upcoming scheduled streams | Yes |
| GET | `/streaming/archive` | Past streams (VOD if available) | Yes |

**HLS Playback:** `https://cdn.blakjaks.com/hls/[stream_key].m3u8`

### **Notifications**

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/notifications` | User's notifications (paginated, filterable by type) | Yes |
| PUT | `/notifications/:id/read` | Mark single notification as read | Yes |
| POST | `/notifications/read-all` | Mark all notifications as read | Yes |
| GET | `/notifications/unread-count` | Count of unread notifications | Yes |

### **Affiliate**

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/affiliate/stats` | Dashboard stats (earnings, downline, conversion rate) | Yes |
| GET | `/affiliate/referrals` | Downline list (filterable by tier, active/inactive) | Yes |
| GET | `/affiliate/chips` | Gold chip balance, vault status, expiring soon | Yes |
| GET | `/affiliate/payouts` | Payout history | Yes |

### **Oobit**

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/oobit/create-token` | Generate Oobit widget access token | Yes |

### **Admin Endpoints (Admin Portal Only)**

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/admin/users` | Search/list users | Admin |
| GET | `/admin/users/:id` | User detail (profile, tier, scans, wallet, orders) | Admin |
| PUT | `/admin/users/:id` | Edit user (tier override, suspend, etc.) | Admin |
| POST | `/admin/qr/generate` | Generate QR code batch | Admin |
| GET | `/admin/qr/batches` | List batches | Admin |
| POST | `/admin/qr/export` | Export batch CSV | Admin |
| POST | `/admin/qr/import-feedback` | Upload manufactured codes | Admin |
| GET | `/admin/comps` | List all comps (filterable) | Admin |
| POST | `/admin/comps/award` | Manually award comp to user | Admin |
| POST | `/admin/comps/retry/:id` | Retry failed crypto transfer | Admin |
| GET | `/admin/orders` | List orders (filterable) | Admin |
| PUT | `/admin/orders/:id` | Update order status | Admin |
| GET | `/admin/affiliates` | List affiliates | Admin |
| POST | `/admin/affiliates/payouts/approve` | Approve weekly payout batch | Admin |
| GET | `/admin/wholesale/applications` | List wholesale applications | Admin |
| PUT | `/admin/wholesale/:id/approve` | Approve/reject wholesale account | Admin |
| POST | `/admin/social/channels` | Create channel | Admin |
| PUT | `/admin/social/channels/:id` | Edit channel | Admin |
| DELETE | `/admin/social/messages/:id` | Delete message | Admin |
| POST | `/admin/social/users/:id/timeout` | Timeout user (duration) | Admin |
| POST | `/admin/social/users/:id/ban` | Permanent ban | Admin |
| POST | `/admin/social/messages/:id/pin` | Pin message | Admin |
| POST | `/admin/governance/votes` | Create governance vote | Admin |
| PUT | `/admin/governance/votes/:id` | Edit vote (before publish) | Admin |
| POST | `/admin/governance/votes/:id/close` | Close vote early | Admin |
| POST | `/admin/streaming/events` | Create/schedule live event | Admin |
| POST | `/admin/treasury/send` | Send USDT from treasury (requires 2FA) | Admin |
| GET | `/admin/treasury/pools` | View pool balances | Admin |
| GET | `/admin/audit-log` | View audit logs (filterable) | Admin |
| GET | `/admin/analytics` | Analytics data (custom date ranges) | Admin |


---

## **Database Schema**

### **Core Tables**

**users** *(UPDATED — added member_id, avatar_url, member_since)*

```sql
id                  UUID PRIMARY KEY
member_id           VARCHAR(20) UNIQUE NOT NULL -- Format: "BJ-XXXX-XX" (sequential + tier suffix)
email               VARCHAR(255) UNIQUE NOT NULL
password_hash       VARCHAR(255) NOT NULL
username            VARCHAR(50) UNIQUE NOT NULL
full_name           VARCHAR(255) NOT NULL
phone               VARCHAR(20)
date_of_birth       DATE NOT NULL
address_line1       VARCHAR(255)
address_line2       VARCHAR(255)
city                VARCHAR(100)
state               VARCHAR(50)
zip_code            VARCHAR(20)
country             VARCHAR(2) DEFAULT 'US'
tier                ENUM('standard', 'vip', 'high_roller', 'whale')
tier_status         ENUM('active', 'locked') DEFAULT 'active'
wallet_address      VARCHAR(42) -- Polygon address
oobit_card_id       VARCHAR(100)
avatar_url          VARCHAR(500) -- GCS URL for profile picture
totp_secret         VARCHAR(32) -- Optional 2FA
totp_enabled        BOOLEAN DEFAULT FALSE
face_id_enabled     BOOLEAN DEFAULT FALSE
language            VARCHAR(5) DEFAULT 'en'
member_since        DATE DEFAULT CURRENT_DATE
created_at          TIMESTAMP DEFAULT NOW()
updated_at          TIMESTAMP DEFAULT NOW()
last_login          TIMESTAMP
is_active           BOOLEAN DEFAULT TRUE
is_admin            BOOLEAN DEFAULT FALSE
referred_by_id      UUID REFERENCES users(id)
```

**Member ID Generation Logic:**
- Sequential number: Auto-increment starting at 0001
- Tier suffix: ST (Standard), VIP, HR (High Roller), WH (Whale)
- Format: `BJ-0001-ST`, `BJ-0042-VIP`, `BJ-0100-HR`, `BJ-0007-WH`
- Updated on tier change (suffix only, number stays)

**tier_history**

```sql
id                  UUID PRIMARY KEY
user_id             UUID REFERENCES users(id)
quarter             VARCHAR(7) -- '2026-Q1'
tier                ENUM('standard', 'vip', 'high_roller', 'whale')
scan_count          INTEGER DEFAULT 0
achieved_at         TIMESTAMP
expires_at          TIMESTAMP
is_permanent        BOOLEAN DEFAULT FALSE -- For affiliate-earned tiers
```

**scans**

```sql
id                  UUID PRIMARY KEY
user_id             UUID REFERENCES users(id)
code_id             UUID REFERENCES qr_codes(id)
scanned_at          TIMESTAMP DEFAULT NOW()
product_sku         VARCHAR(50)
flavor              VARCHAR(50)
strength            VARCHAR(10)
scan_method         ENUM('qr', 'manual')
geolocation         POINT -- lat/lng
device_id           VARCHAR(255)
ip_address          INET
comp_awarded        BOOLEAN DEFAULT FALSE
comp_amount         DECIMAL(10, 2)
comp_type           ENUM('crypto', 'trip', 'casino', 'gold_chip')
milestone_hit       VARCHAR(50) -- '500th', '7500th', etc.
```

**qr_codes**

```sql
id                  UUID PRIMARY KEY
code                VARCHAR(14) UNIQUE NOT NULL -- XXXX-XXXX-XXXX
status              ENUM('generated', 'manufactured', 'scanned', 'invalidated')
generated_at        TIMESTAMP DEFAULT NOW()
manufactured_at     TIMESTAMP
scanned_at          TIMESTAMP
scanned_by_user_id  UUID REFERENCES users(id)
batch_id            UUID REFERENCES qr_batches(id)
product_sku         VARCHAR(50)
```

**qr_batches**

```sql
id                  UUID PRIMARY KEY
name                VARCHAR(255)
code_count          INTEGER
generated_at        TIMESTAMP DEFAULT NOW()
exported_at         TIMESTAMP
manufacturer_name   VARCHAR(255)
notes               TEXT
```

**comps**

```sql
id                  UUID PRIMARY KEY
user_id             UUID REFERENCES users(id)
type                ENUM('crypto_100', 'crypto_1k', 'crypto_10k', 'trip', 'casino', 'new_member_guarantee')
amount              DECIMAL(10, 2)
awarded_at          TIMESTAMP DEFAULT NOW()
paid_at             TIMESTAMP
status              ENUM('pending', 'paid', 'failed', 'cancelled')
transaction_hash    VARCHAR(66) -- Polygon tx hash
trigger_scan_id     UUID REFERENCES scans(id)
milestone           VARCHAR(50)
notes               TEXT
```

**wallet_transactions**

```sql
id                  UUID PRIMARY KEY
user_id             UUID REFERENCES users(id)
type                ENUM('comp_deposit', 'withdrawal', 'oobit_spend', 'external_deposit')
amount              DECIMAL(18, 6) -- USDT supports 6 decimals
transaction_hash    VARCHAR(66)
from_address        VARCHAR(42)
to_address          VARCHAR(42)
status              ENUM('pending', 'confirmed', 'failed')
confirmations       INTEGER DEFAULT 0
created_at          TIMESTAMP DEFAULT NOW()
confirmed_at        TIMESTAMP
comp_id             UUID REFERENCES comps(id)
```

**notifications** *(NEW)*

```sql
id                  UUID PRIMARY KEY
user_id             UUID REFERENCES users(id)
type                ENUM('system', 'social', 'comp', 'order')
title               VARCHAR(255)
body                TEXT
read                BOOLEAN DEFAULT FALSE
data                JSONB -- Contextual payload (e.g., comp_id, order_id, channel_id)
created_at          TIMESTAMP DEFAULT NOW()
```

**affiliate_earnings**

```sql
id                  UUID PRIMARY KEY
affiliate_user_id   UUID REFERENCES users(id)
referred_user_id    UUID REFERENCES users(id)
earning_type        ENUM('prize_match', 'pool_share', 'gold_chip')
comp_id             UUID REFERENCES comps(id)
amount              DECIMAL(10, 2)
earned_at           TIMESTAMP DEFAULT NOW()
paid_at             TIMESTAMP
payout_id           UUID REFERENCES affiliate_payouts(id)
```

**affiliate_payouts**

```sql
id                  UUID PRIMARY KEY
payout_date         DATE
total_amount        DECIMAL(10, 2)
status              ENUM('pending_approval', 'approved', 'processing', 'completed', 'failed')
approved_by_admin   UUID REFERENCES users(id)
approved_at         TIMESTAMP
completed_at        TIMESTAMP
transaction_hash    VARCHAR(66)
earnings_count      INTEGER
```

**affiliate_pool_snapshots**

```sql
id                  UUID PRIMARY KEY
snapshot_date       DATE
total_pool_amount   DECIMAL(10, 2) -- 5% of GP
total_chips         BIGINT
chip_value          DECIMAL(10, 8) -- Pool amount / total chips
distributed_at      TIMESTAMP
payout_id           UUID REFERENCES affiliate_payouts(id)
```

**affiliate_chips**

```sql
id                  UUID PRIMARY KEY
user_id             UUID REFERENCES users(id)
chip_type           ENUM('referral_scan', 'vault_bonus', 'manual_grant')
chips_earned        INTEGER
earned_at           TIMESTAMP DEFAULT NOW()
vaulted             BOOLEAN DEFAULT FALSE
vaulted_at          TIMESTAMP
expires_at          TIMESTAMP -- 365 days from vault date
paid_out            BOOLEAN DEFAULT FALSE
payout_id           UUID REFERENCES affiliate_payouts(id)
```

**orders**

```sql
id                  UUID PRIMARY KEY
user_id             UUID REFERENCES users(id)
order_number        VARCHAR(50) UNIQUE
status              ENUM('pending', 'age_verification', 'payment_processing', 'confirmed', 'fulfilled', 'shipped', 'delivered', 'cancelled')
subtotal            DECIMAL(10, 2)
tax_amount          DECIMAL(10, 2)
shipping_cost       DECIMAL(10, 2) -- $2.99 flat rate or $0.00 if >= $50
total_amount        DECIMAL(10, 2)
payment_method      VARCHAR(50)
payment_status      ENUM('pending', 'authorized', 'captured', 'failed', 'refunded')
shipping_address    JSONB
age_verified        BOOLEAN DEFAULT FALSE
age_verification_id VARCHAR(100) -- AgeChecker.net reference
fulfilled_at        TIMESTAMP
shipped_at          TIMESTAMP
tracking_number     VARCHAR(100)
carrier             VARCHAR(50)
created_at          TIMESTAMP DEFAULT NOW()
updated_at          TIMESTAMP DEFAULT NOW()
```

**order_items**

```sql
id                  UUID PRIMARY KEY
order_id            UUID REFERENCES orders(id)
product_sku         VARCHAR(50)
product_name        VARCHAR(255)
flavor              VARCHAR(50)
strength            VARCHAR(10)
quantity            INTEGER
unit_price          DECIMAL(10, 2)
total_price         DECIMAL(10, 2)
```

**social_channels**

```sql
id                  UUID PRIMARY KEY
name                VARCHAR(100)
description         TEXT
category            VARCHAR(100)
icon                VARCHAR(50)
tier_restriction    ENUM('all', 'vip', 'high_roller', 'whale')
is_voice            BOOLEAN DEFAULT FALSE
display_order       INTEGER
created_by_admin    UUID REFERENCES users(id)
created_at          TIMESTAMP DEFAULT NOW()
is_active           BOOLEAN DEFAULT TRUE
```

**social_messages** *(UPDATED — added media_type, media_url)*

```sql
id                  UUID PRIMARY KEY
channel_id          UUID REFERENCES social_channels(id)
user_id             UUID REFERENCES users(id)
message             TEXT NOT NULL
original_language   VARCHAR(5)
media_type          ENUM('none', 'gif', 'emote', 'image') DEFAULT 'none'
media_url           VARCHAR(500) -- Giphy URL, 7TV emote URL, or image URL
is_system_message   BOOLEAN DEFAULT FALSE
reply_to_id         UUID REFERENCES social_messages(id)
pinned              BOOLEAN DEFAULT FALSE
pinned_by_admin     UUID REFERENCES users(id)
created_at          TIMESTAMP DEFAULT NOW()
deleted_at          TIMESTAMP
moderation_status   ENUM('approved', 'flagged', 'removed')
```

**social_message_translations**

```sql
id                  UUID PRIMARY KEY
message_id          UUID REFERENCES social_messages(id)
language            VARCHAR(5)
translated_text     TEXT
translated_at       TIMESTAMP DEFAULT NOW()
UNIQUE(message_id, language)
```

**social_message_reactions** *(NEW)*

```sql
id                  UUID PRIMARY KEY
message_id          UUID REFERENCES social_messages(id)
user_id             UUID REFERENCES users(id)
emoji               VARCHAR(20) -- Unicode emoji
created_at          TIMESTAMP DEFAULT NOW()
UNIQUE(message_id, user_id, emoji)
```

**governance_votes**

```sql
id                  UUID PRIMARY KEY
title               VARCHAR(255)
description         TEXT
vote_type           ENUM('flavor', 'loyalty', 'corporate')
tier_eligibility    ENUM('vip', 'high_roller', 'whale')
options             JSONB -- Array of vote options
status              ENUM('draft', 'active', 'closed')
created_by_admin    UUID REFERENCES users(id)
created_at          TIMESTAMP DEFAULT NOW()
voting_ends_at      TIMESTAMP
results_published   BOOLEAN DEFAULT FALSE
```

**governance_ballots**

```sql
id                  UUID PRIMARY KEY
vote_id             UUID REFERENCES governance_votes(id)
user_id             UUID REFERENCES users(id)
selected_option     VARCHAR(255)
voted_at            TIMESTAMP DEFAULT NOW()
UNIQUE(vote_id, user_id)
```

**wholesale_accounts**

```sql
id                  UUID PRIMARY KEY
company_name        VARCHAR(255)
contact_name        VARCHAR(255)
email               VARCHAR(255) UNIQUE
phone               VARCHAR(20)
business_address    JSONB
tax_id              VARCHAR(50) ENCRYPTED
status              ENUM('pending', 'approved', 'active', 'suspended')
approved_by_admin   UUID REFERENCES users(id)
approved_at         TIMESTAMP
wallet_address      VARCHAR(42)
tier                VARCHAR(50)
created_at          TIMESTAMP DEFAULT NOW()
```

**wholesale_orders**

```sql
id                  UUID PRIMARY KEY
account_id          UUID REFERENCES wholesale_accounts(id)
order_number        VARCHAR(50) UNIQUE
status              ENUM('pending', 'confirmed', 'fulfilled', 'cancelled')
total_tins          INTEGER
total_amount        DECIMAL(10, 2)
chips_earned        INTEGER
items               JSONB
created_at          TIMESTAMP DEFAULT NOW()
fulfilled_at        TIMESTAMP
```

**live_streams** *(NEW — formalized)*

```sql
id                  UUID PRIMARY KEY
title               VARCHAR(255) NOT NULL
description         TEXT
stream_key          VARCHAR(100) UNIQUE NOT NULL
status              ENUM('scheduled', 'live', 'ended', 'cancelled')
scheduled_at        TIMESTAMP
started_at          TIMESTAMP
ended_at            TIMESTAMP
viewer_count        INTEGER DEFAULT 0
peak_viewers        INTEGER DEFAULT 0
host_name           VARCHAR(100)
vod_url             VARCHAR(500) -- VOD playback URL if recorded
tier_restriction    ENUM('all', 'vip', 'high_roller', 'whale') DEFAULT 'all'
created_by_admin    UUID REFERENCES users(id)
created_at          TIMESTAMP DEFAULT NOW()
```

**transparency_metrics** (TimescaleDB)

```sql
timestamp           TIMESTAMPTZ NOT NULL
metric_type         VARCHAR(50) NOT NULL
metric_value        DECIMAL(18, 6)
metadata            JSONB
PRIMARY KEY (timestamp, metric_type)
```

**treasury_snapshots** *(NEW — TimescaleDB hypertable)*

```sql
timestamp           TIMESTAMPTZ NOT NULL
pool_type           ENUM('member', 'affiliate', 'wholesale') NOT NULL
onchain_balance     DECIMAL(18, 6) -- Blockchain balance
bank_balance        DECIMAL(18, 6) -- Teller.io-synced bank balance (nullable)
metadata            JSONB
PRIMARY KEY (timestamp, pool_type)
```

**teller_connections** *(NEW)*

```sql
id                  UUID PRIMARY KEY
account_name        VARCHAR(100) NOT NULL -- e.g., "Operating", "Reserve", "Comp Pool"
teller_access_token VARCHAR(255) ENCRYPTED -- Encrypted Teller access token
teller_enrollment_id VARCHAR(100) -- Teller enrollment ID
teller_account_id   VARCHAR(100) -- Specific Teller account ID
institution_name    VARCHAR(255)
last_synced_at      TIMESTAMP
status              ENUM('active', 'needs_reauth', 'disconnected')
created_at          TIMESTAMP DEFAULT NOW()
```

**audit_logs**

```sql
id                  UUID PRIMARY KEY
user_id             UUID REFERENCES users(id)
action              VARCHAR(100)
resource_type       VARCHAR(50)
resource_id         UUID
changes             JSONB
ip_address          INET
user_agent          TEXT
created_at          TIMESTAMP DEFAULT NOW()
```

### **Redis Data Structures**

**Scan Velocity Tracking:**
```
scan_velocity:minute:{timestamp}  → INCR (scans in this minute)
scan_velocity:hour:{timestamp}    → INCR (scans in this hour)
```

**Global Scan Counter:**
```
global:scan_count  → Current total scans (atomic increment)
```

**Unread Notification Counts:**
```
notifications:unread:{user_id}  → Count of unread notifications
```

### **Indexes**

```sql
-- Performance-critical indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_wallet ON users(wallet_address);
CREATE INDEX idx_users_member_id ON users(member_id);
CREATE INDEX idx_scans_user_date ON scans(user_id, scanned_at DESC);
CREATE INDEX idx_scans_code ON scans(code_id);
CREATE INDEX idx_qr_codes_code ON qr_codes(code);
CREATE INDEX idx_qr_codes_status ON qr_codes(status);
CREATE INDEX idx_comps_user_status ON comps(user_id, status);
CREATE INDEX idx_comps_type_awarded ON comps(type, awarded_at);
CREATE INDEX idx_wallet_tx_user ON wallet_transactions(user_id, created_at DESC);
CREATE INDEX idx_wallet_tx_hash ON wallet_transactions(transaction_hash);
CREATE INDEX idx_affiliate_earnings_user ON affiliate_earnings(affiliate_user_id, earned_at DESC);
CREATE INDEX idx_social_messages_channel ON social_messages(channel_id, created_at DESC);
CREATE INDEX idx_tier_history_user_quarter ON tier_history(user_id, quarter);
CREATE INDEX idx_orders_user ON orders(user_id, created_at DESC);
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, read, created_at DESC);
CREATE INDEX idx_notifications_type ON notifications(user_id, type, created_at DESC);
CREATE INDEX idx_live_streams_status ON live_streams(status, scheduled_at);
CREATE INDEX idx_social_reactions_message ON social_message_reactions(message_id);
```


---

## **Feature Specifications**

### **1. Authentication & User Management**

**User Registration**

* Collect: Email, password, full name, phone, address, DOB
* Validation: Email format, strong password (8+ chars, uppercase, number, symbol)
* Email verification: Send verification code via Brevo
* Username generation: Suggest based on name, allow custom
* Member ID: Auto-generate sequential `BJ-XXXX-XX` format
* Automatic affiliate assignment: referred_by_id from URL parameter
* Wallet creation: Auto-create MetaMask embedded wallet on signup
* Language selection: Default English, show language picker

**Login**

* Email + password authentication
* JWT access token (15 min expiry)
* JWT refresh token (30 days expiry)
* Mobile: Face ID/Touch ID after first login
* Desktop: Remember me for 30 days
* Failed login tracking: Lock account after 10 attempts in 1 hour

**Session Management**

* Mobile: Single device session (logout on new device login)
* Desktop: Single browser session
* Mobile logout: On app close
* Desktop logout: After 30 days inactivity

**Optional 2FA**

* TOTP-based (Google Authenticator, Authy compatible)
* User opt-in during account setup or settings
* Backup codes provided on 2FA enable
* QR code + manual entry key

**Password Reset**

* Email verification code flow
* Rate limit: 3 attempts per hour
* Code expiry: 15 minutes
* Force re-login on all devices after password change

### **2. QR Code Generation & Management**

**Code Generation**

* Format: `XXXX-XXXX-XXXX` (12 alphanumeric characters)
* Character set: A-Z, 2-9 (exclude 0,O,1,I for clarity)
* Cryptographically random (Python secrets module)
* Batch generation: Admin specifies quantity
* Database insertion: Bulk insert with status 'generated'
* Checksum: Optional validation digit for typo detection

**CSV Export**

* Columns: code, batch_id, batch_name, generated_at
* Filename: `blakjaks_codes_YYYYMMDD_HHMMSS.csv`
* Download from admin panel
* Track export timestamp

**Manufacturer Feedback**

* Upload CSV of manufactured codes
* Update status from 'generated' → 'manufactured'
* Track manufactured_at timestamp
* Unused codes: Admin can invalidate or reuse

**Code Validation (Scan)**

* Real-time database lookup
* Check status: must be 'manufactured'
* Single-use enforcement: Reject if already scanned
* Fraud detection:
  * Velocity check: Max 60 scans/hour per user
  * Geolocation: Flag impossible travel (scan NY → LA in 10 min)
  * Device check: Flag same code scanned from multiple devices
  * Pattern detection: Flag suspicious scan patterns
* Mark as 'scanned' on success
* Record: user_id, scanned_at, geolocation, device_id, IP
* Return rich response (see REST API Contract for full format)

### **3. Tier System & Calculations**

**Tier Thresholds (Quarterly)**

* Standard: 0-6 scans
* VIP: 7-14 scans
* High Roller: 15-29 scans
* Whale: 30+ scans

**Tier Calculation**

* Real-time: Update on every scan
* Quarter definition: Q1 (Jan-Mar), Q2 (Apr-Jun), Q3 (Jul-Sep), Q4 (Oct-Dec)
* Count scans in current quarter
* Assign tier based on scan count
* Tier benefits: Active immediately on threshold hit
* Tier expiry: End of quarter
* Reset: New quarter starts at 0 scans

**Permanent Tier Status (Affiliate-Earned)**

* VIP: Refer members who purchase 210 tins lifetime
* High Roller: Refer members who purchase 2,100 tins lifetime
* Whale: Refer members who purchase 21,000 tins lifetime
* Permanent = Never resets, even in new quarters
* User has TWO tiers: Current quarter tier + Permanent tier
* Effective tier: MAX(quarterly_tier, permanent_tier)

**Tier Display**

* Show current tier badge
* Show progress bar to next tier
* Show scans remaining to next tier
* Show permanent tier indicator if earned

### **4. Comp Award System**

**Comp Unlocking (Volume-Based)**

* $100 crypto: Active Day 1 (always unlocked)
* $1,000 crypto: Unlocks at 2,500 tins/month average
* $10,000 crypto: Unlocks at 50,000 tins/month average
* Casino comps: Unlocks at 10,000 tins/month average
* Trip comps: First trip unlocks at 500,000 tins/month average, +1 trip per additional 500K/month

**UI Display for Locked Comps**

* Show comp tier as "Locked"
* Progress bar: "12,847 / 50,000 tins/month average"
* Message: "Unlock $10K comps at 50,000 tins/month"
* Admin override: Manual unlock available in admin panel

**$100 Crypto Comp**

* Trigger: Every 500th scan (global counter)
* Eligibility: VIP+ tier
* Award: $100 USDT to user wallet
* Process: Background worker → KMS sign → Polygon transfer → Email notification → Create notification

**$1,000 Crypto Comp**

* Trigger: Every 7,500th scan (global counter)
* Eligibility: High Roller+ tier
* Award: $1,000 USDT to user wallet

**$10,000 Crypto Comp**

* Trigger: Every 125,000th scan (global counter)
* Eligibility: Whale tier only
* Award: $10,000 USDT to user wallet

**New Member $50 Guarantee**

* Eligibility: New users in their first year
* Mechanism: 10 automatic $5 comps awarded throughout first year
* Trigger: Time-based (not scan-based)
* Schedule: 1st comp at signup, then monthly for 12 months

**Casino Comp**

* Trigger: Milestone-based (Whale tier members only)
* Package includes:
  * 2-night Bellagio suite
  * $1,000 USDT "free play" crypto (auto-deposited)
  * $500 dining credit
  * VIP host services
  * Spa access
  * Airfare reimbursement (up to $1,000)
* Total value: ~$5,000
* Redemption: Email with instructions + crypto auto-deposited
* Casino partner coordination: Admin handles booking

**Trip Comp**

* Trigger: Every 500,000th scan (global counter)
* Eligibility: Whale tier only (whoever scans the milestone)
* Award notification: Shown in scan confirmation modal + notification created
* Selection process:
  1. User shown "You won a trip comp!" in scan confirmation
  2. Trip comp section highlighted in profile
  3. "Start Trip" button → Choose from 21 luxury experiences
  4. User selects destination
  5. BlakJaks team receives notification
  6. White-glove concierge service to finalize details
  7. Commemorative gold chip mailed after selection
* 21 destinations: Defined in business plan ($65K-$200K value each)

**Comp Processing Flow**

```py
# Pseudocode
async def process_scan(user_id, code):
    # Validate code
    code_record = await validate_qr_code(code)
    
    # Record scan
    scan = await create_scan(user_id, code_record.id)
    
    # Update tier
    new_tier = await update_user_tier(user_id)
    
    # Check milestones
    global_scan_count = await get_global_scan_count()
    
    comp = None
    
    # Check crypto comps
    if global_scan_count % 500 == 0 and user.tier in ['vip', 'high_roller', 'whale']:
        comp = await award_crypto_comp(user_id, 100, scan.id)
    elif global_scan_count % 7500 == 0 and user.tier in ['high_roller', 'whale']:
        comp = await award_crypto_comp(user_id, 1000, scan.id)
    elif global_scan_count % 125000 == 0 and user.tier == 'whale':
        comp = await award_crypto_comp(user_id, 10000, scan.id)
    
    # Check trip comp
    if global_scan_count % 500000 == 0 and user.tier == 'whale':
        comp = await award_trip_comp(user_id, scan.id)
    
    # Create notification
    if comp:
        await create_notification(user_id, 'comp', f'You earned ${comp.amount}!', {'comp_id': comp.id})
    
    # Trigger affiliate matching
    if user.referred_by_id and comp:
        await process_affiliate_match(user.referred_by_id, comp)
    
    # WebSocket broadcast (insights feed)
    await broadcast_scan_event(scan, comp)
    
    # Return rich response
    return build_rich_scan_response(scan, comp, user)
```

### **5. Crypto Wallet & Transactions**

**Wallet Creation**

* Auto-create on user signup
* Use MetaMask Embedded Wallets SDK (formerly Web3Auth)
* SDK creates non-custodial wallet with MPC security
* Network: Polygon PoS
* Store wallet_address in users table
* Private key managed by Web3Auth (split via MPC, user owns)
* No private key stored in our database

**Wallet Display**

* Show USDT balance (Polygon network)
* Show transaction history
* Show pending comps
* Send/Receive buttons
* Link to Oobit Plug & Pay card

**Comp Deposits**

* Background worker processes comp awards
* Fetch treasury private key from Google Cloud KMS
* Sign transaction using self-hosted Polygon node
* Broadcast to network
* Monitor confirmations (wait for 10 blocks)
* Update database status: pending → confirmed
* Create notification (type: 'comp')
* Send email notification
* Update transparency dashboard

**Withdrawals**

* User can withdraw to external wallet
* No minimum/maximum limits from BlakJaks
* Standard Polygon gas fees apply
* Confirmation modal before withdrawal
* Email notification on completion

**Oobit Integration**

* No native Swift or Kotlin SDK exists — Oobit provides a React Native SDK only
* Integration pattern for native apps (iOS/Android):
  1. Backend generates a short-lived access token: `POST /v1/widget/auth/create-token`
  2. Token returned to native app
  3. iOS loads Oobit widget URL in a `WKWebView` (Android: `WebView`), passing the token
  4. Widget handles card activation, KYC, and Apple/Google Pay setup internally
  5. App receives activation result via `WKScriptMessageHandler` (iOS) / `JavascriptInterface` (Android)
* BlakJaks tracks: Oobit card ID, activation status
* Spending functionality fully handled by Oobit

**Treasury Management**

* Three separate wallets:
  * Member Treasury (50% GP pool)
  * Affiliate Treasury (5% GP pool)
  * Wholesale Treasury (5% GP pool)
* Each wallet: Self-custodied hot wallet on self-hosted Polygon node
* Private keys: Stored in Google Cloud KMS
* Multi-sig for manual transfers: 2-of-3 signatures required
* Automated comp payouts: Single-sig (system controlled)
* Daily transaction limits: Flag >$50K for manual review
* Velocity monitoring: Alert if >$500K/hour outflows
* Backup reserves: Kept on exchanges (Coinbase, Gemini, Kraken, Binance)
* Transfer to hot wallet via Stargate Finance cross-chain swap
* Admin can send USDT from any pool to external address (requires 2FA)

**Blockchain Node**

* Self-hosted Polygon full node (Geth client)
* Dedicated GKE pod with persistent storage
* Isolated network (only accessible by backend API)
* RPC endpoint: Internal only (not public)
* Sync mode: Full node
* Regular backups of node data
* Monitoring: Block height, peer count, sync status

**Security**

* Private keys never leave KMS
* Transaction signing inside HSM
* Rate limiting: 100 comp payouts/minute
* Audit trail: All transactions logged
* Daily reconciliation: Database vs blockchain (5AM UTC, ±$10 tolerance)
* Auto-pause on suspicious activity

### **6. Affiliate Program**

**Affiliate Mechanics**

* All members are affiliates until sunset
* Sunset trigger: 10M tins/month average (3-month rolling)
* After sunset: Existing affiliates locked in, new members ineligible
* Referral tracking: Server-side cookie + database attribution
* Referral link: `blakjaks.com/r/{USERNAME}` or `blakjaks.com/r/{CUSTOM_CODE}`

**21% Reward Matching**

* When referred member receives comp → affiliate gets 21% match
* Examples:
  * Referral wins $100 → Affiliate gets $21
  * Referral wins $1,000 → Affiliate gets $210
  * Referral wins $10,000 → Affiliate gets $2,100
  * Referral wins $200K trip → Affiliate gets $42,000
* No cap on matching
* Lifetime tracking (even after sunset)
* Paid in USDT to affiliate wallet

**Permanent Tier Status**

* Track referral's total tins purchased (lifetime)
* VIP floor: 210 tins → Affiliate gets permanent VIP
* High Roller floor: 2,100 tins → Affiliate gets permanent High Roller
* Whale floor: 21,000 tins → Affiliate gets permanent Whale
* Permanent status: Never resets, stacks with quarterly tier

**Affiliate Chips**

* Earn 1 chip per referral scan
* Chips represent proportionate share of 5% GP pool
* Weekly pool distribution (every Sunday)
* Calculation: (User's chips / Total chips) × Weekly pool amount
* Vault system:
  * Overflow chips auto-vault
  * Bonus: 1 chip/month per 5 vaulted chips
  * Expiry: 365 days after vault date
  * Can withdraw from vault anytime before expiry

**Sunset Mechanism**

* Triggered at 10M tins/month (3-month rolling average)
* Dashboard alerts at every 5% threshold increase toward 10M
* Email notifications at each 5% milestone
* On sunset:
  * Lock current affiliate pool shares permanently
  * New members: No longer become affiliates
  * Existing affiliates: Continue earning forever
  * Pool distributions continue weekly

**Affiliate Dashboard**

* Overview: This month earnings, pending payout, downline count, conversion rate
* Referral link/code
* Downline list: Name, tier, scans, earnings generated
* Gold Chips earned
* Payout history

**Payout Process**

* Weekly: Every Sunday at midnight UTC
* Calculate all affiliate earnings for the week
* Generate payout batch
* Admin approval (or set to automatic)
* Batch USDT transfers to affiliate wallets
* Email confirmations
* Create notifications (type: 'comp')
* Update dashboard

**Whale Proposal System**

* Whale tier members can submit governance proposals
* Submission form in app
* Admin reviews and creates official vote
* Displayed in governance channel

### **7. E-Commerce & Shop**

**Product Catalog**

* Flavors: Spearmint, Wintergreen, Bubblegum, Blue Razz, Mint Ice, Citrus, Cinnamon, Coffee
* Strengths: 3mg, 6mg, 9mg, **12mg** *(UPDATED)*
* Price: $4.99 per tin (consistent pricing)
* Inventory: Synced with third-party inventory system via API

**Shopping Cart**

* Add to cart (flavor + strength + quantity)
* Cart persistence: Saved to database (not just session)
* Edit quantities
* Remove items
* Show cart total

**Checkout Flow**

1. Review cart
2. Confirm shipping address
3. Calculate sales tax (Kintsugi API)
4. Age verification (AgeChecker.net API)
5. Payment processing (via chosen processor)
6. Order confirmation
7. Email receipt (Brevo)
8. Create notification (type: 'order')

**Age Verification**

* Trigger: At checkout before payment
* Provider: AgeChecker.net (client-side JavaScript widget)
* Process:
  * Display AgeChecker.net popup via WebView at checkout
  * AgeChecker handles data collection and validation internally
  * Widget returns a pass/fail result to the client
  * Store: age_verification_id (returned by widget) in orders table
* Retention: AgeChecker retains all PII — we store only the reference ID
* Failed verification: Block checkout, show error

**Payment Processing**

* Pluggable architecture (provider TBD)
* Support: Credit card, USDT (crypto payments)
* 3DS verification for fraud prevention
* Tokenization: Never store card numbers
* Payment status tracking: pending → authorized → captured

**Tax Calculation**

* Provider: Kintsugi API (AI-powered, rooftop-accurate)
* Calculate based on: Shipping address, product category, precise location
* Display tax breakdown in cart (state, county, city, special taxes)
* Remit taxes: Kintsugi handles automatic filing and registration
* Nexus monitoring: Automatic detection of tax obligations across states
* Address validation: Built-in validation and cleaning

**Order Fulfillment**

* Auto-export to Selery (or configured provider) on order confirmation
* API integration: Send order details, shipping address
* Track fulfillment status: confirmed → fulfilled → shipped
* Receive tracking number from Selery
* Email tracking info to customer

**Shipping** *(UPDATED)*

* **Flat rate: $2.99 per order**
* **Free shipping: Orders $50+**
* Display in cart: "Add $X more for free shipping!" when subtotal < $50

**Inventory Management**

* Real-time sync with inventory provider API
* Product status: In stock / Out of stock
* Low stock warning in admin panel
* Prevent overselling: Check stock before order confirmation

### **8. Social Hub**

**Architecture**

* Real-time: WebSocket (Socket.io)
* Message delivery: <100ms
* Concurrent users: Scale to 250K during live events
* Message storage: 90 days retention
* Translation: Real-time via Google Cloud Translation API

**Channels**

* Categories: General, High Roller Lounge, Comps & Crypto, Governance
* Channels per category: 3-6 channels
* Tier restrictions:
  * Public channels: All tiers
  * High Roller Lounge: High Roller+ only
  * Whale Room: Whale only
* Admin-created: Only admins can create channels
* Channel display: Icon, name, description, unread count

**Chat Functionality**

* Text messages (2,000 characters max)
* **GIF support: Giphy integration (picker in compose bar)** *(maintained)*
* **Animated emotes: 7TV integration (emote picker in compose bar)** *(NEW)*
* **Image upload (optional)** *(NEW)*
* Reply threading: Reply to specific messages
* Reactions: Emoji reactions on messages
* Mentions: @username notifications
* System messages: Milestone announcements, tier changes

**User Profiles in Chat** *(UPDATED)*

* Display: Username, **avatar/profile picture**, tier badge, join date, total scans, lifetime comps
* **Custom avatars supported** (profile picture upload)
* Tier badge colors:
  * Standard: Red ♠
  * VIP: Silver ♦
  * High Roller: Gold ♣
  * Whale: Platinum ♛

**Real-Time Translation**

* User types in native language
* Message stored with original_language tag
* Broadcast to all users
* Each client requests translation to their language
* Cache translations (same message + language = cache hit)
* Cost optimization: Batch translate if multiple messages in quick succession
* Display: Small flag icon shows original language, tap to see original

**Rate Limiting (Twitch-Style)**

* Standard: 1 message per 1 second
* VIP: 1 message per 0.5 seconds
* High Roller: No cooldown
* Whale: No cooldown
* Escalating cooldown: Rapid messages trigger longer cooldowns
* Spam detection: 5 identical messages = temp mute (1 hour)

**Moderation**

* AI moderation: Filter profanity, hate speech, spam (OpenAI Moderation API)
* User reporting: Report message or user
* Admin actions:
  * Delete message
  * Timeout user (1 hour, 24 hours, 7 days)
  * Permanent ban
  * Pin message (important announcements)
* Audit log: All mod actions logged
* Appeal process: Contact support via Intercom

**Pinned Messages**

* Admins/mods can pin important messages
* Display at top of channel
* Unpin after event/announcement expires

### **9. Live Events**

**Streaming**

* Source: StreamYard (RTMP output)
* Destination: Custom RTMP endpoint on backend
* Playback: HLS streaming to mobile/web clients
* Latency: ~5-10 seconds
* CDN: Cloud CDN for global distribution

**Event Calendar**

* Weekly/monthly view
* Show upcoming events
* Event details: Title, date/time, description, tier requirements
* Reminder notifications: Push notification 1 hour before event

**Admin Controls**

* Start/stop stream
* Pin announcements to stream overlay
* Moderate live chat (same as regular channels)
* View live viewer count

**No Gamification During Events** *(clarified)*

* No scan multipliers during events
* No hype trains
* No gamification mechanics
* Pure community engagement focus

### **10. In-App Notifications** *(NEW)*

**Notification Types**

* **System**: Platform announcements, maintenance, new features
* **Social**: @mentions, replies to your messages
* **Comp**: Comp awarded, withdrawal completed, milestone approaching
* **Order**: Order confirmed, shipped, delivered

**Notification Creation Triggers**

* Comp awarded → Create 'comp' notification
* Order status change → Create 'order' notification
* @mention in chat → Create 'social' notification
* Admin broadcast → Create 'system' notification for all users

**Notification Display**

* Badge count on notification bell icon
* Notification center: Scrollable list, newest first
* Each notification: Icon (by type), title, body, timestamp, read/unread indicator
* Tap notification → Navigate to relevant screen (comp detail, order, chat message)

**Push Notifications**

* iOS: APNs (Apple Push Notification service)
* Android: FCM (Firebase Cloud Messaging)
* Trigger: Same events as in-app notifications
* User preferences: Toggle per notification type in settings
* Silent at night: Respect device Do Not Disturb settings

### **12. Insights (Transparency Dashboard)**

**Access**

* Visible to all authenticated members
* Real-time updates (5-second refresh for key metrics)
* Public version on website (limited, no login required)

**Overview Tab** — `GET /insights/overview`

* Live scan counter: Real-time total scans (animated count-up)
* Key metrics grid:
  * Total scans (all-time)
  * Monthly sales volume
  * Active members (last 30 days)
  * Growth rate
* Live activity feed:
  * "Someone won $100!" (2s ago)
  * "Affiliate earned $21 match!" (14s ago)
  * "New member $50 guarantee!" (31s ago)
  * Auto-scroll, refreshes via WebSocket

**Treasury Tab** — `GET /insights/treasury`

* Three on-chain wallets displayed:
  * Member Treasury (50% GP pool)
  * Affiliate Treasury (5% GP pool)
  * Wholesale Treasury (5% GP pool)
* Each wallet shows:
  * Current USDT balance
  * Progress bar (% of pool utilized)
  * Polygon wallet address
  * Copy button + "Verify on blockchain" link
* **Bank account balances (via Teller.io):** *(NEW)*
  * Operating account balance
  * Reserve account balance
  * Comp Pool account balance
  * Last Teller sync timestamp
* Sparkline charts: Treasury balance over last 90 days *(UPDATED from 30)*
* **Payout ledger:** *(NEW)*
  * Aggregated stats by comp type (counts, totals, percentages)
  * Crypto payouts, trip comps, guarantee payouts
* **Daily reconciliation status:** *(NEW)*
  * Last reconciliation: Timestamp (5AM UTC daily)
  * Tolerance: ±$10
  * Status badge: "Balanced" / "Discrepancy" / "Pending"

**Comps Tab** — `GET /insights/comps`

* Prize tiers grid:
  * $100 (X awarded, eligibility, frequency)
  * $1,000 (X awarded, eligibility, frequency)
  * $10,000 (X awarded, eligibility, frequency)
  * $200K Trip (X awarded, eligibility, frequency)
* Next milestones: Progress bars
  * "8 scans until next $100"
  * "608 scans until next $1,000"
* Trip comp section:
  * Currently eligible: X Whale members
  * Trips awarded: X this month, Y lifetime
  * Progress to next 500K: Bar + percentage
  * Reserve funds: $XXX,XXX held for trips
* New member guarantee:
  * Guarantees paid: X count
  * Total value: $XXX,XXX
* Tier eligibility table
* Vault economy:
  * Total chips vaulted
  * Bonus chips issued
  * Expired chips
  * Vault rules displayed

**Partners Tab** — `GET /insights/partners`

* Affiliate metrics:
  * Active affiliates: X (live pulse indicator)
  * Total chips issued: X
  * Sunset engine status: Active / Locked
  * Last sunset check date
* Weekly pool (5% GP):
  * Last payout: $XXX (date)
  * Accruing this week: $XXX
* 21% prize match:
  * Total paid lifetime: $XXX,XXX (no cap)
* Permanent tier floors:
  * VIP: 210 tins
  * High Roller: 2,100 tins
  * Whale: 21,000 tins (for life)
* Wholesale program:
  * Active accounts: X
  * Chips issued: X
  * Comps awarded: X
  * Total comp value: $XXX,XXX
* Partner treasuries:
  * Affiliate treasury: Balance, address, verify
  * Wholesale treasury: Balance, address, verify
* Partner activity feed: Real-time affiliate/wholesale events

**Systems Tab** — `GET /insights/systems`

* **Comp budget health:** *(NEW — formalized)*
  * Utilization: Percentage of GP allocated to comps
  * Status badge: "On Track" / "Over Budget" / "Warning"
  * Monthly GP vs. comp spend chart
  * Projection: Run-rate at current pace
* **Payout pipeline metrics:** *(NEW)*
  * Queue count: Pending payouts
  * Avg confirmation time: Seconds
  * Success rate: Percentage
  * 24h stats: Total processed, total value
* **Scan velocity:** *(NEW)*
  * Real-time: Scans per minute
  * Peak: Today's peak scans/minute
  * Avg processing time: Milliseconds
  * P95 latency: Milliseconds
* System reconciliation:
  * Last reconciliation: Timestamp
  * Status: Balanced / Discrepancy
* Tier distribution:
  * Standard: X members (%)
  * VIP: X members (%)
  * High Roller: X members (%)
  * Whale: X members (%)
* System uptime: 99.X%
* API response time: XXms avg

**Update Frequencies**

* Live scan counter: Every 1 second (WebSocket)
* Comp pools: Every 5 seconds
* Treasury balances: Every 5 seconds
* Activity feed: Real-time (WebSocket)
* Bank balances (Teller.io): Every 6 hours (cached)
* Other metrics: Every 30 seconds

### **13. Governance & Voting**

**Vote Types**

* **Flavor votes**: New flavor selection (VIP+ eligible)
* **Loyalty votes**: Comp structure changes (High Roller+ eligible)
* **Corporate votes**: Business decisions (Whale only)

**Vote Creation**

* Admin only: Create new votes
* Whale proposals: Whales submit ideas → Admin reviews → Creates official vote
* Fields: Title, description, type, options, duration (default 7 days)
* Tier eligibility: Auto-set based on vote type

**Voting Process**

* Vote displayed in governance channel
* User clicks to view details
* Select option
* Submit vote (one vote per user per ballot)
* Vote stored in database
* Real-time result tracking

**Results**

* Public results: Visible during voting
* Final results: Published at vote close
* Announcement: Posted in global announcements channel
* Livestream: Can pin results to livestream overlay
* Admin can manually close votes early

### **14. Admin Portal**

**Dashboard**

* Key metrics overview:
  * Total users, active users (last 30 days)
  * Today's scans, this week's scans
  * Revenue (today, week, month)
  * Pending orders, fulfilled orders
  * Active affiliates, pending payouts
* Real-time activity feed
* System health status
* Quick actions: Create QR batch, approve wholesale account, start live event

**Treasury Wallet Management** *(NEW)*

* View all pool balances (Member, Affiliate, Wholesale)
* Send USDT from any pool to external address
* **2FA confirmation required** for all outbound transfers
* Transaction history with audit trail
* Balance alerts configuration

**User Management**

* Search: Email, username, wallet address, member_id
* User detail view:
  * Profile info, tier status, scan history, avatar
  * Wallet balance, transaction history
  * Orders, affiliate earnings
  * Social activity, governance votes
* Actions:
  * Edit profile
  * Manually adjust tier
  * Grant comp (override)
  * Suspend/activate account
  * View audit log

**QR Code Management**

* Generate batch: Specify quantity, generate codes
* View batches: List all batches, filter by status
* Export CSV: Download codes for manufacturer
* Import feedback: Upload manufactured codes
* Invalidate codes: Mark unused codes as invalid
* Search: Find specific code, view status/history

**Comp Management**

* View all comps: Filter by type, status, user
* Comp detail: User, amount, trigger, transaction hash
* Manual award: Override system, award comp to user
* Retry failed: Retry failed crypto transfers
* Volume thresholds: View/edit comp unlock thresholds

**Order Management**

* View orders: Filter by status, date range
* Order detail: Items, shipping, payment, fulfillment status
* Actions:
  * Update status
  * Resend to fulfillment
  * Refund (if faulty product)
  * View age verification result

**Affiliate Management**

* View affiliates: Sort by earnings, downline count
* Affiliate detail: Profile, referrals, earnings history
* Payout approval: Review weekly payout batch, approve/reject
* Manual payout: Award affiliate earnings outside regular schedule
* Sunset status: View progress toward 10M threshold

**Wholesale Management**

* View applications: Pending, approved, active accounts
* Application review: View business details, approve/reject
* Account detail: Orders, chips earned, comps awarded
* Manual comp award: Grant discretionary $10K comp

**Social Hub Management**

* Create channel: Name, category, tier restriction
* Edit channel: Modify settings, archive/delete
* Moderate messages: View flagged messages, delete, timeout users
* Pin/unpin messages globally
* View reports: User-reported content, review, take action

**Live Event Management**

* Create event: Schedule, title, description
* Start stream: Connect StreamYard RTMP
* Pin announcements: Overlay text on stream
* View viewers: Real-time count
* Stop stream: End event

**Governance Management**

* View proposals: Whale-submitted proposals
* Create vote: From proposal or new
* Edit vote: Before publishing
* Close vote early: Manual override
* Publish results: Post to announcements

**Analytics**

* Custom date ranges
* Metrics:
  * User growth (signups, active users)
  * Sales (revenue, units sold, AOV)
  * Scans (total, by tier, by time period)
  * Comps (awarded, paid, by type)
  * Affiliates (active, earnings, payouts)
  * Social (messages, active channels, engagement)
  * Treasury (balances, inflows, outflows)
* Export: CSV download for external analysis

**Email Builder**

* Visual drag-and-drop editor
* Templates: Transactional, marketing
* Personalization: Insert user data (name, tier, etc.)
* Preview: Test send
* Send: To segment or individual users

**Settings**

* System settings: Comp unlock thresholds, tier requirements
* Payment settings: Processor config, tax settings
* Integration settings: API keys (Brevo, Oobit, AgeChecker, Teller.io, etc.)
* Security: IP whitelist for admin access, 2FA enforcement
* Notifications: Email/SMS alerts for critical events

**Audit Logs**

* View all admin actions
* Filter: By admin user, action type, date range
* Export: CSV for compliance

### **15. Wholesale Portal**

*Same as v1.0 — See wholesale.blakjaks.com specifications. No changes.*

### **16. Affiliate Portal**

*Same as v1.0 — See affiliate.blakjaks.com specifications. No changes.*


---

## **Security Requirements**

*All security requirements from v1.0 remain in effect. Only additions/changes noted below.*

### **1. Authentication Security**

*(Unchanged from v1.0 — Argon2id, JWT RS256 via KMS, rate limiting, IP blocking)*

### **2. Treasury Security**

*(Unchanged from v1.0 — KMS, multi-sig, velocity monitoring, daily reconciliation)*

**Addition: Admin Treasury Transfers**

* Admin can send USDT from any pool to external address via `POST /admin/treasury/send`
* **Requires 2FA (TOTP) confirmation** for every transfer
* All transfers logged in audit_logs
* Daily transaction limit: Flag >$50K for secondary admin review
* Velocity checks: Alert if >$500K/hour outflows

**Addition: Reconciliation Formalization**

* Schedule: Daily at 5AM UTC (Celery scheduled task)
* Tolerance: ±$10 between database and blockchain
* Status: "Balanced", "Discrepancy", "Pending"
* On discrepancy: Auto-pause payouts, alert admin via email
* Exposed via `GET /insights/systems` for transparency

### **3. API Security**

*(Unchanged from v1.0 — JWT required, rate limiting, CORS, Pydantic validation)*

### **4. Data Encryption**

*(Unchanged from v1.0 — TDE, AES-256, TLS 1.3, HSTS)*

**Addition: Teller Token Encryption**

* Teller access tokens: AES-256-GCM encryption at rest
* Stored in teller_connections table (encrypted field)
* Decrypted only when making Teller API calls
* Teller Connect token exchange: Server-side only

### **5. Infrastructure Security**

*(Unchanged from v1.0 — VPC, firewall, containers, zero-trust)*

### **6. Compliance**

*(Unchanged from v1.0 — PCI DSS, data retention, GDPR/CCPA)*

### **7. Third-Party Security**

*(Unchanged from v1.0 — vendor assessment, key rotation, webhook validation)*

**Addition: Teller.io vendor compliance**

* Teller.io is SOC 2 Type II certified
* Bank credentials never touch BlakJaks servers (handled by Teller Connect)
* Access tokens stored encrypted, rotated on Teller recommendation

### **8. Security Monitoring**

*(Unchanged from v1.0 — real-time alerts, incident response, pen testing)*

### **9. Avatar/Image Security** *(NEW)*

* **Upload validation**: File type check (JPEG, PNG only), max 5MB
* **Malware scanning**: Scan uploaded files before storage
* **Image processing**: Strip EXIF data, resize to standard dimensions (256x256, 512x512)
* **Storage**: Google Cloud Storage bucket `blakjaks-user-avatars`
* **Access**: Public-read via CDN (no authentication needed for display)
* **Rate limiting**: Max 5 avatar uploads per hour per user

---

## **Infrastructure & DevOps**

*All infrastructure from v1.0 remains. Only additions/changes noted below.*

### **1-7. GKE, Database, Blockchain, CI/CD, Monitoring, DR, Scaling**

*(Unchanged from v1.0)*

### **Storage Additions**

**Google Cloud Storage — New Buckets:**

* `blakjaks-user-avatars` — Profile pictures (public-read via CDN)
  * Max file size: 5MB
  * Formats: JPEG, PNG
  * Naming: `avatars/{user_id}/{timestamp}.{ext}`
  * CDN: Cloud CDN for global distribution

**CDN Updates:**

* Add user avatars to CDN caching (Cache-Control: 1 day, stale-while-revalidate)
* HLS stream segments served via CDN

### **TimescaleDB Additions**

* New hypertable: `treasury_snapshots` (hourly balance snapshots)
  * Retention: 90 days for sparkline display
  * Aggregation: Daily rollups kept for 2 years

---

## **Third-Party Integrations**

*All integrations from v1.0 remain. Only additions/changes noted below.*

### **1-9. Brevo, MetaMask, Oobit, Stargate, AgeChecker, Kintsugi, Intercom, Translation, Selery**

*(Unchanged from v1.0)*

### **10. StreamYard (Live Streaming)**

*(Unchanged from v1.0)*

### **11. Giphy (GIF Integration)**

*(Unchanged from v1.0)*

### **12. 7TV (Animated Emotes)** *(NEW)*

**Purpose**: Animated emote sets for social chat, providing Twitch-style emote culture

**Integration**

* API: 7TV REST API (https://7tv.io/docs)
* No SDK required — REST API for emote sets

**Process**

1. Client fetches the global emote set directly: `GET https://7tv.io/v3/emote-sets/global`
2. Client searches the full 7TV database (1.5M+ emotes) via GraphQL: `POST https://7tv.io/v3/gql`
3. No backend proxy required. No API key required. No emote set ID required.
4. Images served directly from 7TV CDN: `cdn.7tv.app/emote/{id}/{size}.webp`
3. Cache emote set locally (Redis, refresh every hour)
4. Client displays emote picker (grid of animated emotes)
5. User selects emote → Message sent with emote code (e.g., `:KEKW:`)
6. Client renders animated emote inline in chat message

**Emote Display**

* Animated: WebP/AVIF animated format (7TV provides multiple formats)
* Size: 32x32 (chat inline), 64x64 (picker)
* Cache: CDN cache emote images (long TTL, rarely change)

**Cost**: Free (7TV is community-driven, open API)

### **13. Teller.io (Bank Balance Transparency)** *(NEW)*

**Purpose**: Read-only access to BlakJaks bank account balances for the Insights transparency dashboard

**Integration**

* API: Teller.io API (https://teller.io/docs/api)
* Auth: mTLS (mutual TLS) using application certificate + private key — no API secret required
* Python: Use `requests` with `cert=(cert_path, key_path)` (mTLS handled natively; no official Python SDK)
* Environment: Production (after Teller approval at https://app.teller.io)

**Setup**

1. Create Teller developer account at https://app.teller.io
2. Generate application certificate + private key in Teller dashboard
3. Store certificate + private key in Google Secret Manager
4. Use Teller Connect (JavaScript widget) in admin portal to connect BlakJaks bank accounts (one-time)
5. Teller Connect returns `access_token` + `enrollment_id` per account — store encrypted in teller_connections table

**Process**

1. Admin connects bank accounts via Teller Connect (admin portal settings)
2. Celery scheduled task: Fetch balances every 6 hours (`teller_balance_sync`)
3. Call Teller API: `GET /accounts/{account_id}/balances` (mTLS authenticated)
4. Store latest balances in treasury_snapshots table
5. Serve via `GET /insights/treasury` (cached, 6-hour refresh)
6. Display "Last Teller sync" timestamp in UI

**Accounts Tracked**

* Operating Account — Day-to-day business funds
* Reserve Account — Emergency reserves
* Comp Pool Account — Funds earmarked for crypto purchases

**Security**

* Read-only access (balance only, no transaction history)
* Access tokens encrypted at rest (AES-256-GCM)
* Bank credentials never touch BlakJaks servers (handled by Teller Connect)
* Teller.io SOC 2 Type II certified
* mTLS ensures mutual authentication on every API call
* Re-authentication: Admin prompted via Teller Connect if enrollment expires

**Cost**: Subscription-based — see https://teller.io/pricing for current rates

**Required for**: Backend API (treasury endpoint), Admin Portal (Teller Connect setup)

---

## **Testing & Quality Assurance**

*All testing from v1.0 remains. Additional test scenarios below.*

### **Additional Test Scenarios (v2.0)**

**Notification Testing**

1. Trigger comp award → Verify notification created
2. Trigger order status change → Verify notification created
3. Test mark as read (single + all)
4. Test unread count accuracy
5. Verify push notification delivery (APNs + FCM)

**Avatar Upload Testing**

1. Upload valid JPEG/PNG → Verify stored in GCS
2. Upload oversized file (>5MB) → Verify rejection
3. Upload invalid file type → Verify rejection
4. Verify avatar_url updated in users table
5. Verify avatar displays in chat messages

**Teller.io Integration Testing**

1. Connect test bank account via Teller Sandbox
2. Verify balance fetch succeeds (GET /accounts/{id}/balances with mTLS)
3. Verify treasury_snapshots table populated
4. Test Teller enrollment expiration → Re-auth flow
5. Verify insights/treasury endpoint returns bank balances

**7TV Emote Testing**

1. Fetch emote set → Verify cached in Redis
2. Send message with emote code → Verify rendered
3. Test emote picker loads correctly
4. Verify animated emotes display in chat

**Insights API Testing**

1. All 6 REST endpoints return valid data
2. WebSocket /insights/live delivers real-time updates
3. Treasury sparkline data covers 90 days
4. Reconciliation status reflects actual DB vs blockchain
5. Scan velocity metrics accurate (compare with Redis counters)

---

## **Deployment Strategy**

*(Unchanged from v1.0 — canary deployment, rollback triggers, database migrations, mobile releases, zero-downtime, monitoring)*

---

## **Agent Orchestration Workflow**

*(Unchanged from v1.0 — same agent types and orchestration patterns)*

**Additional agent responsibilities for v2.0 features:**

* **Backend Agent**: Build Insights API (6 endpoints + WebSocket), Notification system, Teller.io integration, 7TV integration
* **iOS Agent**: Integrate Socket.io-client-swift (instead of Starscream), avatar upload, notification center, translation UI, Giphy/7TV pickers
* **Android Agent**: Same additions as iOS (using platform equivalents)
* **Web Frontend Agent**: Insights dashboard updates (bank balances, scan velocity, payout pipeline), avatar support in chat
* **Integration Agent**: Teller.io setup, 7TV API integration
* **Database Agent**: New tables (notifications, live_streams, treasury_snapshots, teller_connections, social_message_reactions), new indexes, Redis sorted sets for scan velocity

---

## **Development Phases**

*(Same phase structure as v1.0 with the following additions integrated into existing phases)*

**Integrated into Phase 2 (Core Backend):**

* Member ID generation logic
* Notification system (CRUD + triggers)

**Integrated into Phase 4 (Mobile Apps):**

* Avatar upload + display
* Notification center UI
* Socket.io client (not raw WebSocket)
* Giphy + 7TV emote pickers
* Translation UI (flag icon, tap to translate)
* Rich scan response handling

**Integrated into Phase 5 (Web Frontend):**

* Updated Insights dashboard (Teller.io balances, scan velocity, payout pipeline, reconciliation)
* Avatar support in social hub
* 7TV emote rendering

**Integrated into Phase 6 (Integrations):**

* Teller Connect setup + balance fetching
* 7TV API integration
* Treasury snapshot Celery jobs (Teller.io balance sync)

---

## **Environment Variables & Secrets**

*All environment variables from v1.0 remain. Additional variables below.*

### **New Variables (v2.0)**

```shell
# Teller.io Integration
TELLER_APPLICATION_ID=<teller_application_id>
TELLER_CERT_PATH=/secrets/teller_cert.pem
TELLER_PRIVATE_KEY_PATH=/secrets/teller_private_key.pem
TELLER_ENV=production  # sandbox | production
TELLER_WEBHOOK_SECRET=<teller_webhook_secret>

# 7TV Emotes
SEVENTV_EMOTE_SET_ID=<emote_set_id>
SEVENTV_API_BASE_URL=https://7tv.io/v3

# Avatar Storage
STORAGE_GCS_USER_AVATARS_BUCKET=blakjaks-user-avatars
AVATAR_MAX_SIZE_MB=5
AVATAR_CDN_BASE_URL=https://cdn.blakjaks.com/avatars

# Notifications
APNS_KEY_ID=<apple_key_id>
APNS_TEAM_ID=<apple_team_id>
APNS_BUNDLE_ID=com.blakjaks.app
APNS_KEY_PATH=/secrets/apns_key.p8
APNS_ENVIRONMENT=production
FCM_PROJECT_ID=blakjaks-android
FCM_SERVICE_ACCOUNT_PATH=/secrets/fcm_service_account.json
FCM_SERVER_KEY=<fcm_server_key>
FCM_PACKAGE_NAME=com.blakjaks.app

# Insights
INSIGHTS_TREASURY_SNAPSHOT_INTERVAL=3600  # seconds (1 hour)
INSIGHTS_TELLER_SYNC_INTERVAL=21600  # seconds (6 hours)
INSIGHTS_RECONCILIATION_HOUR=5  # UTC hour for daily reconciliation
INSIGHTS_RECONCILIATION_TOLERANCE=10.00  # USD tolerance
```

**Where to get:**

* Teller.io: https://app.teller.io (generate certificate + private key in dashboard)
* 7TV: https://7tv.io (create emote set in dashboard)
* APNs: Apple Developer Portal → Keys
* FCM: Google Cloud Console → Firebase project

---

## **Success Metrics**

**Technical Metrics:**

* API uptime: >99.9%
* API response time: <500ms p95
* Scan processing: <3s end-to-end
* Crypto payout success rate: >99%
* Mobile app crash rate: <1%
* Test coverage: >80%
* WebSocket latency: <100ms

**Business Metrics:**

* User signups: Track daily
* Scans per day: Track and display on transparency dashboard
* Comp payouts: Track total USDT distributed
* Order conversion rate: Cart → order
* Affiliate signups: Track referral conversions
* Social engagement: Messages per day

**User Experience:**

* App Store rating: Target 4.5+ stars
* Google Play rating: Target 4.5+ stars
* Support ticket volume: Monitor, reduce with FAQs
* User retention: 30-day, 90-day retention rates

---

## **Conclusion**

This execution plan (v2.0) provides a comprehensive, aligned blueprint for Claude Code and its AI agents to build the entire BlakJaks platform. All contradictions between the original platform spec and iOS design brief have been resolved, and new features (notifications, Teller.io, 7TV emotes, avatars) have been integrated.

**Key Changes in v2.0:**

1. **Formal REST API contract** — Every endpoint documented with method, path, auth requirement
2. **Rich scan response** — Backend returns full tier progress + comp details on every scan
3. **Insights API** — 6 REST endpoints + WebSocket for real-time transparency dashboard
4. **Teller.io integration** — Bank account balances for transparency
5. **7TV emotes** — Animated emotes in chat alongside Giphy GIFs
6. **User avatars** — Profile pictures in profile and chat
7. **Notifications** — In-app + push notification system
8. **12mg strength** — Fourth product strength added
9. **$2.99 flat shipping** — Free over $50+

*This document serves as the single source of truth for the BlakJaks platform development. All agents should refer to this plan for requirements, architecture decisions, and implementation details.*

**End of Execution Plan v2.0**

