# BlakJaks Platform — Claude Code Orchestration Guide

**Version:** 3.0 | **Date:** February 19, 2026 | **Owner:** Joshua Dunn
**Status:** Active Build Guide | CONFIDENTIAL — BlakJaks LLC

---

## HOW TO USE THIS GUIDE

This is the master instruction set for Claude Code to build out the BlakJaks platform. Joshua will prompt Claude Code with a specific **Phase** to begin. Claude Code then works through every task in that phase sequentially and automatically — it does not stop between tasks unless a dependency is unmet.

### Claude Code Operating Rules

1. **Joshua prompts a Phase. Claude Code executes all tasks in that phase in order, automatically.**
2. **If a dependency is unmet on any task, stop and output a Dependency Briefing.** Wait for Joshua's instruction before proceeding.
3. **Update status markers in this file** as work progresses: `[PENDING]` → `[IN PROGRESS]` → `[COMPLETE]`.
4. **Always read the referenced documentation sections** before writing code for a task.
5. **Write unit tests at the end of each task** before marking it complete.
6. **When all tasks in a phase are complete,** output a Phase Summary and stop. Wait for Joshua to prompt the next phase.
7. **Never hallucinate API contracts, schema, or business logic.** If the spec is unclear, flag it and stop.

### Status Marker Format

Use these markers in each task header:

- `[PENDING]` — Not yet started
- `[IN PROGRESS]` — Currently being worked on
- `[COMPLETE]` — Done and tested
- `[BLOCKED]` — Dependency unmet — waiting on Joshua

### Dependency Briefing Format

When a dependency is unmet, Claude Code outputs this and stops:

```
⛔ DEPENDENCY NOT MET — Cannot start [Task Name]

BLOCKED BY: [Dependency task name]
WHAT IT PROVIDES: [One sentence — what the dependency gives this task]
WHY THIS TASK NEEDS IT: [One sentence — what breaks without it]
SUGGESTED RESOLUTION: [Can an agent handle it? Or does it require manual action (GCP, Apple Developer, API key)?]
READY TO PROCEED WHEN: [Specific condition that unblocks this task]
```

### Phase Summary Format

After completing all tasks in a phase:

```
✅ PHASE [X] COMPLETE

Tasks completed: [list]
Files created: [list]
Files modified: [list]
Tests written: [count]
Notes / Issues: [anything Joshua should know]

Ready for: Phase [next] — awaiting your prompt.
```

---

## Reference Document Index

All documents are in Claude Code's project knowledge. Use exact section headers to locate content.

| Alias | Document |
|---|---|
| **Platform v2** | `BlakJaks_PLATFORM_v2.md` |
| **Env Vars Ref** | `BlakJaks_Environment_Variables_Reference_v2.md` |
| **iOS Strategy** | `BlakJaks_iOS_Master_Strategy_and_Design_Brief_v5.md` |
| **Stargate Docs** | `Stargate_Documentation.md` |
| **Web3py Docs** | `Web3py_Documentation.md` |
| **MetaMask iOS Docs** | `Metamask_IOS_Documentation.md` |
| **MetaMask Android Docs** | `Metamask_Android_Documentation.md` |
| **Teller Docs** | `Teller_Documentation.md` |
| **Socket Docs** | `Socket_Documentation.md` |
| **Socket Java Docs** | `Socket_java_Documentation.md` |
| **Alamofire Docs** | `Alamofire_Documentation.md` |
| **Keychain Docs** | `Keychain_Documentation.md` |
| **SDWebImage Docs** | `SDwebimageSwiftUI_Documentation.md` |
| **AVFoundation Docs** | `AVFoundation_Documentation.md` |
| **AVPlayer Docs** | `AVPlayer_Documentation.md` |
| **AgeChecker Docs** | `Agechecker_Documentation.md` |
| **Oobit Docs** | `Oobit_Documentation.md` |
| **SevenTV Docs** | `SevenTV_Documentation.md` |
| **OpenAI Moderation Docs** | `openAI_Moderation_Documentation.md` |
| **Alembic Docs** | `Alembic_Documentation.md` |
| **FastAPI Docs** | `FastAPI_Documentation.md` |

---

## Repository Structure

```
blakjaks-platform/
├── backend/
│   ├── app/
│   │   ├── core/           ← config.py, security.py, database.py
│   │   ├── models/         ← SQLAlchemy ORM models
│   │   ├── routers/        ← FastAPI route handlers
│   │   ├── services/       ← Business logic layer
│   │   ├── tasks/          ← Celery task files
│   │   └── main.py
│   ├── migrations/         ← Alembic migration files
│   ├── tests/
│   └── pyproject.toml
├── web-app/src/
│   ├── app/                ← Next.js App Router pages
│   ├── components/
│   └── lib/                ← api.ts, auth-context.tsx, stores
├── affiliate/src/
├── wholesale/src/
├── admin/src/
├── ios/                    ← iOS app (to be created in Phase I)
├── infrastructure/         ← Dockerfiles, GKE manifests
├── .github/workflows/
└── docker-compose.yml      ← To be created in Phase C
```

---

# PHASE A — IMMEDIATE FIXES
*No dependencies. Code edits to the existing repo. Auto-continue through all tasks.*

---

### Task A1 — Security Corrections `[COMPLETE]`

**Objective:** Replace bcrypt with Argon2id for password hashing, and fix JWT token expiry values to match spec. Both are spec violations that must be corrected before any other auth work.

**Files to modify:**
- `backend/app/core/security.py` — replace bcrypt with Argon2id via passlib
- `backend/app/core/config.py` — `ACCESS_TOKEN_EXPIRE_MINUTES` → 15, `REFRESH_TOKEN_EXPIRE_DAYS` → 30
- `backend/pyproject.toml` — add `argon2-cffi>=21.3.0`

**Doc references:**
- Platform v2 § "API Security" — JWT expiry requirements
- FastAPI Docs § "Security" — password hashing patterns

**Tests:** Verify Argon2id hash prefix (`$argon2id$`), verify correct password accepts, wrong password rejects, existing bcrypt hashes migrate via passlib `deprecated="auto"`.

---

### Task A2 — Environment Configuration `[COMPLETE]`

**Objective:** `config.py` covers ~30% of the variables defined in Env Vars Ref. Add all missing variables grouped by service so downstream services can be configured without code changes.

**Files to modify:**
- `backend/app/core/config.py` — add all missing fields (see below for groups)
- `backend/.env.example` — add every variable with placeholder value and "Where to get:" comment
- `backend/pyproject.toml` — add `redis>=5.0.0`, `celery>=5.3.0`, `httpx>=0.26.0`

**Missing variable groups to add:**
- Redis: `REDIS_URL`, `REDIS_CLUSTER_ENABLED`, `REDIS_SSL_ENABLED`
- GCS (additional buckets): `GCS_BUCKET_AVATARS`, `GCS_BUCKET_ASSETS`, `GCS_BUCKET_QR`, `GCS_PROJECT_ID`
- Teller.io: `TELLER_CERT_PATH`, `TELLER_KEY_PATH`, `TELLER_ENV`, `TELLER_ACCOUNT_IDS`
- OpenAI: `OPENAI_API_KEY` (already used in image_moderation.py but not in config)
- 7TV / Giphy: `SEVEN_TV_EMOTE_SET_ID`, `GIPHY_API_KEY`
- APNs (iOS — native, no Firebase): `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_BUNDLE_ID`, `APNS_CERT_PATH`
- FCM (Android only): `FCM_SERVER_KEY`
- Blockchain: `POLYGON_CHAIN_ID`, `BLOCKCHAIN_POLYGON_NODE_URL`, `BLOCKCHAIN_POLYGON_NODE_WS_URL`, `BLOCKCHAIN_MEMBER_TREASURY_ADDRESS`, `BLOCKCHAIN_AFFILIATE_TREASURY_ADDRESS`, `BLOCKCHAIN_WHOLESALE_TREASURY_ADDRESS`
- Third-party: `STREAMYARD_API_KEY`, `SELERY_API_KEY`
- Celery: `CELERY_BROKER_URL`, `CELERY_RESULT_BACKEND`
- Sentry: `SENTRY_DSN`, `SENTRY_ENVIRONMENT`, `SENTRY_RELEASE`, `SENTRY_TRACES_SAMPLE_RATE`
- Intercom: `INTERCOM_APP_ID`, `INTERCOM_API_KEY`, `INTERCOM_IDENTITY_VERIFICATION_SECRET`, `INTERCOM_IOS_API_KEY`, `INTERCOM_ANDROID_API_KEY`
- Google Cloud Translation: `TRANSLATION_GOOGLE_PROJECT_ID`, `TRANSLATION_GOOGLE_CREDENTIALS_PATH`, `TRANSLATION_ENABLED`, `TRANSLATION_SUPPORTED_LANGUAGES`, `TRANSLATION_CACHE_TTL`
- Google Analytics: `GA4_MEASUREMENT_ID`
- Google Cloud KMS: `GCP_KMS_KEY_RING`, `GCP_KMS_KEY_NAME`, `GCP_KMS_LOCATION`, `GCP_PROJECT_ID`
- Kintsugi (tax): `KINTSUGI_API_KEY`, `KINTSUGI_API_URL`
- Payment processor (**Authorize.net — confirmed**): all 5 credentials stored in GCP Secret Manager (`blakjaks-production`):
  - `payment-authorize-api-login-id` — API Login ID
  - `payment-authorize-transaction-key` — Transaction Key
  - `payment-authorize-public-client-key` — Public Client Key (Accept.js / hosted form)
  - `payment-authorize-signature-key` — Signature Key (webhook HMAC-SHA512 validation)
  - `payment-authorize-env` — `sandbox` (flip to `production` at go-live via `gcloud secrets versions add`)

