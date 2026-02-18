import uuid
from datetime import datetime, timezone

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy import event
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.ext.compiler import compiles

from app.api.deps import get_db
from app.main import app
from app.models.base import Base

# --- SQLite compat: compile PostgreSQL types as SQLite equivalents ---


@compiles(UUID, "sqlite")
def _compile_uuid_sqlite(type_, compiler, **kw):
    return "CHAR(36)"


@compiles(JSONB, "sqlite")
def _compile_jsonb_sqlite(type_, compiler, **kw):
    return "JSON"


# --- Test engine ---

TEST_DATABASE_URL = "sqlite+aiosqlite://"

engine = create_async_engine(TEST_DATABASE_URL, echo=False)
test_session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


@event.listens_for(engine.sync_engine, "connect")
def _register_sqlite_functions(dbapi_conn, _connection_record):
    """Register PostgreSQL function shims so server_defaults work on SQLite."""
    dbapi_conn.create_function("gen_random_uuid", 0, lambda: str(uuid.uuid4()))
    dbapi_conn.create_function("now", 0, lambda: datetime.now(timezone.utc).isoformat())


async def _override_get_db():
    async with test_session_factory() as session:
        yield session


app.dependency_overrides[get_db] = _override_get_db


@pytest.fixture(autouse=True)
async def setup_database():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest.fixture
async def db():
    async with test_session_factory() as session:
        yield session


@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


SIGNUP_PAYLOAD = {
    "email": "test@example.com",
    "password": "securepassword123",
    "first_name": "Test",
    "last_name": "User",
    "birthdate": "1995-06-15",
}


@pytest.fixture
async def registered_user(client: AsyncClient) -> dict:
    """Sign up a user and return the full response body."""
    resp = await client.post("/api/auth/signup", json=SIGNUP_PAYLOAD)
    assert resp.status_code == 201
    return resp.json()


@pytest.fixture
async def auth_headers(registered_user) -> dict:
    """Return Authorization headers for the registered user."""
    token = registered_user["tokens"]["access_token"]
    return {"Authorization": f"Bearer {token}"}


async def seed_tiers(db: AsyncSession):
    """Insert the 4 standard tiers into the test database."""
    from app.models.tier import Tier

    tiers = [
        Tier(name="Standard", min_scans=0, discount_pct=0, color="#6B7280",
             benefits_json={"comp_eligibility": [], "community_access": "observational", "merch_tier": None}),
        Tier(name="VIP", min_scans=7, discount_pct=10, color="#3B82F6",
             benefits_json={"comp_eligibility": ["crypto_100"], "community_access": "full", "merch_tier": "vip"}),
        Tier(name="High Roller", min_scans=15, discount_pct=15, color="#F59E0B",
             benefits_json={"comp_eligibility": ["crypto_100", "crypto_1k"], "community_access": "high_roller_lounge", "merch_tier": "high_roller"}),
        Tier(name="Whale", min_scans=30, discount_pct=20, color="#8B5CF6",
             benefits_json={"comp_eligibility": ["crypto_100", "crypto_1k", "crypto_10k", "casino_comp"], "community_access": "whale_lounge", "merch_tier": "whale"}),
    ]
    db.add_all(tiers)
    await db.commit()
