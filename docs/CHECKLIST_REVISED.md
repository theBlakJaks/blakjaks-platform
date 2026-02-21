# BlakJaks Platform — Master Checklist
**Last updated:** Feb 20 2026  
**Status:** Phase L in progress

---

## How to read this file

- ✅ Complete — built, tested, committed
- ⏭ Skipped — intentionally removed from scope
- 🔲 Pending — not yet started
- 👤 Manual — requires Joshua action outside the codebase (vendor approval, portal config, asset creation)
- ⚠️ Known gap — tracked architectural debt, not blocking launch

---

## PHASE A — Immediate Fixes
| # | Task | Status |
|---|------|--------|
| A1 | Security corrections (SECRET_KEY, TOTP, CORS) | ✅ |
| A2 | Environment configuration (.env, xcconfig, BuildConfig) | ✅ |
| A3 | CI/CD corrections (deploy.yml baseline) | ✅ |

## PHASE B — Database Corrections
| # | Task | Status |
|---|------|--------|
| B1 | Restore multiplier columns | ✅ |
| B2 | New table migrations (social, notifications, teller, affiliate, wallet, etc.) | ✅ |
| B3 | Redis key schema | ✅ |

## PHASE C — Infrastructure
| # | Task | Status |
|---|------|--------|
| C1 | Redis setup | ✅ |
| C2 | Polygon RPC configuration (Infura) | ✅ |
| C3 | Celery infrastructure | ✅ |
| C4 | Local development environment (docker-compose) | ✅ |
| C5 | Sentry + Prometheus + Grafana monitoring | ✅ |

## PHASE D — Services
| # | Task | Status |
|---|------|--------|
| D1 | Redis service | ✅ |
| D2 | Teller.io bank sync service | ✅ |
| D3 | Analytics service (PostgreSQL RANGE partitioning) | ✅ |
| D4 | 7TV emote service | ⏭ Client-side only — no backend service needed |
| D5 | Stargate bridge service | ✅ |
| D6 | Live stream service | ✅ |
| D7 | Wholesale backend system | ✅ |
| D8 | Push notification service (APNs + FCM) | ✅ |
| D9 | Dwolla ACH payout service | ✅ |
| D10 | Giphy service | ✅ |
| D11 | Notification center REST API | ✅ |
| D12 | Google Cloud Translation service | ✅ |
| D13 | Intercom integration | ✅ |
| D14 | Member ID generation | ✅ |
| D15 | Avatar upload service | ✅ |
| D16 | QR code batch admin system | ✅ |
| D17 | Google Cloud KMS configuration | ✅ |

## PHASE E — API Endpoints
| # | Task | Status |
|---|------|--------|
| E1 | Scan submit enrichment | ✅ |
| E2 | Insights API | ✅ |
| E3 | Leaderboard endpoints | ⏭ Removed from scope |
| E4 | Governance voting API | ✅ |
| E5 | Social message reactions API | ✅ |

## PHASE F — Web App
| # | Task | Status |
|---|------|--------|
| F1 | Compliance UI — FDA nicotine banner (all portals) | ✅ |
| F2 | Web app real API client | ✅ |
| F3 | Web app missing pages (notifications, social hub, live stream) | ✅ |

## PHASE G — Admin Portal
| # | Task | Status |
|---|------|--------|
| G1 | Admin insights tab | ✅ |
| G2 | Admin Teller bank panel | ✅ |
| G3 | Admin live streams management | ✅ |
| G4 | Admin wholesale management | ✅ |
| G5 | Admin QR batch management | ✅ |
| G6 | Admin governance management | ✅ |

## PHASE H — Portals
| # | Task | Status |
|---|------|--------|
| H1 | Affiliate portal API wiring | ✅ |
| H2 | Wholesale portal API wiring | ✅ |

## PHASE I — iOS App
| # | Task | Status |
|---|------|--------|
| I1 | iOS project setup (Xcode, SPM, xcconfig) | ✅ |
| I2 | iOS design system (gold theme, components) | ✅ |
| I3 | iOS authentication (login, signup, Face ID) | ✅ |
| I4 | Insights dashboard + QR scanner | ✅ |
| I5 | Scan & Wallet (Web3Auth, Dwolla, comp vault) | ✅ |
| I6 | Shop + checkout (Authorize.net, AgeChecker) | ✅ |
| I7 | Social hub + profile + APNs push + polish | ✅ |

## PHASE J — Android App
| # | Task | Status |
|---|------|--------|
| J1 | Project setup (Gradle, design system, networking) | ✅ |
| J2 | Authentication (welcome, login, signup, biometrics) | ✅ |
| J3 | Insights dashboard + QR scanner (CameraX + ML Kit) | ✅ |
| J4 | Scan & wallet (Web3Auth, Dwolla, PayoutChoiceSheet) | ✅ |
| J5 | Shop + checkout | ✅ |
| J6 | Social hub + profile + FCM push + polish | ✅ |

