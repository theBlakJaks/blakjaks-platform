"""Transactional email service via Brevo (Sendinblue).

Uses Brevo HTTP API when BREVO_API_KEY is configured.
Falls back to logging when API key is not set (dev/test).
"""

import logging

import httpx

from app.core.config import settings

logger = logging.getLogger(__name__)

BREVO_API_URL = "https://api.brevo.com/v3/smtp/email"


async def send_email(to_email: str, subject: str, html_content: str) -> None:
    """Send a transactional email via Brevo API."""
    if not settings.BREVO_API_KEY:
        logger.info("EMAIL [dev] to=%s subject=%s\n%s", to_email, subject, html_content)
        return

    payload = {
        "sender": {"name": "BlakJaks", "email": "noreply@blakjaks.com"},
        "to": [{"email": to_email}],
        "subject": subject,
        "htmlContent": html_content,
    }
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                BREVO_API_URL,
                json=payload,
                headers={
                    "api-key": settings.BREVO_API_KEY,
                    "Content-Type": "application/json",
                },
                timeout=10.0,
            )
            if resp.status_code >= 400:
                logger.error("Brevo API error %d: %s", resp.status_code, resp.text)
            else:
                logger.info("Email sent to %s (messageId: %s)", to_email, resp.json().get("messageId"))
    except Exception:
        logger.exception("Failed to send email to %s", to_email)


async def send_verification_email(user_email: str, first_name: str, verify_url: str) -> None:
    """Email verification link on signup."""
    html = f"""
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <h2 style="color: #c9a84c;">Welcome to BlakJaks, {first_name}!</h2>
        <p>Please verify your email address to activate your account.</p>
        <a href="{verify_url}"
           style="display: inline-block; padding: 12px 32px; background: #c9a84c; color: #000;
                  text-decoration: none; border-radius: 8px; font-weight: bold; margin: 20px 0;">
            Verify Email
        </a>
        <p style="color: #888; font-size: 13px;">
            Or copy this link: <a href="{verify_url}">{verify_url}</a>
        </p>
        <p style="color: #888; font-size: 13px;">This link expires in 24 hours.</p>
    </div>
    """
    await send_email(user_email, "Verify Your BlakJaks Email", html)


async def send_welcome_email(user_email: str, first_name: str) -> None:
    """Welcome email on signup."""
    html = f"""
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <h2 style="color: #c9a84c;">Welcome to BlakJaks, {first_name}!</h2>
        <p>Your account is ready. Start exploring the platform.</p>
    </div>
    """
    await send_email(user_email, "Welcome to BlakJaks!", html)


async def send_order_confirmation(user_email: str, order: dict) -> None:
    """Order confirmation with order details."""
    html = f"""
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <h2>Order Confirmation</h2>
        <p>Order #{str(order.get('id', ''))[:8]}</p>
        <p>Total: ${order.get('total', '0.00')}</p>
    </div>
    """
    await send_email(user_email, f"Order Confirmation #{str(order.get('id', ''))[:8]}", html)


async def send_password_reset(user_email: str, reset_token: str, reset_url: str) -> None:
    """Password reset link email."""
    html = f"""
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <h2>Reset Your Password</h2>
        <p>Click the link below to reset your BlakJaks password.</p>
        <a href="{reset_url}"
           style="display: inline-block; padding: 12px 32px; background: #c9a84c; color: #000;
                  text-decoration: none; border-radius: 8px; font-weight: bold; margin: 20px 0;">
            Reset Password
        </a>
        <p style="color: #888; font-size: 13px;">This link expires in 60 minutes.</p>
    </div>
    """
    await send_email(user_email, "Reset Your BlakJaks Password", html)


async def send_comp_award(user_email: str, first_name: str, amount: str, comp_type: str) -> None:
    """Congratulations comp award notification."""
    html = f"""
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <h2 style="color: #c9a84c;">Congratulations, {first_name}!</h2>
        <p>You received <strong>${amount}</strong> in crypto comp ({comp_type}).</p>
    </div>
    """
    await send_email(user_email, f"Congratulations! You received ${amount} in crypto comp", html)


async def send_tier_advancement(user_email: str, first_name: str, new_tier_name: str) -> None:
    """Tier promotion notification."""
    html = f"""
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <h2 style="color: #c9a84c;">Congratulations, {first_name}!</h2>
        <p>You've been promoted to <strong>{new_tier_name}</strong>!</p>
    </div>
    """
    await send_email(user_email, f"You've been promoted to {new_tier_name}!", html)


async def send_withdrawal_confirmation(user_email: str, amount: str, tx_hash: str) -> None:
    """Withdrawal processed confirmation."""
    html = f"""
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <h2>Withdrawal Processed</h2>
        <p>Your withdrawal of <strong>${amount}</strong> has been processed.</p>
        <p style="color: #888; font-size: 13px;">Transaction: {tx_hash}</p>
    </div>
    """
    await send_email(user_email, f"Withdrawal of ${amount} Processed", html)


async def send_shipping_update(
    user_email: str, order_id: str, tracking_number: str, status: str
) -> None:
    """Order shipped/delivered notification."""
    html = f"""
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <h2>Shipping Update</h2>
        <p>Order #{order_id[:8]} — {status.title()}</p>
        <p>Tracking: {tracking_number}</p>
    </div>
    """
    await send_email(user_email, f"Order #{order_id[:8]} - {status.title()}", html)
