import uuid
from decimal import Decimal

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.product import Product
from app.services.shop_service import calculate_shipping

pytestmark = pytest.mark.asyncio

SHIPPING_ADDRESS = {
    "line1": "123 Main St",
    "city": "Los Angeles",
    "state": "CA",
    "zip_code": "90001",
    "country": "US",
}


# ── Helper: seed 16 products ─────────────────────────────────────────


async def _seed_products(db: AsyncSession) -> list[Product]:
    """Insert the 16-product catalog into the test database."""
    flavors = [
        ("Wintergreen", "wintergreen"),
        ("Spearmint", "spearmint"),
        ("Bubblegum", "bubblegum"),
        ("Bluerazz Ice", "bluerazz_ice"),
    ]
    strengths = ["3mg", "6mg", "9mg", "12mg"]

    products = []
    for display_name, flavor_code in flavors:
        for strength in strengths:
            p = Product(
                name=f"BlakJaks {display_name} {strength}",
                description=f"Premium nicotine pouches - {display_name} flavor, {strength} strength",
                price=Decimal("5.00"),
                flavor=flavor_code,
                nicotine_strength=strength,
                stock=1000,
                is_active=True,
            )
            db.add(p)
            products.append(p)
    await db.commit()
    for p in products:
        await db.refresh(p)
    return products


# ── Product listing ───────────────────────────────────────────────────


async def test_list_products(client: AsyncClient, db: AsyncSession):
    await _seed_products(db)
    resp = await client.get("/api/shop/products")
    assert resp.status_code == 200
    data = resp.json()
    assert data["total"] == 16
    assert len(data["items"]) == 16


async def test_filter_by_flavor(client: AsyncClient, db: AsyncSession):
    await _seed_products(db)
    resp = await client.get("/api/shop/products?flavor=spearmint")
    assert resp.status_code == 200
    data = resp.json()
    assert data["total"] == 4
    assert all(p["flavor"] == "spearmint" for p in data["items"])


async def test_get_single_product(client: AsyncClient, db: AsyncSession):
    products = await _seed_products(db)
    product_id = str(products[0].id)
    resp = await client.get(f"/api/shop/products/{product_id}")
    assert resp.status_code == 200
    data = resp.json()
    assert data["id"] == product_id
    assert Decimal(data["price"]) == Decimal("5.00")


# ── Cart operations ──────────────────────────────────────────────────