**Doc references:**
- Env Vars Ref — read the complete document. Every section maps to a variable group above.

**Tests:** `Settings()` loads with all fields defaulting correctly, reads from env vars correctly.

---

### Task A3 — CI/CD Corrections `[COMPLETE]`

**Objective:** CI currently builds and deploys without running tests. A broken backend ships silently. Add pytest to the pipeline and a PR test gate.

**Files to modify/create:**
- `.github/workflows/deploy.yml` — add backend test job that runs before Docker build; make deploy depend on test passing
- `.github/workflows/test.yml` — new file; runs pytest on every PR to `main` and `staging`; blocks merge on failure

**Additional:** Create `docs/github-secrets.md` listing every credential that must be added to GitHub Secrets for CI/CD. Documentation only — actual secrets added manually.

**Doc references:**
- Env Vars Ref § "Environment-Specific Variables" — which vars go in which environment

**Tests:** Confirm that intentionally broken Python code in a test PR causes the test job to fail and block the deploy job.

---

# PHASE B — DATABASE CORRECTIONS
*⚡ Requires: Task A2 complete (config vars), PostgreSQL with TimescaleDB extension running*

---

### Task B1 — Restore Multiplier Columns `[COMPLETE]`

**Dependency check:** Verify `backend/migrations/versions/002_*.py` contains the `ALTER TABLE` that removed `multiplier` from `tiers` and `tier_multiplier` from `scans`. If migration 002 does NOT contain this removal, flag it and stop.

**Objective:** Migration 002 incorrectly removed `multiplier` from `tiers` and `tier_multiplier` from `scans`. Without these columns, `usdt_earned` is always zero — the entire earn system is broken.

**Files to create:**
- `backend/migrations/versions/012_restore_multipliers.py` — Alembic migration that re-adds both columns and seeds correct multiplier values: Standard 1.0x, VIP 1.5x, High Roller 2.0x, Whale 3.0x

**Files to modify:**
- `backend/app/models/tier.py` — add `multiplier` field to ORM model
- `backend/app/models/scan.py` — add `tier_multiplier` field to ORM model

**Doc references:**
- Alembic Docs — migration file conventions
- Platform v2 § "Tier System" — multiplier values per tier

**Tests:** All 4 tiers have correct multiplier values post-migration. `scans` table accepts `tier_multiplier` values.

---

### Task B2 — New Table Migrations `[COMPLETE]`

**Dependency check:** Task B1 must be complete.

**Objective:** Six table groups required by Platform v2 spec are missing. Create Alembic migrations for each.

**Files to create (one migration per table group):**
- `013_transparency_metrics.py` — TimescaleDB hypertable; columns: timestamp, metric_type, metric_value, metadata; 2-year retention
- `014_treasury_snapshots.py` — TimescaleDB hypertable; columns: timestamp, pool_type, onchain_balance, bank_balance, metadata; 90-day retention with daily rollups kept 2 years
- `015_teller_accounts.py` — columns per Platform v2 § "teller_connections" schema; seed 3 rows: Operating, Reserve, Comp Pool (no credentials yet)
- `016_live_streams.py` — columns per Platform v2 § "live_streams" schema
- `017_tier_history.py` — columns: id, user_id, quarter, tier_name, scan_count, achieved_at, expires_at, is_permanent
- `018_audit_logs.py` — columns per Platform v2 § "audit_logs" schema
- `019_020_wholesale.py` — create `wholesale_accounts` and `wholesale_orders` only if they don't already exist; check first
- `021_governance.py` — create `governance_votes` and `governance_ballots` tables per Platform v2 § "Database Schema — Governance"; `governance_votes` columns: id, title, description, vote_type (flavor/loyalty/corporate), tier_eligibility (vip/high_roller/whale), options (JSONB array), status (draft/active/closed), created_by_admin, voting_ends_at, results_published
- `022_social_reactions.py` — create `social_message_reactions` table; columns: id, message_id, user_id, emoji (Unicode), created_at; UNIQUE(message_id, user_id, emoji)
- `023_social_translations.py` — create `social_message_translations` table; columns: id, message_id, language (VARCHAR 5), translated_text (TEXT), translated_at; UNIQUE(message_id, language)

**Files to create (ORM models):**
- `backend/app/models/transparency_metric.py`
- `backend/app/models/treasury_snapshot.py`
- `backend/app/models/teller_account.py`
- `backend/app/models/live_stream.py`
- `backend/app/models/tier_history.py`
- `backend/app/models/audit_log.py`
- `backend/app/models/wholesale_account.py` (if not already exists)
- `backend/app/models/wholesale_order.py` (if not already exists)
- `backend/app/models/governance_vote.py`
- `backend/app/models/governance_ballot.py`
- `backend/app/models/social_message_reaction.py`
- `backend/app/models/social_message_translation.py`

Register all new models in `backend/app/models/__init__.py`.

**Doc references:**
- Platform v2 § "Database Schema" — exact column definitions for every table above
- Alembic Docs — hypertable creation via `op.execute()` pattern

**Tests:** All tables exist post-migration. TimescaleDB hypertables created (or gracefully skip if extension absent). 3 seed rows in `teller_accounts`.

---

### Task B3 — Redis Key Schema `[COMPLETE]`

**Dependency check:** None — this is a constants-only file.
No live Redis connection required.

**Objective:** Define all Redis key patterns in a single constants file. No service should ever hardcode a Redis key string.

**Files to create:**
- `backend/app/services/redis_keys.py` — defines all key patterns and TTL constants as functions/constants

**Key patterns to define:**
- `GLOBAL_SCAN_COUNTER` — global scan total
- `leaderboard_monthly(year_month)` — function returning monthly leaderboard key
- `LEADERBOARD_ALL_TIME` — all-time leaderboard
- `SCAN_VELOCITY_MINUTE` / `SCAN_VELOCITY_HOUR` — sliding window counters
- `unread_notifications(user_id)` — per-user unread count
- `emote_set_cache(set_id)` — 7TV emote cache key
- TTL constants for each cached key type

**Tests:** Verify key functions return expected string patterns.

---

# PHASE C — INFRASTRUCTURE
*⚡ Requires: Task A2 complete*

> **Infrastructure Audit Note — Read before starting any Phase C task:**
> The following GCP infrastructure already exists and must NOT be reprovisioned:
> - **GKE Cluster:** `blakjaks-primary` (Autopilot, us-central1) — RUNNING
> - **PostgreSQL:** `blakjaks-db` (PostgreSQL 18.2, Cloud SQL) — IP: 10.96.112.3 (private)
> - **Redis:** `blakjaks-redis` (Redis 7.2, Cloud Memorystore) — IP: 10.96.113.3:6379
> - **Namespaces:** default, development, staging, production — all exist
> - **All GCS buckets** — fully provisioned including blakjaks-user-avatars and blakjaks-backups
> - **All Secret Manager secrets** — fully populated including treasury wallet addresses
>
> **C1 agents:** Do not provision Redis. Create docker-compose.yml with local Redis for
> local dev only. Create redis_client.py pointing at `settings.REDIS_URL`
> (which maps to the Memorystore instance in GKE environments).
>
> **C2 agents:** Infura credentials are in Secret Manager as `infura-api-key`.
> No node provisioning required.

---

### Task C1 — Redis Setup `[COMPLETE]`

**Dependency check:** Task A2 must be complete (`REDIS_URL` in config).

**Objective:** Redis is completely absent from the repository. Required for leaderboards, scan velocity, global counter, notification counts, and emote caching. This task provisions Redis locally and creates the application client singleton.

**Files to create:**
- `docker-compose.yml` (repo root) — services: postgres (timescale/timescaledb:latest-pg15), redis (redis:7-alpine), backend (hot-reload mount), celery-worker, celery-beat
- `backend/app/services/redis_client.py` — async Redis singleton using `redis.asyncio`; startup/shutdown hooks wired to FastAPI lifespan in `main.py`

**Tests:** Redis ping succeeds on startup. Singleton returns same instance on repeated calls.

---

### Task C2 — Polygon RPC Configuration (Infura) `[COMPLETE]`

**Dependency check:** Task A2 complete (blockchain env vars in config).

**Objective:** Configure the backend to use Infura as the Polygon RPC provider. The repo currently has blockchain.py with hardcoded or placeholder RPC values. Update to use `settings.BLOCKCHAIN_POLYGON_NODE_URL` (pointed at Infura) and load treasury addresses from config. A self-hosted Geth node is a future infrastructure upgrade — Infura is the provider for now.

**No GKE provisioning required. No Dockerfile required.**

**Files to modify:**
- `backend/app/core/config.py` — confirm `BLOCKCHAIN_POLYGON_NODE_URL` and `BLOCKCHAIN_POLYGON_NODE_WS_URL` accept Infura endpoint format (`https://polygon-mumbai.infura.io/v3/{key}`)
- `backend/app/services/blockchain.py` — set Web3 HTTP provider from `settings.BLOCKCHAIN_POLYGON_NODE_URL`; set WebSocket provider from `settings.BLOCKCHAIN_POLYGON_NODE_WS_URL`; load all 3 treasury addresses from config (not hardcoded); add `get_node_health()` returning connected status, block number, syncing state (works identically whether provider is Infura or self-hosted)
- `backend/.env.example` — update `BLOCKCHAIN_POLYGON_NODE_URL` comment to show Infura URL format with "Where to get: infura.io → Create Project → Polygon endpoint"