## PHASE K — CI/CD
| # | Task | Status |
|---|------|--------|
| K1 | Full CI/CD pipeline (path-filter deploys, iOS fastlane, staging branch) | ✅ |

---

## PHASE L — Testing, Security & Launch

### L1 — Security Audit ✅ Complete (commit bccdf85)

25 vulnerabilities fixed across Critical / High / Medium. See audit summary for full list.

**Remaining architectural debt (tracked, not blocking launch):**
| # | Item | Priority |
|---|------|----------|
| ⚠️ L1-a | JWT → HttpOnly session cookies (web/admin/affiliate frontends) | High — post-launch sprint |
| ⚠️ L1-b | SSL certificate pinning (iOS Alamofire + Android OkHttp) | High — post-launch sprint |
| ⚠️ L1-c | Android biometric upgrade: BIOMETRIC_WEAK → BIOMETRIC_STRONG + CryptoObject | Medium |
| ⚠️ L1-d | Kubernetes NetworkPolicy manifests (no K8s manifests in repo yet) | Medium |

---

### L2 — Load Testing 🔲 Pending (Claude Code)

**Tool:** k6 (preferred — JS-based, CI-friendly) or Locust (Python)

**Targets from Platform spec:**
- Social Hub: 250,000 concurrent WebSocket connections during live events
- Scan submission: burst load at milestone boundaries (global counter hits round numbers)
- Auth: sustained login load during app launch events

**Test scenarios to write:**

| Scenario | Endpoint(s) | Target | Pass threshold |
|----------|------------|--------|----------------|
| Scan burst | POST /scan/submit | 5,000 req/min | p95 < 500ms, 0% error |
| Auth flood | POST /auth/login | 1,000 concurrent | p95 < 800ms, rate-limited 429s appear |
| Social WebSocket | WSS /insights/live | 10,000 concurrent connections | No drops, <100ms message latency |
| Insights API | GET /insights/overview | 2,000 req/min | p95 < 300ms |
| Shop catalog | GET /products | 1,000 req/min | p95 < 200ms |
| Withdrawal | POST /wallet/comp-payout-choice | 200 req/min | 0% double-spend, p95 < 1s |

**Files to create:**
- `load-tests/scan_burst.js`
- `load-tests/auth_flood.js`
- `load-tests/websocket_social.js`
- `load-tests/insights_api.js`
- `load-tests/withdrawal_safety.js`
- `load-tests/README.md` — how to run against staging

**CI integration:** Add `load-test` job to `.github/workflows/deploy.yml` — runs `scan_burst.js` and `withdrawal_safety.js` against staging after `deploy-staging` job completes. Fails pipeline if thresholds not met.

---

### L3 — Staging QA Pass 🔲 Pending (Claude Code + 👤 Joshua)

**Claude Code:** Write `scripts/staging_smoke_test.py` — automated smoke test that hits every critical path against the staging environment:
- Auth: signup → login → token refresh → logout
- Scan: submit a valid QR code → verify comp_earned in response → verify comp shows in wallet
- Payout choice: POST /wallet/comp-payout-choice with method='later' → verify comp_balance incremented
- Shop: GET /products → add to cart → estimate tax → place order
- Social: connect WebSocket → send message → verify echo
- Notifications: GET /notifications → mark read
- Insights: GET /insights/overview, /insights/treasury

**👤 Joshua (manual):** Full end-to-end QA on staging devices:
- [ ] iOS TestFlight build installed on physical device
- [ ] Android APK sideloaded on physical device
- [ ] Complete scan flow (scan a real QR code in staging)
- [ ] Payout choice modal appears and all 3 options work (sandbox)
- [ ] Dwolla sandbox bank link (Plaid + ACH in sandbox mode)
- [ ] Live stream: start a test stream via StreamYard → RTMP → verify HLS plays in app
- [ ] Push notifications: trigger a comp → verify APNs (iOS) and FCM (Android) deliver
- [ ] Social chat: send messages, reactions, GIFs, 7TV emotes
- [ ] Shop: complete full checkout flow with Authorize.net sandbox
- [ ] AgeChecker.net: verify age verification step loads
- [ ] Admin portal: create QR batch, manage live stream, review governance
- [ ] Affiliate portal: verify referral stats load
- [ ] Wholesale portal: verify order management loads

---

### L4 — App Store & Play Store Assets 👤 Joshua (manual)

