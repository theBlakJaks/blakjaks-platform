# BlakJaks Task Log
Last updated: 2026-02-19 by Eng-1

## Active Task Checkpoints

### Task B1 — Restore Multiplier Columns
Engineer: Eng-1 | Branch: feature/B1 | Started: 2026-02-19 UTC

CHECKPOINT 1 [IN PROGRESS]: Create migration 012_restore_multipliers.py — re-add multiplier to tiers, tier_multiplier to scans, seed correct values
CHECKPOINT 2 [PENDING]: Add multiplier field to tier.py ORM model
CHECKPOINT 3 [PENDING]: Add tier_multiplier field to scan.py ORM model
CHECKPOINT 4 [PENDING]: Write tests

LAST KNOWN STATE: Starting implementation on feature/B1

## Completed Tasks

### Task A1 — Security Corrections
Engineer: Eng-1 | Branch: feature/A1 | Merged: 2026-02-19 UTC | Auditor: PASS

CHECKPOINT 1 [DONE]: Replace bcrypt with Argon2id in security.py via passlib CryptContext
CHECKPOINT 2 [DONE]: Fix JWT expiry values — ACCESS_TOKEN_EXPIRE_MINUTES=15, REFRESH_TOKEN_EXPIRE_DAYS=30
CHECKPOINT 3 [DONE]: Update pyproject.toml — added argon2-cffi>=21.3.0, passlib[argon2]>=1.7.4, removed bcrypt
CHECKPOINT 4 [DONE]: Tests written in backend/tests/test_security.py (7 tests)

### Task A3 — CI/CD Corrections
Engineer: Eng-2 | Branch: feature/A3 | Merged: 2026-02-19 UTC | Auditor: PASS

CHECKPOINT 1 [DONE]: Added test-backend job to deploy.yml — runs pytest before build
CHECKPOINT 2 [DONE]: Created .github/workflows/test.yml — PR gate on main/staging
CHECKPOINT 3 [DONE]: Created docs/github-secrets.md — full secrets reference

### Task A2 — Environment Configuration
Engineer: Eng-1 | Branch: feature/A2 | Merged: 2026-02-19 UTC | Auditor: PASS

CHECKPOINT 1 [DONE]: Added all missing variable groups to config.py (16 service groups, 40+ fields)
CHECKPOINT 2 [DONE]: Updated backend/.env.example — all vars with placeholder values and "Where to get:" comments
CHECKPOINT 3 [DONE]: Added redis>=5.0.0, celery>=5.3.0 to pyproject.toml
CHECKPOINT 4 [DONE]: Tests written in backend/tests/test_config.py (17 tests)