**Infura setup required before this runs:**
- Create a free Infura account at infura.io
- Create a project, enable Polygon network
- Copy the HTTPS and WebSocket endpoints into `BLOCKCHAIN_POLYGON_NODE_URL` and `BLOCKCHAIN_POLYGON_NODE_WS_URL`

> If Infura credentials not set: "BLOCKCHAIN_POLYGON_NODE_URL is blank. Create an Infura project at infura.io and set the Polygon Mumbai (testnet) endpoint. Claude Code can update blockchain.py now, but connection will fail at runtime without credentials."

**Doc references:**
- Web3py Docs — HTTP and WebSocket provider initialization
- Platform v2 § "Treasury Management" — treasury address configuration

**Tests:** `get_node_health()` returns correct dict shape (mock the Web3 connection). Treasury addresses load from config. Provider initializes without error when URL is set.

---

### Task C3 — Celery Infrastructure `[COMPLETE]`

**Dependency check:** Task C1 complete (Redis as broker).

**Objective:** Celery is completely absent. Four scheduled background jobs require it: treasury snapshots (hourly), Teller sync (every 6h), affiliate payout (weekly Sunday), guaranteed comp batch (monthly 1st).

**Files to create:**
- `backend/app/celery_app.py` — Celery app with Redis broker/backend; 5 beat schedule entries: treasury snapshot (hourly), Teller sync (every 6h), affiliate payout (Sunday 3AM UTC), guaranteed comps (1st of month 2AM UTC), leaderboard reconciliation (daily midnight UTC)
- `backend/app/tasks/treasury.py` — stub tasks: `take_treasury_snapshot()`, `reconcile_leaderboard()`
- `backend/app/tasks/teller.py` — stub task: `sync_teller_balances()`
- `backend/app/tasks/affiliate.py` — stub task: `run_weekly_affiliate_payout()`
- `backend/app/tasks/comps.py` — stub task: `run_monthly_guaranteed_comps()`
- `infrastructure/celery/Dockerfile` — worker container (CMD: `celery worker`)
- `infrastructure/celery/Dockerfile.beat` — beat container (CMD: `celery beat`)

Update `docker-compose.yml` to add `celery-worker` and `celery-beat` services.

Stubs should log that they ran and return a status dict. Real logic is wired in Phase D.

**Tests:** `celery_app` imports cleanly. All 5 beat entries present. Task files import cleanly.

---

### Task C4 — Local Development Environment `[COMPLETE]`

**Dependency check:** Task A2 complete, Task C1 complete (docker-compose started there).

**Objective:** Complete the local dev setup so any developer can run the full stack with one command.

**Files to create:**
- `.env.local.example` — safe local defaults (local postgres, local redis, blank third-party keys with instructions)
- `README.md` — prerequisites, `cp .env.local.example .env` → fill in → `docker-compose up`, run migrations, run tests

**Tests:** `docker-compose up && alembic upgrade head` runs cleanly end-to-end.

---

### Task C5 — Sentry + Monitoring Setup `[COMPLETE]`

**Dependency check:** Task A2 complete (Sentry, Prometheus, Grafana env vars), Task C1 complete (docker-compose exists).

**Objective:** The platform has zero error tracking or observability infrastructure. Sentry, Prometheus, Grafana, and AlertManager are all required by Platform v2 spec but absent from the repo. Without these, production issues are invisible.

**Files to create:**
- `infrastructure/monitoring/prometheus.yml` — Prometheus scrape config targeting FastAPI `/metrics`, Celery worker, Postgres exporter, Redis exporter
- `infrastructure/monitoring/grafana/` — datasource config pointing to Prometheus; placeholder dashboard JSON for: API latency, error rates, scan velocity, DB connections, Redis memory
- `infrastructure/monitoring/alertmanager.yml` — alert rules for: API error rate >1%, Celery queue depth >100, DB connection pool exhausted, Redis memory >80%

**Files to modify:**
- `docker-compose.yml` — add prometheus, grafana, alertmanager services
- `backend/app/main.py` — instrument with `prometheus-fastapi-instrumentator`; expose `/metrics` endpoint
- `backend/app/core/config.py` — Sentry init using `SENTRY_DSN` on app startup; set environment, release, traces_sample_rate from config
- `backend/pyproject.toml` — add `sentry-sdk[fastapi]>=1.40.0`, `prometheus-fastapi-instrumentator>=6.1.0`

**Doc references:**
- Env Vars Ref § "Monitoring & Logging" — Sentry, Prometheus, Grafana config values

**Tests:** `/metrics` endpoint returns Prometheus-formatted text. Sentry init does not crash on startup with blank DSN (dev mode). Alertmanager config parses cleanly.
*⚡ Requires: Phase B complete (migrations applied), Phase C complete (Redis and Celery running)*

---

### Task D1 — Redis Service `[COMPLETE]`

**Dependency check:** Task C1 (Redis running), Task B3 (`redis_keys.py` defined).

**Objective:** Application-level Redis service. All services that need Redis call functions from here — never touch the client directly.

**Files to create:**
- `backend/app/services/redis_service.py` — implements: `increment_global_scan_counter()`, `get_global_scan_count()`, `update_leaderboard(user_id, delta)`, `get_leaderboard(type, limit)`, `get_user_rank(user_id, type)`, `track_scan_velocity()`, `get_scan_velocity()`, `get_unread_count(user_id)`, `increment_unread(user_id)`, `clear_unread(user_id)`, `cache_emote_set(set_id, data)`, `get_cached_emote_set(set_id)`

All functions use `redis_keys.py` constants — zero hardcoded key strings.

**Doc references:**
- Platform v2 § "Redis Data Structures" — leaderboard sorted set patterns, velocity windows

**Tests:** Use `fakeredis[aioredis]` for all unit tests. Test each function's behavior (increment, sorting, TTL, round-trip cache).

---

### Task D2 — Teller.io Bank Sync Service `[COMPLETE]`

**Dependency check:**
- Task C3 complete (Celery running)
- Task B2 complete (`teller_accounts` table exists)
- Task A2 complete (Teller env vars configured)
- Physical Teller mTLS cert + key files present

> If Teller credentials not obtained: "Teller.io uses mTLS — a client TLS certificate and private key issued by Teller. Log in to teller.io, download the certificate bundle from your application settings. Set TELLER_CERT_PATH and TELLER_KEY_PATH. Claude Code can build the service now, but real sync requires credentials."

**Objective:** Sync bank balances for 3 accounts (Operating, Reserve, Comp Pool) from Teller.io every 6 hours. Write results to `teller_accounts` and `treasury_snapshots` tables.

**Files to create:**
- `backend/app/services/teller_service.py` — `get_account_balance(teller_account_id)` via mTLS httpx client; `sync_all_balances(db)` iterates all 3 accounts, writes to both tables; `get_last_sync_status(db)` returns current balance + last sync time per account

**Files to modify:**
- `backend/app/tasks/teller.py` — wire stub to real `sync_all_balances()`

**Doc references:**
- Teller Docs — mTLS authentication, `GET /accounts/{id}/balances` endpoint

**Tests:** Mock httpx responses (no real Teller calls in tests). Failed individual account doesn't abort entire sync.

---

### Task D3 — TimescaleDB Analytics Service `[COMPLETE]`

**Dependency check:** Task C3 (Celery running), Task B2 (hypertables created).

**Objective:** Write and read time-series data for treasury snapshots and transparency metrics. Used by the Insights API for sparkline charts.

**Files to create:**
- `backend/app/services/timescale_service.py` — `write_treasury_snapshot(db, pool_type, onchain_balance, bank_balance)`, `get_treasury_sparkline(db, pool_type, days)`, `write_transparency_metric(db, metric_key, value)`, `get_metric_history(db, metric_key, hours)`

**Files to modify:**
- `backend/app/tasks/treasury.py` — wire `take_treasury_snapshot` stub to call `write_treasury_snapshot()` for all 3 pool types using on-chain balances from `blockchain.py`

**Doc references:**
- Platform v2 § "TimescaleDB" — hypertable write patterns, time_bucket() for sparklines

**Tests:** Write inserts correctly. Sparkline query returns time-bucketed data.

---

### Task D4 — 7TV Emote Service `[SKIP]`

**Dependency check:** Task D1 (Redis service), Task A2 (`SEVEN_TV_EMOTE_SET_ID` configured).

**Objective:** Fetch the BlakJaks 7TV emote set and cache in Redis for 1 hour. Mobile and web clients must fetch from the backend — never directly from 7TV (CORS + caching concerns).

**Files to create:**
- `backend/app/services/emote_service.py` — `fetch_emote_set(set_id)` hits 7TV REST API; `get_emotes()` checks Redis cache first, fetches from 7TV on miss, caches result; returns list of `{id, name, animated, cdn_url_webp, cdn_url_avif}`

**Files to modify:**
- Appropriate router (social or new emotes router) — add `GET /emotes` endpoint calling `get_emotes()`. No auth required.