**iOS App Store:**
- [ ] App name: "BlakJaks"
- [ ] Subtitle (30 chars max)
- [ ] Description (4,000 chars max)
- [ ] Keywords (100 chars max)
- [ ] Screenshots: 6.7" (iPhone 15 Pro Max), 6.1" (iPhone 15), 12.9" iPad (if supporting iPad)
  - Required screens: Onboarding, Scan, Wallet/Comps, Shop, Social Hub
- [ ] App preview video (optional but recommended)
- [ ] Support URL
- [ ] Privacy policy URL (must be live before submission)
- [ ] Age rating questionnaire (nicotine content → 17+ rating expected)
- [ ] APNs production certificate (.p8 key) — Apple Developer portal → Keys
- [ ] Provisioning profile for distribution (App Store)
- [ ] App Store Connect API key for Fastlane (already used in `ios.yml` — ensure production key set in GitHub secrets)

**Google Play Store:**
- [ ] Store listing title: "BlakJaks"
- [ ] Short description (80 chars)
- [ ] Full description (4,000 chars)
- [ ] Feature graphic (1024×500px)
- [ ] Screenshots: phone (minimum 2), 7" tablet (optional)
  - Required screens: same 5 as iOS
- [ ] Content rating questionnaire (nicotine → Mature 17+)
- [ ] Privacy policy URL
- [ ] FCM production `google-services.json` → `android/app/google-services.json`
- [ ] Signing keystore (production) → stored in GitHub secrets as `ANDROID_KEYSTORE_BASE64`
- [ ] Target API level 35 confirmed in `build.gradle.kts`

---

### L5 — Production Credentials & Secrets 👤 Joshua (manual)

All must be populated in GCP Secret Manager before production deploy:

**Backend:**
- [ ] `SECRET_KEY` — strong random 64-char key (not default)
- [ ] `DATABASE_URL` — production PostgreSQL connection string
- [ ] `REDIS_URL` — production Redis connection string
- [ ] `TELLER_CERT_PATH` + `TELLER_PRIVATE_KEY_PATH` — production Teller.io certificates
- [ ] `DWOLLA_KEY` + `DWOLLA_SECRET` — production Dwolla credentials (see L6)
- [ ] `DWOLLA_MASTER_FUNDING_SOURCE` — production Dwolla master funding source URL
- [ ] `AUTHORIZE_NET_API_LOGIN_ID` + `AUTHORIZE_NET_TRANSACTION_KEY` — production (see L6)
- [ ] `BLOCKCHAIN_POLYGON_NETWORK` → set to `mainnet`
- [ ] `INFURA_PROJECT_ID` — production Infura key
- [ ] `GCP_KMS_KEY_RING` + `GCP_KMS_KEY_NAME` — production KMS key (treasury signing)
- [ ] `OPENAI_API_KEY` — production key (OpenAI Moderation + Translation fallback)
- [ ] `GOOGLE_TRANSLATE_API_KEY` — production Google Cloud Translation key
- [ ] `GIPHY_API_KEY` — production Giphy key
- [ ] `SENTRY_DSN` — production Sentry project DSN
- [ ] `INTERCOM_APP_ID` + `INTERCOM_SECRET_KEY` — production
- [ ] `FCM_SERVICE_ACCOUNT_PATH` — production FCM service account JSON path
- [ ] `APNS_KEY_ID` + `APNS_TEAM_ID` + `APNS_KEY_PATH` — production APNs .p8 key
- [ ] `JWT_PRIVATE_KEY_PATH` + `JWT_PUBLIC_KEY_PATH` — production RS256 keypair via KMS

**iOS (xcconfig `Production.xcconfig`):**
- [ ] `API_BASE_URL` = production API URL
- [ ] `GIPHY_API_KEY` = production key
- [ ] `WEB3AUTH_CLIENT_ID` = production MetaMask Embedded Wallets client ID

**Android (`gradle.properties` production values):**
- [ ] `API_BASE_URL` = production API URL
- [ ] `GIPHY_API_KEY` = production key
- [ ] `WEB3AUTH_CLIENT_ID` = production client ID

---

### L6 — Merchant & Vendor Approvals 👤 Joshua (manual)

These require external approval processes and may take days to weeks:

**Dwolla:**
- [ ] Contact Dwolla sales/compliance to confirm nicotine/tobacco merchant approval
- [ ] Dwolla compliance review of BlakJaks business model (comp payouts to members)
- [ ] Obtain production `DWOLLA_KEY` + `DWOLLA_SECRET`
- [ ] Set up production master funding source (Dwolla business verified account)
- [ ] Confirm Same-Day ACH approval (if desired; separate Dwolla account feature)
- **Note from docs:** "Nicotine/tobacco merchant approval must be confirmed with Dwolla before production payout launch"