async def test_add_to_cart(client: AsyncClient, auth_headers, db: AsyncSession):
    products = await _seed_products(db)
    resp = await client.post(
        "/api/cart/add",
        headers=auth_headers,
        json={"product_id": str(products[0].id), "quantity": 2},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["item_count"] == 2
    assert Decimal(data["subtotal"]) == Decimal("10.00")


async def test_add_same_product_increments(client: AsyncClient, auth_headers, db: AsyncSession):
    products = await _seed_products(db)
    pid = str(products[0].id)
    await client.post("/api/cart/add", headers=auth_headers, json={"product_id": pid, "quantity": 2})
    resp = await client.post("/api/cart/add", headers=auth_headers, json={"product_id": pid, "quantity": 3})
    assert resp.status_code == 200
    data = resp.json()
    assert data["item_count"] == 5
    assert Decimal(data["subtotal"]) == Decimal("25.00")


async def test_get_cart(client: AsyncClient, auth_headers, db: AsyncSession):
    products = await _seed_products(db)
    await client.post(
        "/api/cart/add", headers=auth_headers,
        json={"product_id": str(products[0].id), "quantity": 3},
    )
    resp = await client.get("/api/cart", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert len(data["items"]) == 1
    assert data["items"][0]["quantity"] == 3
    assert Decimal(data["subtotal"]) == Decimal("15.00")


async def test_update_cart_item(client: AsyncClient, auth_headers, db: AsyncSession):
    products = await _seed_products(db)
    add_resp = await client.post(
        "/api/cart/add", headers=auth_headers,
        json={"product_id": str(products[0].id), "quantity": 2},
    )
    item_id = add_resp.json()["items"][0]["id"]
    resp = await client.put(
        f"/api/cart/{item_id}", headers=auth_headers,
        json={"quantity": 5},
    )
    assert resp.status_code == 200
    assert resp.json()["item_count"] == 5


async def test_delete_cart_item(client: AsyncClient, auth_headers, db: AsyncSession):
    products = await _seed_products(db)
    add_resp = await client.post(
        "/api/cart/add", headers=auth_headers,
        json={"product_id": str(products[0].id), "quantity": 2},
    )
    item_id = add_resp.json()["items"][0]["id"]
    resp = await client.delete(f"/api/cart/{item_id}", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["item_count"] == 0


# ── Shipping calculation ─────────────────────────────────────────────


def test_shipping_under_50():
    assert calculate_shipping(Decimal("25.00")) == Decimal("2.99")


def test_shipping_free_at_50():
    assert calculate_shipping(Decimal("50.00")) == Decimal("0.00")


def test_shipping_free_above_50():
    assert calculate_shipping(Decimal("75.00")) == Decimal("0.00")


# ── Tax estimate ──────────────────────────────────────────────────────


async def test_tax_estimate(client: AsyncClient, auth_headers, db: AsyncSession):
    products = await _seed_products(db)
    # Add 5 tins ($25)
    await client.post(
        "/api/cart/add", headers=auth_headers,
        json={"product_id": str(products[0].id), "quantity": 5},
    )
    resp = await client.post(
        "/api/tax/estimate", headers=auth_headers,
        json=SHIPPING_ADDRESS,
    )
    assert resp.status_code == 200
    data = resp.json()
    # CA tax rate = 7.25%
    assert Decimal(data["tax_rate"]) == Decimal("7.25")
    assert Decimal(data["tax_amount"]) == Decimal("1.81")  # 25 * 0.0725 = 1.8125 -> 1.81


# ── Order creation ───────────────────────────────────────────────────


async def test_create_order_success(client: AsyncClient, auth_headers, db: AsyncSession):
    products = await _seed_products(db)
    # Add 5 tins ($25 — minimum met)
    await client.post(
        "/api/cart/add", headers=auth_headers,
        json={"product_id": str(products[0].id), "quantity": 5},
    )
    resp = await client.post(
        "/api/orders/create", headers=auth_headers,
        json={
            "shipping_address": SHIPPING_ADDRESS,
            "age_verification_id": "AGE-VERIFIED-123",
        },
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "pending"
    assert Decimal(data["subtotal"]) == Decimal("25.00")
    assert Decimal(data["shipping"]) == Decimal("2.99")
    assert Decimal(data["tax"]) > 0
    assert len(data["items"]) == 1
    assert data["items"][0]["quantity"] == 5


async def test_create_order_empty_cart(client: AsyncClient, auth_headers, db: AsyncSession):
    resp = await client.post(
        "/api/orders/create", headers=auth_headers,
        json={
            "shipping_address": SHIPPING_ADDRESS,
            "age_verification_id": "AGE-VERIFIED-123",
        },
    )
    assert resp.status_code == 400
    assert "empty" in resp.json()["detail"].lower()


async def test_create_order_under_minimum(client: AsyncClient, auth_headers, db: AsyncSession):
    products = await _seed_products(db)
    # Add only 4 tins ($20 — under $25 minimum)
    await client.post(
        "/api/cart/add", headers=auth_headers,
        json={"product_id": str(products[0].id), "quantity": 4},
    )
    resp = await client.post(
        "/api/orders/create", headers=auth_headers,
        json={
            "shipping_address": SHIPPING_ADDRESS,
            "age_verification_id": "AGE-VERIFIED-123",
        },
    )
    assert resp.status_code == 400
    assert "minimum" in resp.json()["detail"].lower()


# ── Order history ─────────────────────────────────────────────────────


async def test_order_history(client: AsyncClient, auth_headers, db: AsyncSession):
    products = await _seed_products(db)
    # Create an order first
    await client.post(
        "/api/cart/add", headers=auth_headers,
        json={"product_id": str(products[0].id), "quantity": 5},
    )
    await client.post(
        "/api/orders/create", headers=auth_headers,
        json={
            "shipping_address": SHIPPING_ADDRESS,
            "age_verification_id": "AGE-VERIFIED-123",
        },
    )

    resp = await client.get("/api/orders", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["total"] == 1
    assert len(data["items"]) == 1


async def test_order_detail(client: AsyncClient, auth_headers, db: AsyncSession):
    products = await _seed_products(db)
    await client.post(
        "/api/cart/add", headers=auth_headers,
        json={"product_id": str(products[0].id), "quantity": 5},
    )
    create_resp = await client.post(
        "/api/orders/create", headers=auth_headers,
        json={
            "shipping_address": SHIPPING_ADDRESS,
            "age_verification_id": "AGE-VERIFIED-123",
        },
    )
    order_id = create_resp.json()["id"]

    resp = await client.get(f"/api/orders/{order_id}", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["id"] == order_id
    assert data["shipping_address"]["state"] == "CA"