**Doc references:**
- SevenTV Docs — emote-sets REST endpoint, CDN URL format (`cdn.7tv.app/emote/{id}/4x.webp`)

**Tests:** Mock 7TV API. Verify no second HTTP call on cache hit.

---

### Task D5 — Stargate Finance Bridge Service `[COMPLETE]`

**Dependency check:**
- Task C2 complete (Polygon node running, `blockchain.py` updated)
- Mumbai testnet validated

> If Polygon node (C2) not running: "Stargate bridge transactions must be signed and broadcast via a live Web3 connection. Without the Polygon node, no transactions can be submitted. Complete Task C2 first."

**Objective:** Bridge USDT from Ethereum to Polygon for treasury deposits. Admin-only operation, never user-facing. Uses Bus mode (batched — more gas efficient than Taxi mode).

**Files to create:**
- `backend/app/services/stargate_service.py` — `get_bridge_quote(amount_usdt)` returns fee estimate; `execute_bridge(amount_usdt, destination_address)` builds, signs via KMS, broadcasts, returns tx hash + LayerZero scan URL; `get_bridge_status(tx_hash)` polls LayerZero scan API

**Files to modify:**
- `backend/app/routers/admin.py` — add `POST /admin/treasury/bridge` endpoint; requires admin auth + 2FA; resolves destination pool to treasury wallet address; logs action to `audit_logs`

**Doc references:**
- Stargate Docs — read fully before implementing. Bus vs Taxi mode, `sendToken()` ABI, LayerZero chain IDs, fee quoting
- Web3py Docs — contract interaction, KMS signing pattern

**Tests:** Mock contract calls (no real Ethereum in tests). Admin endpoint rejects without 2FA. Bridge action logs to `audit_logs`.

---

### Task D6 — Live Stream Service `[COMPLETE]`

**Dependency check:** Task B2 complete (`live_streams` table exists).

**Objective:** Backend record-keeping and admin control layer for live streams. StreamYard pushes RTMP to our server; server transcodes to HLS. This service manages stream state and exposes endpoints for admin and client apps.

**Files to create:**
- `backend/app/services/livestream_service.py` — `create_stream()`, `set_stream_live()`, `update_viewer_count()`, `end_stream()`, `get_current_stream()`, `get_schedule()`, `get_archive()`
- `backend/app/routers/streams.py` — public endpoints: `GET /live-streams/current`, `GET /live-streams/schedule`, `GET /live-streams/archive`; admin endpoints: `POST /admin/live-streams`, `PUT /admin/live-streams/{id}/go-live`, `PUT /admin/live-streams/{id}/end`, `PUT /admin/live-streams/{id}/viewer-count`, `DELETE /admin/live-streams/{id}`
- `infrastructure/rtmp/deployment.yaml` — Nginx RTMP module deployment on GKE; RTMP auth webhook calls backend; HLS transcoding to GCS bucket; Cloud CDN delivery at `https://cdn.blakjaks.com/hls/`

Register `streams` router in `main.py`.

**Doc references:**
- Platform v2 § "Live Streaming" — StreamYard architecture, RTMP ingest, HLS delivery

**Tests:** Stream lifecycle state transitions (scheduled → live → ended; invalid transitions rejected). `GET /live-streams/current` returns null when no active stream.

---

### Task D7 — Wholesale Backend System `[COMPLETE]`

**Dependency check:** Task B2 complete (`wholesale_accounts` and `wholesale_orders` tables exist).

**Objective:** The entire wholesale backend is absent. Build from scratch — account management, order flow, chip tracking, and admin controls.

**Files to create:**
- `backend/app/services/wholesale_service.py` — `create_application()`, `approve_account()`, `suspend_account()`, `place_order()` (validates minimums, calculates chips_earned), `get_dashboard()`, `award_comp()` (logs to audit_logs)
- `backend/app/routers/wholesale.py` — partner endpoints: `POST /wholesale/apply`, `GET /wholesale/dashboard`, `GET /wholesale/orders`, `POST /wholesale/orders`, `GET /wholesale/orders/{id}`, `GET /wholesale/chips`; admin endpoints: `GET /admin/wholesale/accounts`, `GET /admin/wholesale/accounts/{id}`, `PUT /admin/wholesale/accounts/{id}/approve`, `PUT /admin/wholesale/accounts/{id}/suspend`, `POST /admin/wholesale/accounts/{id}/award-comp`, `GET /admin/wholesale/orders`

Register `wholesale` router in `main.py`.

**Doc references:**
- Platform v2 § "Wholesale Program" — business rules, minimum order quantities, chip calculation logic, $10K discretionary comp

**Tests:** Application → approval → order → chips earned end-to-end. Minimum order validation rejects undersized orders. Admin comp award logs to `audit_logs`.

---

### Task D8 — Push Notification Service (Real Implementation) `[COMPLETE]`

**Dependency check:** Task A2 complete (APNs + FCM env vars), APNs `.p8` key file present.

> If APNs `.p8` not obtained: "APNs requires a .p8 key file from Apple Developer Portal → Certificates, Identifiers & Profiles → Keys. Download it, set APNS_CERT_PATH. Claude Code can update service code now, but real delivery requires this file."

**Objective:** `push_service.py` currently logs to console instead of sending real notifications. Wire it to real APNs (iOS) and FCM (Android).

**Files to modify:**
- `backend/app/services/push_service.py` — replace console log stubs with real APNs HTTP/2 API calls (using `.p8` JWT auth — NOT legacy binary protocol) for iOS tokens; real FCM API calls for Android tokens. Function signatures unchanged.

**Doc references:**
- Platform v2 § "Push Notifications" — APNs for iOS, FCM for Android only (no Firebase on iOS)

**Tests:** iOS device tokens route to APNs. Android tokens route to FCM. Delivery failures caught and logged, not raised.

---

### Task D9 — Oobit Widget Token Generation `[COMPLETE]`

**Dependency check:** Task A2 (Oobit API key configured), Oobit credentials obtained.

> If Oobit credentials not obtained: "Oobit API credentials are required to generate widget auth tokens. Obtain from Oobit dashboard. Without them, the token endpoint will fail at runtime."

**Objective:** `wallet_service.py` Oobit activation returns a stub/mock. Replace with a real Oobit API call that generates a short-lived widget auth token. Mobile app loads this token into a WKWebView (iOS) / WebView (Android) to show the Oobit card UI.

**Files to modify:**
- `backend/app/services/wallet_service.py` — replace mock with real `POST /v1/widget/auth/create-token` call to Oobit API; return `{token, widget_url, expires_in}`

**Files to modify:**
- Appropriate router — add `POST /oobit/token` endpoint (authenticated user only)

**Doc references:**
- Oobit Docs — widget auth token creation flow, WKWebView integration pattern

**Tests:** Mock Oobit API response. Token endpoint requires auth.

---

### Task D10 — Giphy Service `[COMPLETE]`

**Dependency check:** Task D1 (Redis service), Task A2 (`GIPHY_API_KEY` configured).

**Objective:** The Code Guide covers 7TV emotes (D4) but Giphy GIFs are equally required for the chat media picker. Like 7TV, clients must fetch through the backend — never hit Giphy directly (API key exposure + CORS). Giphy search results are short-lived so caching strategy differs from emotes.

**Files to create:**
- `backend/app/services/giphy_service.py` — `search_gifs(query, limit, offset)` calls Giphy REST API, returns normalized list of `{id, title, url_mp4, url_webp, url_gif, width, height}`; `get_trending(limit)` fetches trending GIFs; results cached in Redis with 5-minute TTL per query string

**Files to modify:**
- Appropriate router — add `GET /gifs/search?q={query}&limit={n}&offset={n}` and `GET /gifs/trending` endpoints. Auth required (rate-limit per user).

**Doc references:**
- Platform v2 § "Social Hub" — GIF picker integration requirements
- Env Vars Ref § "Chat Media" — Giphy config

**Tests:** Mock Giphy API. Cache hit returns same result without second HTTP call. Search with empty query returns 400.

---

### Task D11 — Notification Center REST API `[COMPLETE]`

**Dependency check:** Task B2 complete (`notifications` table exists), Task D8 complete (push service wired).

**Objective:** The notification table exists and push_service.py can deliver notifications, but there are no REST endpoints for clients to fetch, read, or manage their notification inbox. Without these endpoints the web app `/notifications` page (Task F3) and iOS notification center (Task I7) have nothing to call.

**Files to create:**
- `backend/app/services/notification_service.py` — `create_notification(db, user_id, type, title, body, data)`, `get_notifications(db, user_id, type_filter, limit, offset)`, `mark_read(db, notification_id, user_id)`, `mark_all_read(db, user_id)`, `get_unread_count(db, user_id)`, `delete_notification(db, notification_id, user_id)`
- `backend/app/routers/notifications.py` — endpoints: `GET /notifications` (paginated, filterable by type), `POST /notifications/{id}/read`, `POST /notifications/read-all`, `DELETE /notifications/{id}`, `GET /notifications/unread-count`

Register `notifications` router in `main.py`. Notification creation must also call `push_service.send()` and increment Redis unread counter via `redis_service.increment_unread()`.

**Doc references:**
- Platform v2 § "In-App Notifications" — notification types, payload shape, delivery rules

**Tests:** Unread count decrements on read. Mark-all-read sets all to read for that user only. Pagination returns correct page. Creating a notification triggers both push + Redis increment.

---

