"""E-commerce shop service — products, cart, orders."""

import uuid
from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy import delete, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload, subqueryload

from app.models.cart_item import CartItem
from app.models.order import Order
from app.models.order_item import OrderItem
from app.models.product import Product
from app.services.age_verification import verify_age
from app.services.tax_service import estimate_tax

# Business constants
PRICE_PER_TIN = Decimal("5.00")
MIN_ORDER_AMOUNT = Decimal("25.00")  # 5 tins minimum
SHIPPING_FLAT_RATE = Decimal("2.99")
FREE_SHIPPING_THRESHOLD = Decimal("50.00")

# Sort options
SORT_MAP = {
    "price_asc": Product.price.asc(),
    "price_desc": Product.price.desc(),
    "name": Product.name.asc(),
}


# ── Products ──────────────────────────────────────────────────────────


async def get_products(
    db: AsyncSession,
    flavor: str | None = None,
    sort_by: str = "name",
    page: int = 1,
    per_page: int = 20,
) -> dict:
    """Paginated product catalog with optional flavor filter and sort."""
    query = select(Product).where(Product.is_active == True)  # noqa: E712

    if flavor:
        query = query.where(Product.flavor == flavor)

    # Count total
    count_query = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_query)).scalar_one()

    # Sort
    order_clause = SORT_MAP.get(sort_by, Product.name.asc())
    query = query.order_by(order_clause)

    # Paginate
    offset = (page - 1) * per_page
    query = query.offset(offset).limit(per_page)

    result = await db.execute(query)
    products = list(result.scalars().all())

    return {"items": products, "total": total}


async def get_product(db: AsyncSession, product_id: uuid.UUID) -> Product:
    """Single product detail."""
    result = await db.execute(select(Product).where(Product.id == product_id))
    product = result.scalar_one_or_none()
    if product is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Product not found")
    return product


# ── Cart ──────────────────────────────────────────────────────────────


async def get_cart(db: AsyncSession, user_id: uuid.UUID) -> dict:
    """Return user's current cart."""
    result = await db.execute(
        select(CartItem)
        .where(CartItem.user_id == user_id)
        .options(selectinload(CartItem.product))
        .order_by(CartItem.created_at)
    )
    cart_items = list(result.scalars().all())

    items = []
    subtotal = Decimal("0")
    item_count = 0
    for ci in cart_items:
        line_total = ci.product.price * ci.quantity
        subtotal += line_total
        item_count += ci.quantity
        items.append({
            "id": ci.id,
            "product_id": ci.product_id,
            "product_name": ci.product.name,
            "product_image": ci.product.image_url,
            "quantity": ci.quantity,
            "unit_price": ci.product.price,
            "line_total": line_total,
        })

    return {"items": items, "subtotal": subtotal, "item_count": item_count}


async def add_to_cart(
    db: AsyncSession, user_id: uuid.UUID, product_id: uuid.UUID, quantity: int
) -> dict:
    """Add item to cart or increment quantity if already present."""
    # Verify product exists and is active
    product = await db.execute(
        select(Product).where(Product.id == product_id, Product.is_active == True)  # noqa: E712
    )
    product = product.scalar_one_or_none()
    if product is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Product not found")

    # Check if already in cart
    result = await db.execute(
        select(CartItem).where(
            CartItem.user_id == user_id, CartItem.product_id == product_id
        )
    )
    existing = result.scalar_one_or_none()

    if existing:
        existing.quantity += quantity
    else:
        cart_item = CartItem(
            user_id=user_id, product_id=product_id, quantity=quantity
        )
        db.add(cart_item)

    await db.commit()
    return await get_cart(db, user_id)


async def update_cart_item(
    db: AsyncSession, user_id: uuid.UUID, item_id: uuid.UUID, quantity: int
) -> dict:
    """Update cart item quantity. Remove if quantity is 0."""
    result = await db.execute(
        select(CartItem).where(CartItem.id == item_id, CartItem.user_id == user_id)
    )
    item = result.scalar_one_or_none()
    if item is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Cart item not found")

    if quantity == 0:
        await db.delete(item)
    else:
        item.quantity = quantity

    await db.commit()
    return await get_cart(db, user_id)


