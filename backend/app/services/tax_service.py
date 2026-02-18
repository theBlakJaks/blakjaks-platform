"""Sales tax estimation — placeholder using state-based lookup.

Real Kintsugi API integration will replace this when we have their full API docs.
"""

from decimal import Decimal

# State tax rates (placeholder — real rates come from Kintsugi API)
STATE_TAX_RATES: dict[str, Decimal] = {
    "CA": Decimal("7.25"),
    "TX": Decimal("6.25"),
    "FL": Decimal("6.00"),
    "NY": Decimal("8.00"),
}
DEFAULT_TAX_RATE = Decimal("5.00")


async def estimate_tax(subtotal: Decimal, state: str) -> dict:
    """Estimate sales tax for a given subtotal and state.

    Returns dict with subtotal, tax_amount, tax_rate, total.
    """
    rate = STATE_TAX_RATES.get(state.upper(), DEFAULT_TAX_RATE)
    tax_amount = (subtotal * rate / Decimal("100")).quantize(Decimal("0.01"))
    return {
        "subtotal": subtotal,
        "tax_amount": tax_amount,
        "tax_rate": rate,
        "total": subtotal + tax_amount,
    }