### Task D12 — Google Cloud Translation Service `[COMPLETE]`

**Dependency check:** Task A2 complete (Translation env vars), Task B2 complete (`social_message_translations` table exists).

**Objective:** Chat messages are stored with their original language. Users tap to translate any message to their preferred language. Translations are cached in the `social_message_translations` table — same message + language never hits the API twice.

**Files to create:**
- `backend/app/services/translation_service.py` — `detect_language(text)` returns ISO language code; `translate_message(db, message_id, target_language)` checks `social_message_translations` table first (cache hit returns immediately), falls back to Google Cloud Translation API, stores result in table; `get_supported_languages()` returns list of enabled language codes from config

**Files to modify:**
- `backend/app/routers/social.py` (or chat router) — add `POST /social/messages/{id}/translate` endpoint with `{target_language}` in body; auth required; returns `{translated_text, source_language, cached}`

**Doc references:**
- Platform v2 § "Social Hub — Chat Translation" — translation flow, caching rules, language detection
- Env Vars Ref § "Translation" — Google Cloud Translation config

**Tests:** Second request for same message+language returns cached result (no API call). Unsupported language returns 400. Source language detected correctly.

---

### Task D13 — Intercom Integration `[COMPLETE]`

**Dependency check:** Task A2 complete (Intercom env vars), Intercom account and API keys obtained.

> If Intercom credentials not obtained: "Intercom credentials are required for live chat support. Log in to Intercom dashboard → Settings → Installation to get APP_ID, API_KEY, and Identity Verification secret. Claude Code can wire the integration now, but the widget will not load until credentials are set."

**Objective:** Intercom provides in-app live chat support. Backend must generate identity verification HMACs so users are authenticated to Intercom. Frontend and mobile embed the Intercom widget.

**Files to create:**
- `backend/app/services/intercom_service.py` — `generate_identity_hash(user_id)` returns HMAC-SHA256 of user_id using `INTERCOM_IDENTITY_VERIFICATION_SECRET`; `create_or_update_user(user)` syncs user data to Intercom on login (name, email, created_at, tier, member_id)

**Files to modify:**
- `backend/app/routers/auth.py` (or users router) — add `GET /intercom/token` endpoint; returns `{app_id, user_id, user_hash}` for client-side Intercom init
- `web-app/src/lib/api.ts` — fetch Intercom token on login, initialize Intercom widget with `window.Intercom('boot', {...})`

**Doc references:**
- Platform v2 § "Third-Party Services — Intercom"
- Env Vars Ref § "Intercom" — all config values

**Tests:** `generate_identity_hash()` produces consistent HMAC for same user_id. Token endpoint requires auth.

---

### Task D14 — Member ID Generation `[COMPLETE]`

**Dependency check:** Task B2 complete (users table exists with `member_id` column).

**Objective:** The Platform v2 spec defines a `BJ-0001-ST` format member ID for every user. The column exists in the users table schema but no generation logic exists anywhere. New members currently have null member IDs, which breaks profile display and tier tracking.

**Files to modify:**
- `backend/app/services/user_service.py` (or wherever user creation lives) — add `generate_member_id(db, user_id, tier)` that: fetches next sequential number from a `member_id_seq` PostgreSQL sequence (not auto-increment — must be consistent across migrations), formats as `BJ-XXXX-{SUFFIX}` where suffix is ST/VIP/HR/WH; add `update_member_id_tier_suffix(db, user_id, new_tier)` called whenever a user's tier changes (number stays, suffix updates)
- `backend/migrations/versions/024_member_id_seq.py` — create `member_id_seq` PostgreSQL sequence starting at 1; add `member_id` VARCHAR(20) UNIQUE column to users table if not present; backfill existing users with sequential IDs

**Doc references:**
- Platform v2 § "Database Schema — Users — Member ID Generation Logic" — exact format and suffix mapping

**Tests:** Generated IDs match `BJ-XXXX-ST` format. Sequential numbers don't collide under concurrent inserts (test with thread pool). Tier suffix updates on tier change, number unchanged.

---

### Task D15 — Avatar Upload Service `[COMPLETE]`

**Dependency check:** Task A2 complete (`GCS_BUCKET_AVATARS` configured), GCS bucket `user-avatars` provisioned.

> If GCS bucket not provisioned: "The user-avatars GCS bucket must exist before this service can write to it. Create it in GCP Console → Cloud Storage → Create Bucket, named per GCS_BUCKET_AVATARS config value. Claude Code can build the service now, but uploads will fail until the bucket exists."

**Objective:** Users can set a profile picture. The `avatar_url` column exists on the users table but no upload endpoint or GCS write logic exists.

**Files to create:**
- `backend/app/services/avatar_service.py` — `upload_avatar(user_id, file_bytes, content_type)` validates file type (JPEG/PNG/WebP only, max 5MB), resizes to 400×400 via Pillow, uploads to GCS at `avatars/{user_id}/avatar.{ext}`, returns CDN URL; `delete_avatar(user_id)` removes from GCS

**Files to modify:**
- Appropriate router — add `POST /users/me/avatar` (multipart upload, auth required) and `DELETE /users/me/avatar`; update `avatar_url` on users table after successful upload
- `backend/pyproject.toml` — add `Pillow>=10.0.0`, `google-cloud-storage>=2.10.0`

**Doc references:**
- Platform v2 § "User Management — Profile" — avatar size, format requirements
- Env Vars Ref § "Cloud Storage" — GCS bucket names, CDN URL pattern

**Tests:** Non-image files rejected. Oversized files rejected. Successful upload returns HTTPS CDN URL. Avatar URL on user record updated.

---

### Task D16 — QR Code Batch Admin System `[COMPLETE]`

**Dependency check:** Task B2 complete (`qr_batches` table exists).

**Objective:** QR codes are generated in batches for physical product manufacturing. The `qr_codes` and `qr_batches` tables exist but there is no admin service or endpoints to generate, track, or export batches. Manufacturing cannot proceed without this.

**Files to create:**
- `backend/app/services/qr_service.py` — `generate_batch(db, name, count, product_sku, manufacturer_name, notes)` generates `count` unique 14-character codes (format: `XXXX-XXXX-XXXX`), stores in `qr_codes` + `qr_batches` tables, returns batch_id; `export_batch_csv(db, batch_id)` returns CSV bytes with columns: code, batch_id, product_sku, status; `get_batch_status(db, batch_id)` returns total/scanned/remaining counts

**Files to modify:**
- `backend/app/routers/admin.py` — add: `POST /admin/qr/batches` (create batch), `GET /admin/qr/batches` (list all batches), `GET /admin/qr/batches/{id}` (batch detail + stats), `GET /admin/qr/batches/{id}/export` (download CSV)

**Doc references:**
- Platform v2 § "QR Code System" — code format, batch workflow, manufacturer export

**Tests:** Generated codes match `XXXX-XXXX-XXXX` format. No duplicate codes across batches. CSV export contains correct column headers. Batch status counts are accurate.

---

### Task D17 — Google Cloud KMS Configuration `[COMPLETE]`

**Dependency check:**
- Task A2 complete (KMS env vars configured)
- GCP KMS key ring and key must be provisioned

> If KMS key ring not provisioned: "Google Cloud KMS requires a key ring and asymmetric signing key to be created in GCP Console → Security → Key Management. Create a key ring named per GCP_KMS_KEY_RING config, then create an asymmetric signing key (ECDSA P-256). Claude Code can write the KMS client code, but signing will fail until the key exists."

**Objective:** `blockchain.py` signs treasury transactions using Cloud KMS but the KMS client is not properly initialized or abstracted. Task D5 (Stargate bridge) and any future admin treasury operations depend on a working KMS client. This task creates the centralized KMS service used by all signing operations.

**Files to create:**
- `backend/app/services/kms_service.py` — `get_kms_client()` initializes GCP KMS client from service account credentials; `sign_transaction(tx_hash_bytes)` signs a 32-byte hash using the configured asymmetric key, returns DER-encoded signature; `get_public_key()` returns the KMS public key for on-chain verification

**Files to modify:**
- `backend/app/services/blockchain.py` — replace any inline KMS calls with `kms_service.sign_transaction()`

**Doc references:**
- Platform v2 § "Blockchain Infrastructure — Key Management"
- Env Vars Ref § "Google Cloud KMS"
- Web3py Docs — transaction signing with external signer

**Tests:** `sign_transaction()` returns bytes of correct length. Mock KMS client in all unit tests — never call real KMS in tests.
*⚡ Requires: Phase D complete (services built and running)*

---

### Task E1 — Scan Submit Enrichment `[COMPLETE]`

**Dependency check:**
- Task B1 complete (`multiplier` restored to `tiers`, `tier_multiplier` on `scans`)
- Task D1 complete (Redis service)

**Objective:** The scan endpoint validates and marks QR codes but `usdt_earned` is always 0, the response is minimal, Redis is not incremented, and comp milestone checks don't run at scan time. Fix all four.

**Files to modify:**
- `backend/app/routers/qr_code.py` (or wherever `POST /scans/submit` lives) — add earn calculation (`base_rate × tier.multiplier`), store `tier_multiplier` on scan record, run comp milestone check post-scan, increment Redis (global counter, velocity), return full rich response

**Rich response shape** (create `ScanResponse` Pydantic model):
- `success`, `product_name`, `usdt_earned`, `tier_multiplier`
- `tier_progress`: `{quarter, current_count, next_tier, scans_required}`
- `comp_earned` (nullable): `{amount, type, lifetime_comps, wallet_balance, gold_chips}`
- `milestone_hit`, `wallet_balance`, `global_scan_count`