async def remove_from_cart(
    db: AsyncSession, user_id: uuid.UUID, item_id: uuid.UUID
) -> dict:
    """Remove item from cart."""
    result = await db.execute(
        select(CartItem).where(CartItem.id == item_id, CartItem.user_id == user_id)
    )
    item = result.scalar_one_or_none()
    if item is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Cart item not found")

    await db.delete(item)
    await db.commit()
    return await get_cart(db, user_id)


async def clear_cart(db: AsyncSession, user_id: uuid.UUID) -> None:
    """Empty user's cart."""
    await db.execute(delete(CartItem).where(CartItem.user_id == user_id))
    await db.commit()


# ── Shipping ──────────────────────────────────────────────────────────


def calculate_shipping(subtotal: Decimal) -> Decimal:
    """$2.99 flat rate, FREE at $50+."""
    if subtotal >= FREE_SHIPPING_THRESHOLD:
        return Decimal("0.00")
    return SHIPPING_FLAT_RATE


# ── Orders ────────────────────────────────────────────────────────────


async def create_order(
    db: AsyncSession,
    user_id: uuid.UUID,
    shipping_address: dict,
    age_verification_id: str,
) -> Order:
    """Full checkout: validate cart, calc totals, verify age, create order."""
    # Verify age
    if not await verify_age(age_verification_id):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Age verification failed")

    # Get cart
    cart = await get_cart(db, user_id)
    if not cart["items"]:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Cart is empty")

    subtotal = cart["subtotal"]
    if subtotal < MIN_ORDER_AMOUNT:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"Minimum order is ${MIN_ORDER_AMOUNT} (5 tins)",
        )

    # Calculate shipping
    shipping = calculate_shipping(subtotal)

    # Calculate tax
    tax_result = await estimate_tax(subtotal, shipping_address.get("state", ""))
    tax = tax_result["tax_amount"]

    total = subtotal + shipping + tax

    # Create order
    order = Order(
        user_id=user_id,
        status="pending",
        subtotal=subtotal,
        shipping=shipping,
        tax=tax,
        total=total,
        shipping_address_json=shipping_address,
        age_verification_id=age_verification_id,
    )
    db.add(order)
    await db.flush()

    # Create order items from cart
    for item in cart["items"]:
        order_item = OrderItem(
            order_id=order.id,
            product_id=item["product_id"],
            quantity=item["quantity"],
            unit_price=item["unit_price"],
        )
        db.add(order_item)

    # Clear cart
    await db.execute(delete(CartItem).where(CartItem.user_id == user_id))
    await db.commit()

    # Reload order with items
    await db.refresh(order)
    result = await db.execute(
        select(Order)
        .where(Order.id == order.id)
        .options(selectinload(Order.items).selectinload(OrderItem.product))
    )
    return result.scalar_one()


async def get_orders(
    db: AsyncSession, user_id: uuid.UUID, page: int = 1, per_page: int = 10
) -> dict:
    """User's order history, paginated."""
    count_query = select(func.count()).select_from(Order).where(Order.user_id == user_id)
    total = (await db.execute(count_query)).scalar_one()

    offset = (page - 1) * per_page
    result = await db.execute(
        select(Order)
        .where(Order.user_id == user_id)
        .options(selectinload(Order.items).selectinload(OrderItem.product))
        .order_by(Order.created_at.desc())
        .offset(offset)
        .limit(per_page)
    )
    orders = list(result.scalars().all())
    return {"items": orders, "total": total, "page": page, "per_page": per_page}


async def get_order(db: AsyncSession, user_id: uuid.UUID, order_id: uuid.UUID) -> Order:
    """Single order detail."""
    result = await db.execute(
        select(Order)
        .where(Order.id == order_id, Order.user_id == user_id)
        .options(selectinload(Order.items).selectinload(OrderItem.product))
    )
    order = result.scalar_one_or_none()
    if order is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Order not found")
    return order
