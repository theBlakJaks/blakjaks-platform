# BlakJaks Task Log
Last updated: 2026-02-19 by Eng-1

## Active Task Checkpoints

### Task A1 — Security Corrections
Engineer: Eng-1 | Branch: feature/A1 | Started: 2026-02-19 UTC

CHECKPOINT 1 [DONE]: Replace bcrypt with Argon2id in security.py via passlib CryptContext
CHECKPOINT 2 [DONE]: Fix JWT expiry values — ACCESS_TOKEN_EXPIRE_MINUTES=15, REFRESH_TOKEN_EXPIRE_DAYS=30
CHECKPOINT 3 [DONE]: Update pyproject.toml — added argon2-cffi>=21.3.0, passlib[argon2]>=1.7.4, removed bcrypt
CHECKPOINT 4 [DONE]: Tests written in backend/tests/test_security.py

LAST KNOWN STATE: COMPLETE — merged to develop [Auditor PASS]

### Task A3 — CI/CD Corrections
Engineer: Eng-2 | Branch: feature/A3 | Started: 2026-02-19 UTC

CHECKPOINT 1 [DONE]: Added test-backend job to deploy.yml — runs pytest before build; build-and-push now depends on test-backend
CHECKPOINT 2 [DONE]: Created .github/workflows/test.yml — runs on all PRs to main/staging, blocks merge on failure
CHECKPOINT 3 [DONE]: Created docs/github-secrets.md — full list of all required secrets with where-to-get instructions

LAST KNOWN STATE: COMPLETE — merged to develop [Auditor PASS]

### Task A2 — Environment Configuration
Engineer: Eng-1 | Branch: feature/A2 | Started: 2026-02-19 UTC

CHECKPOINT 1 [DONE]: Added all missing variable groups to config.py (Redis, Celery, GCS, KMS, Blockchain, Teller, OpenAI, 7TV/Giphy, APNs, FCM, Sentry, Intercom, Translation, GA4, Kintsugi, Payment, StreamYard/Selery)
CHECKPOINT 2 [DONE]: Updated backend/.env.example — all vars with placeholder values and "Where to get:" comments
CHECKPOINT 3 [DONE]: Added redis>=5.0.0, celery>=5.3.0 to pyproject.toml
CHECKPOINT 4 [DONE]: Tests written in backend/tests/test_config.py

LAST KNOWN STATE: COMPLETE — all files committed on feature/A2

## Completed Tasks
<!-- Orchestrator archives completed task entries here after Auditor PASS -->
