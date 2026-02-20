# BlakJaks Platform

> Nicotine products platform — backend API, web app, affiliate portal, wholesale portal, and admin dashboard.

---

## Prerequisites

| Tool | Minimum version | Notes |
|------|----------------|-------|
| Docker + Docker Compose | Docker 24+ | Required for local stack |
| Python | 3.11+ | Backend development |
| Node.js | 20+ | Frontend apps |
| gcloud CLI | Latest | GCP integration (KMS, GCS) |

---

## Quick Start (local dev)

### 1. Clone and configure

```bash
git clone git@github.com:theBlakJaks/blakjaks-platform.git
cd blakjaks-platform
cp .env.local.example .env
```

Open `.env` and fill in any third-party API keys you need for the features you're working on. At minimum, the stack runs with all blank third-party keys — services that need them will log warnings.

### 2. Start the local stack

```bash
docker-compose up
```

This starts:
- **PostgreSQL** (TimescaleDB) on port `5432`
- **Redis** on port `6379`
- **FastAPI backend** on port `8000` (hot-reload)
- **Celery worker** and **Celery beat** scheduler
- **Prometheus** on port `9090`
- **Grafana** on port `3100` (admin / blakjaks-local)
- **AlertManager** on port `9093`

### 3. Run database migrations

```bash
docker-compose exec backend alembic upgrade head
```

### 4. Verify the stack

```bash
curl http://localhost:8000/health
# → {"status": "ok", "redis": "ok"}

curl http://localhost:8000/metrics
# → Prometheus metrics text
```

---

## Running Tests

```bash
cd backend
pip install -e ".[dev]"
pytest
```

Tests use an in-memory SQLite database (via `aiosqlite`) and mocked Redis. No real GCP or third-party services are called during tests.

---

## Project Structure

```
blakjaks-platform/
├── backend/
│   ├── app/
│   │   ├── core/           ← config.py, security.py
│   │   ├── models/         ← SQLAlchemy ORM models
│   │   ├── api/            ← FastAPI route handlers and schemas
│   │   ├── services/       ← Business logic layer
│   │   ├── tasks/          ← Celery task files
│   │   └── main.py         ← FastAPI app (lifespan, middleware, routes)
│   ├── alembic/            ← Alembic migration files
│   ├── tests/
│   ├── .env.example        ← Full variable reference with "Where to get:" comments
│   └── pyproject.toml
├── web-app/                ← Consumer Next.js web app
├── affiliate/              ← Affiliate portal (Next.js)
├── wholesale/              ← Wholesale portal (Next.js)
├── admin/                  ← Admin dashboard (Next.js)
├── infrastructure/
│   ├── celery/             ← Celery worker + beat Dockerfiles
│   └── monitoring/         ← Prometheus, Grafana, AlertManager configs
├── .env.local.example      ← Safe local dev defaults
├── docker-compose.yml      ← Local dev stack (NOT GCP provisioning)
└── README.md
```

---

## GCP Infrastructure

All production infrastructure is pre-provisioned. Do not run terraform or gcloud create commands without verifying first.

| Resource | Name | Details |
|----------|------|---------|
| GKE Cluster | `blakjaks-primary` | Autopilot, us-central1 |
| PostgreSQL | `blakjaks-db` | PostgreSQL 18.2, Cloud SQL, 10.96.112.3 (private) |
| Redis | `blakjaks-redis` | Redis 7.2, Cloud Memorystore, 10.96.113.3:6379 |
| KMS Keyring | `blakjaks-crypto` | 3 ASYMMETRIC_SIGN keys (treasury, affiliate, wholesale) |

GKE namespaces: `default`, `development`, `staging`, `production`

---

## GCP Authentication (local dev)

To use KMS or GCS locally, authenticate with Application Default Credentials:

```bash
gcloud auth application-default login
gcloud config set project blakjaks-production
```

---

## Monitoring

| Service | URL | Credentials |
|---------|-----|-------------|
| Grafana | http://localhost:3100 | admin / blakjaks-local |
| Prometheus | http://localhost:9090 | — |
| AlertManager | http://localhost:9093 | — |
| API Metrics | http://localhost:8000/metrics | — |

---

## Environment Variables

See `backend/.env.example` for the complete variable reference with "Where to get:" comments for every third-party service.

---

## Warning

This product contains nicotine. Nicotine is an addictive chemical. For authorized users 21+ only.
