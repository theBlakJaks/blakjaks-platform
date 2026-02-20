# BlakJaks Task Log
Last updated: 2026-02-19 by Eng-1

## Active Task Checkpoints

### Task A1 — Security Corrections
Engineer: Eng-1 | Branch: feature/A1 | Started: 2026-02-19 UTC

CHECKPOINT 1 [IN PROGRESS]: Replace bcrypt with Argon2id in security.py
CHECKPOINT 2 [PENDING]: Fix JWT expiry values in config.py (ACCESS_TOKEN_EXPIRE_MINUTES → 15, REFRESH_TOKEN_EXPIRE_DAYS → 30)
CHECKPOINT 3 [PENDING]: Update pyproject.toml — add argon2-cffi>=21.3.0, remove bcrypt
CHECKPOINT 4 [PENDING]: Write tests (hash prefix, correct/wrong password, bcrypt migration)

LAST KNOWN STATE: Starting implementation on feature/A1

### Task A3 — CI/CD Corrections
Engineer: Eng-2 | Branch: feature/A3 | Started: 2026-02-19 UTC

CHECKPOINT 1 [IN PROGRESS]: Add pytest job to deploy.yml before Docker build
CHECKPOINT 2 [PENDING]: Create .github/workflows/test.yml
CHECKPOINT 3 [PENDING]: Create docs/github-secrets.md

LAST KNOWN STATE: Starting implementation on feature/A3

## Completed Tasks
<!-- Orchestrator archives completed task entries here after Auditor PASS -->
