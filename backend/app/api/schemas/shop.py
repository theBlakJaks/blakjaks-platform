import uuid
from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field


# --- Products ---


class ProductOut(BaseModel):
    id: uuid.UUID
    name: str
    description: str | None
    price: Decimal
    flavor: str | None
    nicotine_strength: str | None
    image_url: str | None
    stock: int
    is_active: bool

    model_config = {"from_attributes": True}


class ProductList(BaseModel):
    items: list[ProductOut]
    total: int


# --- Cart ---


class CartItemAdd(BaseModel):
    product_id: uuid.UUID
    quantity: int = Field(ge=1, le=100)


class CartItemUpdate(BaseModel):
    quantity: int = Field(ge=0, le=100)


class CartItemOut(BaseModel):
    id: uuid.UUID
    product_id: uuid.UUID
    product_name: str
    product_image: str | None
    quantity: int
    unit_price: Decimal
    line_total: Decimal

    model_config = {"from_attributes": True}


class CartOut(BaseModel):
    items: list[CartItemOut]
    subtotal: Decimal
    item_count: int


# --- Shipping & Tax ---


class ShippingAddress(BaseModel):
    line1: str = Field(min_length=1, max_length=255)
    line2: str | None = None
    city: str = Field(min_length=1, max_length=100)
    state: str = Field(min_length=2, max_length=2)
    zip_code: str = Field(min_length=5, max_length=10)
    country: str = "US"


class TaxEstimate(BaseModel):
    subtotal: Decimal
    tax_amount: Decimal
    tax_rate: Decimal
    total: Decimal


# --- Orders ---


class OrderCreate(BaseModel):
    shipping_address: ShippingAddress
    age_verification_id: str = Field(min_length=1)
    payment_method_token: str | None = None


class OrderItemOut(BaseModel):
    product_id: uuid.UUID
    product_name: str
    quantity: int
    unit_price: Decimal
    line_total: Decimal

    model_config = {"from_attributes": True}


class OrderOut(BaseModel):
    id: uuid.UUID
    status: str
    subtotal: Decimal
    shipping: Decimal
    tax: Decimal
    total: Decimal
    items: list[OrderItemOut]
    shipping_address: ShippingAddress | None
    tracking_number: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class OrderList(BaseModel):
    items: list[OrderOut]
    total: int
    page: int
    per_page: int
