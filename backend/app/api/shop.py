"""E-commerce shop endpoints — products, cart, checkout, orders."""

import uuid

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.api.schemas.shop import (
    CartItemAdd,
    CartItemUpdate,
    CartOut,
    OrderCreate,
    OrderList,
    OrderOut,
    ProductList,
    ProductOut,
    ShippingAddress,
    TaxEstimate,
)
from app.models.user import User
from app.services.shop_service import (
    add_to_cart,
    create_order,
    get_cart,
    get_order,
    get_orders,
    get_product,
    get_products,
    remove_from_cart,
    update_cart_item,
    calculate_shipping,
)
from app.services.tax_service import estimate_tax

router = APIRouter(tags=["shop"])


# ── Products (public) ────────────────────────────────────────────────


@router.get("/shop/products", response_model=ProductList)
async def list_products(
    flavor: str | None = None,
    sort: str = Query("name", pattern="^(price_asc|price_desc|name)$"),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    result = await get_products(db, flavor=flavor, sort_by=sort, page=page, per_page=per_page)
    return ProductList(
        items=[ProductOut.model_validate(p) for p in result["items"]],
        total=result["total"],
    )


@router.get("/shop/products/{product_id}", response_model=ProductOut)
async def product_detail(
    product_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    product = await get_product(db, product_id)
    return ProductOut.model_validate(product)


# ── Cart (auth required) ─────────────────────────────────────────────


@router.post("/cart/add", response_model=CartOut)
async def add_cart_item(
    body: CartItemAdd,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await add_to_cart(db, user.id, body.product_id, body.quantity)


@router.get("/cart", response_model=CartOut)
async def view_cart(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await get_cart(db, user.id)


@router.put("/cart/{item_id}", response_model=CartOut)
async def update_cart(
    item_id: uuid.UUID,
    body: CartItemUpdate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await update_cart_item(db, user.id, item_id, body.quantity)


@router.delete("/cart/{item_id}", response_model=CartOut)
async def delete_cart_item(
    item_id: uuid.UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await remove_from_cart(db, user.id, item_id)


# ── Tax estimate (auth required) ─────────────────────────────────────


@router.post("/tax/estimate", response_model=TaxEstimate)
async def tax_estimate(
    address: ShippingAddress,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    cart = await get_cart(db, user.id)
    subtotal = cart["subtotal"]
    result = await estimate_tax(subtotal, address.state)
    return TaxEstimate(**result)


# ── Orders (auth required) ───────────────────────────────────────────


@router.post("/orders/create", response_model=OrderOut)
async def checkout(
    body: OrderCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    address_dict = body.shipping_address.model_dump()
    order = await create_order(db, user.id, address_dict, body.age_verification_id)
    return _order_to_response(order)


@router.get("/orders", response_model=OrderList)
async def order_history(
    page: int = Query(1, ge=1),
    per_page: int = Query(10, ge=1, le=50),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await get_orders(db, user.id, page=page, per_page=per_page)
    return OrderList(
        items=[_order_to_response(o) for o in result["items"]],
        total=result["total"],
        page=result["page"],
        per_page=result["per_page"],
    )


@router.get("/orders/{order_id}", response_model=OrderOut)
async def order_detail(
    order_id: uuid.UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    order = await get_order(db, user.id, order_id)
    return _order_to_response(order)


def _order_to_response(order) -> OrderOut:
    """Convert Order ORM object to OrderOut schema."""
    from app.api.schemas.shop import OrderItemOut, ShippingAddress

    items = []
    for oi in order.items:
        product_name = oi.product.name if oi.product else "Unknown"
        items.append(OrderItemOut(
            product_id=oi.product_id,
            product_name=product_name,
            quantity=oi.quantity,
            unit_price=oi.unit_price,
            line_total=oi.unit_price * oi.quantity,
        ))

    shipping_address = None
    if order.shipping_address_json:
        shipping_address = ShippingAddress(**order.shipping_address_json)

    return OrderOut(
        id=order.id,
        status=order.status,
        subtotal=order.subtotal,
        shipping=order.shipping,
        tax=order.tax,
        total=order.total,
        items=items,
        shipping_address=shipping_address,
        tracking_number=order.tracking_number,
        created_at=order.created_at,
    )
