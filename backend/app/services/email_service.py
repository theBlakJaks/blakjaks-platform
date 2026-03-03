"""Transactional email service via Brevo (Sendinblue).

PLACEHOLDER: Logs email details instead of calling Brevo API.
Swap to real Brevo integration when API key is configured.
"""

import logging

from app.core.config import settings

logger = logging.getLogger(__name__)


async def send_email(to_email: str, template_name: str, template_data: dict) -> None:
    """Generic email sender via Brevo API.

    PLACEHOLDER: Logs the email instead of sending.
    TODO: Replace with real Brevo API call using settings.BREVO_API_KEY
    """
    logger.info(
        "EMAIL [%s] to=%s data=%s",
        template_name,
        to_email,
        template_data,
    )


async def send_welcome_email(user_email: str, first_name: str) -> None:
    """Welcome email on signup."""
    await send_email(user_email, "welcome", {
        "first_name": first_name,
        "subject": "Welcome to BlakJaks!",
    })


async def send_order_confirmation(user_email: str, order: dict) -> None:
    """Order confirmation with order details."""
    await send_email(user_email, "order_confirmation", {
        "order_id": str(order.get("id", "")),
        "subtotal": str(order.get("subtotal", "")),
        "shipping": str(order.get("shipping", "")),
        "tax": str(order.get("tax", "")),
        "total": str(order.get("total", "")),
        "item_count": order.get("item_count", 0),
        "subject": f"Order Confirmation #{str(order.get('id', ''))[:8]}",
    })


async def send_password_reset(user_email: str, reset_token: str, reset_url: str) -> None:
    """Password reset link email."""
    await send_email(user_email, "password_reset", {
        "reset_token": reset_token,
        "reset_url": reset_url,
        "subject": "Reset Your BlakJaks Password",
    })


async def send_comp_award(user_email: str, first_name: str, amount: str, comp_type: str) -> None:
    """Congratulations comp award notification."""
    await send_email(user_email, "comp_award", {
        "first_name": first_name,
        "amount": amount,
        "comp_type": comp_type,
        "subject": f"Congratulations! You received ${amount} in crypto comp",
    })


async def send_tier_advancement(user_email: str, first_name: str, new_tier_name: str) -> None:
    """Tier promotion notification."""
    await send_email(user_email, "tier_advancement", {
        "first_name": first_name,
        "new_tier_name": new_tier_name,
        "subject": f"You've been promoted to {new_tier_name}!",
    })


async def send_withdrawal_confirmation(user_email: str, amount: str, tx_hash: str) -> None:
    """Withdrawal processed confirmation."""
    await send_email(user_email, "withdrawal_confirmation", {
        "amount": amount,
        "tx_hash": tx_hash,
        "subject": f"Withdrawal of ${amount} Processed",
    })


async def send_shipping_update(
    user_email: str, order_id: str, tracking_number: str, status: str
) -> None:
    """Order shipped/delivered notification."""
    await send_email(user_email, "shipping_update", {
        "order_id": order_id,
        "tracking_number": tracking_number,
        "status": status,
        "subject": f"Order #{order_id[:8]} - {status.title()}",
    })