**Doc references:**
- Platform v2 § "Scan Flow (Updated — Rich Response)" — exact response field specification

**Tests:** `usdt_earned` correct for all 4 tier multipliers. `tier_multiplier` stored on scan record. Redis counter increments. Comp milestone triggers at $100/$1K/$10K thresholds. Response matches full `ScanResponse` schema.

---

### Task E2 — Insights API `[COMPLETE]`

**Dependency check:**
- Task D1 complete (Redis — scan velocity, global counter)
- Task D2 complete (Teller — bank balances)
- Task D3 complete (TimescaleDB — sparklines)

**Objective:** Build the 6 Insights endpoints and the `/insights/live` WebSocket namespace. These power the Transparency Dashboard on mobile and web — BlakJaks' key differentiator.

**Files to create:**
- `backend/app/services/insights_service.py` — one aggregator function per endpoint, pulling from Redis, Teller, TimescaleDB, and blockchain
- `backend/app/routers/insights.py` — all 6 endpoints (no auth required — public transparency data)

**Endpoints:**
- `GET /insights/overview` — global scan count (Redis), active members, 24h payouts, live activity feed (last 20), next milestone progress bars
- `GET /insights/treasury` — on-chain wallet balances, bank balances (Teller), 90-day sparklines (TimescaleDB), reconciliation status (DB vs blockchain ±$10), payout ledger
- `GET /insights/systems` — comp budget health, payout pipeline queue/success rate, scan velocity (Redis), Polygon node status (`get_node_health()`), Teller last sync, tier distribution counts
- `GET /insights/comps` — prize tier stats ($100/$1K/$10K/$200K trip), milestone progress, $50 guarantee totals, vault economy
- `GET /insights/partners` — affiliate metrics (active count, sunset engine status), weekly pool, 21% match lifetime total, permanent tier floor counts, wholesale stats
- `GET /insights/feed` — paginated activity feed (comp payouts, tier upgrades, new members — last 24h default)

**WebSocket namespace `/insights/live`** (Socket.IO):
- Emit `scan_counter` event on every scan (triggered from scan endpoint)
- Emit `comp_awarded` event when a comp is paid
- Emit `balance_update` event when Celery snapshot job runs

**Doc references:**
- Platform v2 § "Insights API & Transparency System" — exact field specifications for each endpoint
- Socket Docs — python-socketio namespace setup and event emission

**Tests:** Each endpoint returns expected shape (mock service functions). WebSocket namespace emits correct events.

---

### Task E3 — Leaderboard Endpoints `[REMOVED]`

**Decision:** Leaderboard feature removed from scope. The Redis infrastructure (keys, service functions) remains in place for potential future use, but no REST endpoints or reconciliation job will be built. The `reconcile_leaderboard` Celery task remains a stub. Remove leaderboard references from all future phase tasks and the web app pages.

---

### Task E4 — Governance Voting API `[COMPLETE]`

**Dependency check:** Task B2 complete (`governance_votes` and `governance_ballots` tables exist).

**Objective:** Platform v2 spec includes a governance system where VIP+ members vote on flavors, loyalty rules, and corporate decisions. The tables exist but no service or endpoints were built. The iOS Social Hub has a Governance channel category that expects these endpoints.

**Files to create:**
- `backend/app/services/governance_service.py` — `create_vote(db, admin_user_id, title, description, vote_type, tier_eligibility, options, voting_ends_at)`, `cast_ballot(db, vote_id, user_id, selected_option)` validates tier eligibility + one vote per user, `close_vote(db, vote_id, admin_user_id)` tallies results + sets results_published, `get_active_votes(db, user_tier)` returns votes the user is eligible for, `get_vote_results(db, vote_id)` returns tally per option

**Files to create:**
- `backend/app/routers/governance.py` — public endpoints: `GET /governance/votes` (active votes for user's tier), `GET /governance/votes/{id}` (vote detail + user's ballot if cast), `POST /governance/votes/{id}/ballot` (cast ballot — auth required, tier check); admin endpoints: `POST /admin/governance/votes` (create), `PUT /admin/governance/votes/{id}/close` (close + tally), `GET /admin/governance/votes` (all votes including drafts)

Register `governance` router in `main.py`.

**Doc references:**
- Platform v2 § "Governance & Voting" — vote types, tier eligibility rules, ballot constraints
- Platform v2 § "Database Schema — governance_votes, governance_ballots"

**Tests:** User below required tier cannot cast ballot (403). User cannot vote twice on same vote (409). Closing a vote correctly tallies all options. Admin can see draft votes, public cannot.

---

### Task E5 — Social Message Reactions API `[COMPLETE]`

**Dependency check:** Task B2 complete (`social_message_reactions` table exists).

**Objective:** The `social_message_reactions` table exists in the schema but no service or endpoints were built. The iOS and web chat UI spec includes emoji reactions on messages.

**Files to create:**
- `backend/app/services/reaction_service.py` — `add_reaction(db, message_id, user_id, emoji)` enforces UNIQUE(message_id, user_id, emoji) constraint; `remove_reaction(db, message_id, user_id, emoji)`; `get_reactions(db, message_id)` returns grouped counts per emoji with a `reacted_by_me` flag for the requesting user

**Files to modify:**
- `backend/app/routers/social.py` (or chat router) — add: `POST /social/messages/{id}/reactions` with `{emoji}` in body (auth required), `DELETE /social/messages/{id}/reactions/{emoji}` (auth required), `GET /social/messages/{id}/reactions` (public)
- Socket.IO chat namespace — emit `reaction_added` and `reaction_removed` events to the channel room when reactions change, so all connected clients update in real time

**Doc references:**
- Platform v2 § "Social Hub — Reactions"
- Socket Docs — emitting to room

**Tests:** Adding same emoji twice returns 409. Removing non-existent reaction returns 404. `get_reactions()` correctly groups and counts. WebSocket event fires on add and remove.
*⚡ Requires: Phase E endpoints live*

---

### Task F1 — Compliance UI (All Portals) `[PENDING]`

**Dependency check:** None — pure frontend, no backend required.

**Objective:** The always-visible nicotine warning banner and age gate are legally required and absent from all portals. Must be present before any portal goes live.