**Authorize.net:**
- [ ] Confirm nicotine/tobacco product sales permitted under Authorize.net merchant agreement
- [ ] Obtain production `AUTHORIZE_NET_API_LOGIN_ID` + `AUTHORIZE_NET_TRANSACTION_KEY`
- [ ] Configure merchant account for card-not-present e-commerce
- [ ] Test a real transaction in sandbox before production cutover

**AgeChecker.net:**
- [ ] Confirm production account and API key
- [ ] Test age verification flow with real credentials in staging

**Intercom:**
- [ ] Confirm production workspace and `INTERCOM_APP_ID`
- [ ] Configure iOS + Android SDK with production credentials

**Teller.io:**
- [ ] Confirm production certificates (`TELLER_CERT_PATH`, `TELLER_PRIVATE_KEY_PATH`)
- [ ] Confirm production environment (`TELLER_ENV=production`)

---

### L7 — Production Infrastructure 👤 Joshua (manual)

- [ ] Domain DNS cutover: point `api.blakjaks.com`, `app.blakjaks.com`, `admin.blakjaks.com` etc. to GCP load balancers
- [ ] SSL/TLS certificates: verify auto-provisioned via GCP managed certs or Cert Manager
- [ ] GCP production Kubernetes cluster: confirm node pools, autoscaling, resource limits
- [ ] Kubernetes NetworkPolicy manifests (see ⚠️ L1-d) — create before production if possible
- [ ] GCP Cloud Armor (WAF): configure rate limiting rules at edge
- [ ] CloudSQL production instance: confirm backups enabled, point-in-time recovery configured
- [ ] Redis (Memorystore): confirm production instance size and HA failover
- [ ] GCP KMS: confirm production key ring and treasury signing keys are in place
- [ ] Cloud CDN: confirm HLS stream CDN and static asset CDN configured
- [ ] Uptime monitoring: Sentry + Grafana dashboards reviewed, alert channels (PagerDuty or equivalent) configured
- [ ] StreamYard RTMP: configure production RTMP endpoint for live events

---

### L8 — Launch Sequence (Day of Launch) 👤 Joshua + Claude Code

**T-24h:**
- [ ] Final staging smoke test passes (`scripts/staging_smoke_test.py`)
- [ ] Load tests pass against staging
- [ ] All L5 production secrets populated in GCP Secret Manager
- [ ] All L6 merchant approvals confirmed

**T-0 (production deploy):**
- [ ] Merge `main` → production deploy fires via `deploy.yml`
- [ ] Watch `kubectl rollout status` for all deployments
- [ ] Verify Sentry receives first production events (no crashes)
- [ ] Verify APNs + FCM deliver first push notification
- [ ] Send one test scan → verify comp flow end to end
- [ ] Admin portal: confirm live dashboard shows real data

**App store release:**
- [ ] iOS: tag `v1.0.0` → `ios.yml` `release` job fires → Fastlane uploads to TestFlight → submit for App Store review
- [ ] Android: promote internal test track → production track in Play Console

---

### L9 — Post-Launch Sprint (First 2 Weeks) ⚠️ Architectural debt

These were intentionally deferred and should be addressed in the first post-launch release:

| # | Item | Effort |
|---|------|--------|
| L9-a | JWT → HttpOnly session cookies (web/admin/affiliate) | Large — full auth rewrite across 3 frontends |
| L9-b | SSL certificate pinning (iOS + Android) | Medium — Alamofire TrustKit / OkHttp CertificatePinner |
| L9-c | Android biometric → BIOMETRIC_STRONG + CryptoObject | Small |
| L9-d | Kubernetes NetworkPolicy manifests | Medium |
| L9-e | Self-hosted Polygon full node (replace Infura) | Large — infrastructure only |
| L9-f | Same-Day ACH (pending Dwolla account approval) | Small — feature flag already in code |

---

## Summary

| Phase | Tasks | Status |
|-------|-------|--------|
| A | 3/3 | ✅ Complete |
| B | 3/3 | ✅ Complete |
| C | 5/5 | ✅ Complete |
| D | 16/17 | ✅ Complete (D4 skipped — client-side only) |
| E | 4/5 | ✅ Complete (E3 removed from scope) |
| F | 3/3 | ✅ Complete |
| G | 6/6 | ✅ Complete |
| H | 2/2 | ✅ Complete |
| I | 7/7 | ✅ Complete |
| J | 6/6 | ✅ Complete |
| K | 1/1 | ✅ Complete |
| L1 | Security audit | ✅ Complete |
| L2 | Load testing | 🔲 Pending |
| L3 | Staging QA | 🔲 Pending |
| L4 | App store assets | 👤 Manual |
| L5 | Production secrets | 👤 Manual |
| L6 | Merchant approvals | 👤 Manual |
| L7 | Production infrastructure | 👤 Manual |
| L8 | Launch sequence | 👤 Manual |
| L9 | Post-launch sprint | ⚠️ Deferred |
