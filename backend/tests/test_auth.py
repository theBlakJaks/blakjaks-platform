import pytest
from httpx import AsyncClient

from app.core.security import create_access_token, create_reset_token
from tests.conftest import SIGNUP_PAYLOAD

pytestmark = pytest.mark.asyncio


# ── Health ───────────────────────────────────────────────────────────


async def test_health(client: AsyncClient):
    resp = await client.get("/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}


# ── Signup ───────────────────────────────────────────────────────────


async def test_signup_success(client: AsyncClient):
    resp = await client.post("/api/auth/signup", json=SIGNUP_PAYLOAD)
    assert resp.status_code == 201
    data = resp.json()
    assert data["user"]["email"] == SIGNUP_PAYLOAD["email"]
    assert data["user"]["first_name"] == SIGNUP_PAYLOAD["first_name"]
    assert data["tokens"]["access_token"]
    assert data["tokens"]["refresh_token"]
    assert data["tokens"]["token_type"] == "bearer"


async def test_signup_duplicate_email(client: AsyncClient, registered_user):
    resp = await client.post("/api/auth/signup", json=SIGNUP_PAYLOAD)
    assert resp.status_code == 409
    assert "already registered" in resp.json()["detail"].lower()


# ── Login ────────────────────────────────────────────────────────────


async def test_login_success(client: AsyncClient, registered_user):
    resp = await client.post(
        "/api/auth/login",
        json={"email": SIGNUP_PAYLOAD["email"], "password": SIGNUP_PAYLOAD["password"]},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["user"]["email"] == SIGNUP_PAYLOAD["email"]
    assert data["tokens"]["access_token"]
    assert data["tokens"]["refresh_token"]


async def test_login_wrong_password(client: AsyncClient, registered_user):
    resp = await client.post(
        "/api/auth/login",
        json={"email": SIGNUP_PAYLOAD["email"], "password": "wrongpassword99"},
    )
    assert resp.status_code == 401
    assert "invalid" in resp.json()["detail"].lower()


async def test_login_nonexistent_email(client: AsyncClient):
    resp = await client.post(
        "/api/auth/login",
        json={"email": "nobody@example.com", "password": "whatever1234"},
    )
    assert resp.status_code == 401


# ── Refresh ──────────────────────────────────────────────────────────


async def test_refresh_success(client: AsyncClient, registered_user):
    refresh_token = registered_user["tokens"]["refresh_token"]
    resp = await client.post("/api/auth/refresh", json={"refresh_token": refresh_token})
    assert resp.status_code == 200
    data = resp.json()
    assert data["access_token"]
    assert data["token_type"] == "bearer"


async def test_refresh_invalid_token(client: AsyncClient):
    resp = await client.post("/api/auth/refresh", json={"refresh_token": "garbage.token.here"})
    assert resp.status_code == 401


async def test_refresh_rejects_access_token(client: AsyncClient, registered_user):
    access_token = registered_user["tokens"]["access_token"]
    resp = await client.post("/api/auth/refresh", json={"refresh_token": access_token})
    assert resp.status_code == 401


# ── Reset Password ──────────────────────────────────────────────────


async def test_reset_password_existing_email(client: AsyncClient, registered_user):
    resp = await client.post(
        "/api/auth/reset-password", json={"email": SIGNUP_PAYLOAD["email"]}
    )
    assert resp.status_code == 200
    assert "reset link" in resp.json()["message"].lower()


async def test_reset_password_nonexistent_email(client: AsyncClient):
    resp = await client.post(
        "/api/auth/reset-password", json={"email": "ghost@example.com"}
    )
    assert resp.status_code == 200
    assert "reset link" in resp.json()["message"].lower()


# ── Reset Password Confirm ──────────────────────────────────────────


async def test_reset_password_confirm_success(client: AsyncClient, registered_user):
    user_id = registered_user["user"]["id"]
    reset_token = create_reset_token(user_id)
    new_password = "brandnewpassword456"

    resp = await client.post(
        "/api/auth/reset-password/confirm",
        json={"token": reset_token, "new_password": new_password},
    )
    assert resp.status_code == 200
    assert "successfully" in resp.json()["message"].lower()

    # Verify the new password actually works
    resp = await client.post(
        "/api/auth/login",
        json={"email": SIGNUP_PAYLOAD["email"], "password": new_password},
    )
    assert resp.status_code == 200


async def test_reset_password_confirm_invalid_token(client: AsyncClient):
    resp = await client.post(
        "/api/auth/reset-password/confirm",
        json={"token": "bad.token.here", "new_password": "newpassword123"},
    )
    assert resp.status_code == 400


async def test_reset_password_confirm_rejects_access_token(
    client: AsyncClient, registered_user
):
    access_token = registered_user["tokens"]["access_token"]
    resp = await client.post(
        "/api/auth/reset-password/confirm",
        json={"token": access_token, "new_password": "newpassword123"},
    )
    assert resp.status_code == 400