**Nicotine Warning Banner — Exact Specifications:**
- Appears ONLY on these three pages: shop/product page, cart page, checkout page
- Does NOT appear on any other pages (home, wallet, scans, social, profile, admin, etc.)
- Implemented as a reusable component imported individually into those three pages only — NOT in the root layout
- Height: exactly 20vh (20% of the viewport height) — no more, no less
- Background: black (#000000)
- Text: white, Helvetica Bold (font-family: Helvetica, Arial, sans-serif; font-weight: bold)
- Text must be sized dynamically to fill as much of the banner as possible — use CSS clamp() or a JS text-fit solution to maximize font size within the banner bounds without overflow
- Text content: "WARNING: This product contains nicotine. Nicotine is an addictive chemical."
- Fixed to the top of the viewport (position: fixed, top: 0, z-index: 9999) when present
- Pages that include the banner must offset their content by 20vh (padding-top: 20vh on the page wrapper)

**Files to create/modify:**
- `web-app/src/components/WarningBanner.tsx` — new component per exact specifications above; never dismissible, no close button
- `web-app/src/app/shop/page.tsx` — import and render `<WarningBanner />` at top; add padding-top: 20vh to page wrapper
- `web-app/src/app/cart/page.tsx` — import and render `<WarningBanner />` at top; add padding-top: 20vh to page wrapper
- `web-app/src/app/checkout/page.tsx` — import and render `<WarningBanner />` at top; add padding-top: 20vh to page wrapper
- `web-app/src/components/AgeGate.tsx` — new component; full-screen overlay on first visit; localStorage flag `blakjaks_age_verified`; "Are you 21 or older?" with Yes (set flag, show site) / No (redirect to google.com) buttons
- `web-app/src/app/layout.tsx` — wrap root content in `<AgeGate>`
- `affiliate/src/app/layout.tsx` — add WarningBanner (no age gate — internal tool)
- `wholesale/src/app/layout.tsx` — add WarningBanner (no age gate — internal tool)

**Doc references:**
- Platform v2 § "Compliance & Age Verification"

**Tests:** Banner present on all pages. Age gate blocks content until verified. "No" exits site. Refreshing after "Yes" skips gate.

---

### Task F2 — Web App Real API Client `[PENDING]`

**Dependency check:** Task A1 (auth working), core backend APIs returning real data.

**Objective:** Every method in `api.ts` returns mock data or throws 'Not implemented'. Replace all with real `fetch()` calls. Wire auth context and stores.

**Files to modify:**
- `web-app/src/lib/api.ts` — rewrite all methods with real `fetch()` to backend; add `Authorization: Bearer {token}` header; handle 401 by triggering silent token refresh then retrying
- `web-app/src/lib/auth-context.tsx` — wire `login()`, `signup()`, `logout()` to real `/auth/login`, `/auth/signup`, `/auth/logout`; persist JWT in httpOnly cookie or secure localStorage
- `web-app/src/lib/store.ts` — add `refreshToken()` calling `POST /auth/refresh`; auto-refresh on 401
- `web-app/src/lib/notification-store.ts` — switch from polling to Socket.IO subscription on `/notifications` namespace
- `web-app/src/lib/emote-store.ts` — fetch from backend `GET /emotes` instead of 7TV CDN directly

**Doc references:**
- Platform v2 § "API Endpoints" — all endpoint paths and response contracts

**Tests:** Auth flow works end-to-end against live backend. Token refresh works on 401. Emotes load from backend.

---

### Task F3 — Web App Missing Pages `[PENDING]`

**Dependency check:** Task F2 (API client wired), relevant backend endpoints live.

**Payment processor: Authorize.net (confirmed).** All 5 credentials are in GCP Secret Manager (`blakjaks-production`). Use Accept.js (hosted payment form) for the checkout page — load the public client key from `payment-authorize-public-client-key`. Do not implement Stripe or Square. Environment is `sandbox` until go-live.

Build all other pages (shop, cart, wallet, scans, notifications) while the checkout integration is in progress.

**Objective:** Build 7 pages that exist in the spec but not in the codebase.

**Files to create:**
- `web-app/src/app/shop/page.tsx` — product grid, flavor filter bar, add to cart; calls `GET /shop/products`
- `web-app/src/app/cart/page.tsx` — line items, quantity controls, proceed to checkout; calls `GET /cart`, `PUT /cart/update`, `DELETE /cart/remove`
- `web-app/src/app/checkout/page.tsx` — multi-step: shipping address → AgeChecker.net popup → payment method → review + Kintsugi tax; calls `POST /tax/estimate`, `POST /orders/create`
- `web-app/src/app/wallet/page.tsx` — USDT balance, pending vs available, wallet address with copy, transaction history with filters, withdrawal flow; calls `GET /users/me/wallet`, `GET /wallet/transactions`, `POST /wallet/withdraw`
- `web-app/src/app/scans/page.tsx` — scan history list; calls `GET /scans/history`
- `web-app/src/app/notifications/page.tsx` — full notification list, type filters, mark-all-read; calls `GET /notifications`, `POST /notifications/read-all`

Every page must have loading state, empty state, and error state.

**Doc references:**
- Platform v2 § "Consumer Web App" — page-by-page specs
- AgeChecker Docs — web SDK popup integration for checkout step

**Tests:** Each page renders in loading, empty, and error states. Checkout AgeChecker popup triggers correctly.

---

# PHASE G — ADMIN PORTAL ADDITIONS
*⚡ Requires: Phase E endpoints live*

---

### Task G1 — Admin Insights Tab `[PENDING]`

**Dependency check:** Task E2 (Insights API).

**Objective:** Add system health and performance visibility to the admin portal.

**Files to create:**
- New Insights section in `admin/src/` — panels: System Health (API latency P95, DB connections, Redis memory, Polygon node status), Scan Velocity chart (scans/minute last 60min), Pool Balance sparklines (3 line charts), Comp Budget Health gauge, Payout Pipeline metrics

Data from: `GET /insights/systems`, `GET /insights/treasury`, `GET /insights/comps`

---

### Task G2 — Admin Teller Bank Panel `[PENDING]`

**Dependency check:** Task D2 (Teller service), `GET /treasury/teller` endpoint live.

**Objective:** Show bank account balances and last sync status in admin. Add manual sync trigger.

**Files to modify:**
- Admin portal Treasury page — add Bank Accounts section: 3 account cards (Operating, Reserve, Comp Pool) showing institution, masked account, balance, last sync timestamp; "Re-sync Now" button calling new `POST /admin/treasury/teller-sync` endpoint; Teller Connect setup button for initial enrollment

**Files to modify:**
- `backend/app/routers/admin.py` — add `POST /admin/treasury/teller-sync` endpoint (triggers manual `sync_all_balances()`)

---

### Task G3 — Admin Live Streams Management `[PENDING]`

**Dependency check:** Task D6 (live stream service + endpoints).

**Objective:** Add live stream management to admin portal.

**Files to create:**
- New Live Streams section in admin portal — stream list table (title, status, scheduled date, viewer count, VOD link), "Create Stream" form (title, description, datetime, tier restriction), Go Live / End Stream action buttons, live viewer count display

---

### Task G4 — Admin Wholesale Management `[PENDING]`

**Dependency check:** Task D7 (wholesale backend).

**Objective:** Add wholesale account and order management to admin portal.

**Files to create:**
- New Wholesale section in admin portal — applications queue (Approve/Reject), active accounts list, account detail view, order history per account, "Award Comp" action button ($10K input + confirm)

---

### Task G5 — Admin QR Batch Management `[PENDING]`

**Dependency check:** Task D16 (QR batch service + endpoints).

**Objective:** Add QR code batch generation and export to the admin portal. Manufacturing teams need this to generate and download code sheets for physical product printing.

**Files to create:**
- New QR Codes section in admin portal — "Generate New Batch" form (batch name, code count, product SKU, manufacturer name, notes), batch list table (name, code count, scanned/remaining counts, date generated, export button), batch detail view showing scan rate and individual code status; "Export CSV" button calls `GET /admin/qr/batches/{id}/export` and triggers file download

---

### Task G6 — Admin Governance Management `[PENDING]`

**Dependency check:** Task E4 (Governance API).

**Objective:** Add governance vote creation and management to the admin portal.

**Files to create:**
- New Governance section in admin portal — "Create Vote" form (title, description, vote type, tier eligibility, options as multi-input, end date/time), votes list table (title, status, tier, end date, total ballots cast), vote detail view showing real-time tally per option as bar chart, "Close Vote" button with confirmation, "Publish Results" toggle
*⚡ Requires: Respective backend systems complete*

---

### Task H1 — Affiliate Portal API Wiring `[PENDING]`

**Dependency check:** Task A1 (auth), affiliate backend endpoints returning real data.

**Objective:** All affiliate portal pages have good UI but 100% mock data. Replace every mock return in `api.ts` with real fetch calls.

**Files to modify:**
- `affiliate/src/lib/api.ts` — wire to: `GET /affiliate/dashboard`, `/affiliate/downline`, `/affiliate/chips`, `/affiliate/payouts`, `/affiliate/referral-code`
- `affiliate/src/lib/auth-context.tsx` — wire to real `/auth/login`, `/auth/refresh`; add JWT refresh-on-401

**Doc references:**
- Platform v2 § "Affiliate Program" — business rules context for each endpoint

---

### Task H2 — Wholesale Portal API Wiring `[PENDING]`

**Dependency check:** Task D7 (wholesale backend must exist first — no routes to wire to without it).

> If D7 not complete: "The wholesale portal has nothing to wire to. Task D7 builds the entire /wholesale/* API. Resolution: Complete D7 first, or spin up an agent to run D7 in parallel."

**Objective:** Wire wholesale portal to real backend.

**Files to modify:**
- `wholesale/src/lib/api.ts` — wire to: `POST /wholesale/apply`, `GET /wholesale/dashboard`, `GET /wholesale/orders`, `POST /wholesale/orders`, `GET /wholesale/chips`
- `wholesale/src/lib/auth-context.tsx` — real auth endpoints, JWT refresh

---

# PHASE I — iOS APP
*Start immediately, parallel to backend. Use MockAPIClient until each backend endpoint is live.*

---

### Task I1 — iOS Project Setup `[PENDING]`

**Dependency check:** Apple Developer Program membership required for APNs + TestFlight.

> If Developer account not active: "Apple Developer Program ($99/year) is required for APNs, TestFlight, and App Store. Enroll at developer.apple.com. Approval can take up to 24 hours. Claude Code can set up the project and run on simulators without it, but real device testing and push notifications require enrollment."

**Objective:** Create the iOS Xcode project from scratch. No iOS code exists in the repo.

**Files to create:**
- `ios/BlakJaks.xcodeproj` — Bundle ID: `com.blakjaks.app`, iOS 16.0+, SwiftUI, includes Unit + UI test targets
- Full feature-based MVVM folder structure per iOS Strategy § 7.1 — exact folder and file names required
- `ios/BlakJaks/Config/Dev.xcconfig`, `Staging.xcconfig`, `Production.xcconfig` — `API_BASE_URL` + `METAMASK_CLIENT_ID` per environment; `Secrets.xcconfig` gitignored
- `ios/BlakJaks/MockData/MockAPIClient.swift` — implements `APIClientProtocol` with hardcoded mock data
- `ios/BlakJaks/MockData/MockData/` — MockUser.swift, MockProducts.swift, MockTransactions.swift, MockInsights.swift
- `ios/BlakJaks/Networking/APIClientProtocol.swift` — protocol defining all endpoints; ViewModels take this as dependency

**SPM dependencies (Day 1 only):**
- Alamofire `https://github.com/Alamofire/Alamofire` (5.x)
- KeychainAccess `https://github.com/kishikawakatsuki/KeychainAccess` (4.x)

Do NOT add Web3Auth, Socket.IO, SDWebImageSwiftUI, or APNs entitlements yet — those are added in later tasks when first needed.

**Info.plist additions:**
- `NSCameraUsageDescription` — QR scanning
- `NSFaceIDUsageDescription` — biometric login
- `blakjaks` URL scheme — Web3Auth redirect (`blakjaks://auth`)

**Doc references:**
- iOS Strategy § 7.1 "SwiftUI Architecture (MVVM)" — exact folder structure (copy it precisely)
- Alamofire Docs — initial setup
- Keychain Docs — initial setup

**Tests:** Project builds cleanly on iOS Simulator. MockAPIClient implements all methods defined in `APIClientProtocol`.

---

### Task I2 — iOS Design System `[PENDING]`

**Dependency check:** Task I1 complete.

**Objective:** Build the shared design system before any feature screens. Every screen depends on these components.

**Files to create (all in `ios/BlakJaks/Shared/`):**
- `Theme/Color+Theme.swift` — `BlakJaksColor.gold = #D4AF37`, `goldDark = #C9A961`, all semantic colors
- `Theme/Typography.swift` — SF Pro (UI), New York serif (brand headlines), SF Mono (crypto/wallet amounts)
- `Theme/Spacing.swift` — 8pt grid constants (xs=4, sm=8, md=16, lg=24, xl=32, xxl=48)
- `Components/GoldButton.swift` — primary CTA, 50pt height, 16pt radius, gold background, black text, loading state
- `Components/BlakJaksCard.swift` — elevated card, 16pt radius
- `Components/TierBadge.swift` — Standard (gray) / VIP (blue) / High Roller (purple) / Whale (gold)
- `Components/WarningBanner.swift` — black background, white uppercase text, always visible, never dismissible, no close button
- `Components/LoadingView.swift` — shimmer/skeleton using `.redacted(reason: .placeholder)`
- `Components/EmptyStateView.swift` — icon + title + subtitle
- `Components/ErrorView.swift` — error message + retry button

**Tab bar navigation** in `BlakJaksApp.swift`:
- 5 tabs: Insights, Shop, Scan & Wallet (center), Social, Profile
- Center bubble (tab 3): 56–64pt gold circle extending above tab bar, ♠ spade symbol; requires custom `UITabBarController` or `UIViewRepresentable` to position above native tab bar bounds
- Active: Gold `#D4AF37` / Inactive: secondary label color

**Doc references:**
- iOS Strategy § "3. Design Standards" — full color, type, spacing tokens
- iOS Strategy § "4. Component Library" — component specs
- iOS Strategy § "5. Navigation Architecture" — tab bar and center bubble spec

**Tests:** All components render correctly in SwiftUI Previews. `WarningBanner` has no close/dismiss capability.

---

### Task I3 — iOS Authentication `[PENDING]`

**Dependency check:** Task I2 (design system). For real API: Task A1 complete.

**Objective:** Build all auth screens with MockAPIClient, then wire to real API.

**Files to create:**
- `ios/BlakJaks/Features/Authentication/Views/AgeGateView.swift` — full-screen 21+ gate on first launch, `@AppStorage("age_verified")` flag
- `ios/BlakJaks/Features/Authentication/Views/WelcomeView.swift` — splash + 3 onboarding cards
- `ios/BlakJaks/Features/Authentication/Views/LoginView.swift` — email, password, Face ID button, forgot password link
- `ios/BlakJaks/Features/Authentication/Views/SignupView.swift` — email, password, full name, date of birth, T&C checkbox
- `ios/BlakJaks/Features/Authentication/Views/FaceIDPromptView.swift` — Face ID/Touch ID enrollment after first login
- `ios/BlakJaks/Features/Authentication/ViewModels/AuthViewModel.swift` — `@MainActor`, `ObservableObject`, follows ViewModel Contract from iOS Strategy § 7.1; uses `APIClientProtocol` dependency
- `ios/BlakJaks/Networking/APIClient.swift` — Alamofire session with JWT `RequestInterceptor` for silent refresh on 401
- `ios/BlakJaks/Networking/APIEndpoints.swift` — all endpoint definitions as enum
- `ios/BlakJaks/Networking/KeychainManager.swift` — store/retrieve access token + refresh token
- `ios/BlakJaks/Networking/NetworkMonitor.swift` — reachability
- `ios/BlakJaks/Networking/Config.swift` — reads `API_BASE_URL` from xcconfig

**Doc references:**
- iOS Strategy § "Phase 2: Authentication" — exact screen specs and flow
- iOS Strategy § 7.1 "ViewModel Contract" — follow this pattern exactly for AuthViewModel
- Alamofire Docs § "RequestInterceptor" — silent token refresh implementation
- Keychain Docs — token storage

**Tests (Swift unit tests):** `AuthViewModel.login()` success + failure with MockAPIClient. `KeychainManager` stores and retrieves tokens. Token refresh interceptor retries on 401.

---

### Tasks I4–I7 `[PENDING]`

Tasks I4 (Insights Dashboard + QR Scanner), I5 (Scan & Wallet center tab), I6 (Shop + Checkout), and I7 (Social Hub + Profile + Push Notifications + Polish Pass) will be fully detailed when Joshua prompts Phase I beyond Task I3. Each follows the same MockAPIClient-first → real API wiring pattern established in I3.

**Doc references for when these tasks are prompted:**
- I4: iOS Strategy § "Phase 4: Insights" + § "Phase 3: Scanner", AVFoundation Docs, AVPlayer Docs
- I5: iOS Strategy § "Phase 3: Scan & Wallet", MetaMask iOS Docs (Web3Auth v11.1.0), Oobit Docs
- I6: iOS Strategy § "Phase 5: Shop", SDWebImage Docs, AgeChecker Docs
- I7: iOS Strategy § "Phase 7: Social Hub", Socket Docs (Socket.IO-Client-Swift), AVPlayer Docs (HLS streaming), SevenTV Docs

---

# PHASE J — ANDROID APP
*⚡ Recommended: Complete iOS (I7) first. Backend APIs fully stable by then.*

Full Android task detail will be provided when Joshua prompts Phase J.

**Doc references:** MetaMask Android Docs, Socket Java Docs, Platform v2 § "Android"

---

# PHASE K — CI/CD HARDENING
*⚡ Requires: iOS project exists (I1), Phase D-F complete*

---

### Task K1 — Complete CI/CD Pipeline `[PENDING]`

**Dependency check:** Task I1 (iOS project in repo), Task A3 (`test.yml` created).

**Objective:** Add frontend deploys, staging environment, iOS CI, and Celery deployment to the pipeline.

**Files to modify:**
- `.github/workflows/deploy.yml` — add 4 frontend deploy jobs (web-app, affiliate, wholesale, admin), each triggered only on changes to its directory; add Celery worker + beat deploy alongside API deploy; make all deploy jobs depend on the test job

**Files to create:**
- `.github/workflows/ios.yml` — triggers on PRs touching `ios/**`; runs `xcodebuild test` on iOS Simulator; on tagged releases, Fastlane upload to TestFlight

**Additional:**
- Add staging deploy job triggered on merges to `staging` branch: uses `BLOCKCHAIN_POLYGON_NETWORK=mumbai`, `TELLER_ENV=sandbox`, deploys to Kubernetes namespace `staging`

**Tests:** Frontend deploy job triggers only when its directory has changes. iOS test job blocks merge on test failure.

---

# PHASE L — TESTING, SECURITY & LAUNCH
*⚡ Requires: All prior phases complete*

Full security audit, load testing, staging QA, app store assets, and production launch procedures are defined in `CHECKLIST_REVISED.md § Phase L`. Claude Code will execute these when prompted after all prior phases are complete.

---

## Appendix: Service Dependency Map

| Service | Called By | Purpose |
|---|---|---|
| `redis_service.py` | Scan endpoint, Insights API | Counters, velocity, notification counts, emote/GIF cache |
| `teller_service.py` | Celery beat (6h), Admin, Insights treasury | Bank balance sync |
| `timescale_service.py` | Celery beat (hourly), Insights treasury | Treasury sparkline data |
| `emote_service.py` | `GET /emotes` | 7TV emote set, Redis-cached |
| `giphy_service.py` | `GET /gifs/search`, `GET /gifs/trending` | GIF search, Redis-cached |
| `stargate_service.py` | `POST /admin/treasury/bridge` | ETH → Polygon USDT bridge (admin only) |
| `livestream_service.py` | Stream endpoints, RTMP webhook | Stream lifecycle management |
| `wholesale_service.py` | Wholesale + admin endpoints | Account management, orders, chips |
| `blockchain.py` | Wallet endpoints, Insights, Celery snapshot | USDT transfers, pool balances, node health (via Infura) |
| `kms_service.py` | `blockchain.py`, `stargate_service.py` | GCP KMS signing for treasury transactions |
| `celery_app.py` | Beat scheduler (autonomous) | Schedules 5 recurring background jobs |
| `push_service.py` | `notification_service.py` | APNs (iOS) + FCM (Android) delivery |
| `notification_service.py` | Scan endpoint, order events, comp awards, admin broadcast | Notification creation, inbox management, push trigger |
| `translation_service.py` | `POST /social/messages/{id}/translate` | On-demand chat message translation, DB-cached |
| `intercom_service.py` | Auth login, `GET /intercom/token` | Identity verification + user sync to Intercom |
| `avatar_service.py` | `POST /users/me/avatar` | Profile picture upload to GCS |
| `qr_service.py` | Admin QR batch endpoints | Batch code generation and CSV export |
| `governance_service.py` | Governance endpoints, admin governance endpoints | Vote creation, ballot casting, result tallying |
| `reaction_service.py` | Social message reaction endpoints | Emoji reactions on chat messages |
| `user_service.py` | User creation, tier changes | Member ID generation and tier suffix updates |

---

*End of Claude Code Orchestration Guide v3.0*
*BlakJaks LLC — Confidential*
*Built for Claude Code. Managed by Joshua Dunn.*
