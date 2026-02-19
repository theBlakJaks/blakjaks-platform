"""Image content moderation using Google Cloud Vision SafeSearch."""

import logging
import time
import uuid
from collections import defaultdict
from enum import Enum

from google.cloud import vision

logger = logging.getLogger(__name__)


class ModerationResult(Enum):
    APPROVED = "approved"
    REJECTED_ADULT = "rejected_adult"
    REJECTED_VIOLENCE = "rejected_violence"
    REJECTED_RACY = "rejected_racy"
    SCAN_FAILED = "scan_failed"


# In-memory rate limiting (matches chat_service.py pattern)
_upload_counts: dict[str, list[float]] = defaultdict(list)  # user_id -> list of timestamps
_rejection_counts: dict[str, list[float]] = defaultdict(list)  # user_id -> list of rejection timestamps

MAX_UPLOADS_PER_HOUR = 5
MAX_UPLOADS_PER_DAY = 20
MAX_REJECTIONS_BEFORE_BLOCK = 3
BLOCK_WINDOW_SECONDS = 86400  # 24 hours


def _clean_timestamps(timestamps: list[float], window: float) -> list[float]:
    """Remove timestamps older than the given window."""
    now = time.time()
    return [t for t in timestamps if now - t < window]


def check_rate_limit(user_id: uuid.UUID) -> str | None:
    """Check if user is rate-limited. Returns error message or None if OK."""
    uid = str(user_id)

    # Check rejection block first
    _rejection_counts[uid] = _clean_timestamps(_rejection_counts[uid], BLOCK_WINDOW_SECONDS)
    if len(_rejection_counts[uid]) >= MAX_REJECTIONS_BEFORE_BLOCK:
        return "Too many rejected uploads. Avatar uploads temporarily blocked. Try again later."

    # Check hourly limit
    _upload_counts[uid] = _clean_timestamps(_upload_counts[uid], 3600)
    hourly = len([t for t in _upload_counts[uid] if time.time() - t < 3600])
    if hourly >= MAX_UPLOADS_PER_HOUR:
        return "Upload limit reached. Maximum 5 uploads per hour."

    # Check daily limit
    daily = len([t for t in _upload_counts[uid] if time.time() - t < BLOCK_WINDOW_SECONDS])
    if daily >= MAX_UPLOADS_PER_DAY:
        return "Upload limit reached. Maximum 20 uploads per day."

    return None


def record_upload(user_id: uuid.UUID) -> None:
    """Record an upload attempt for rate limiting."""
    _upload_counts[str(user_id)].append(time.time())


def record_rejection(user_id: uuid.UUID) -> None:
    """Record a moderation rejection."""
    _rejection_counts[str(user_id)].append(time.time())


def scan_image_for_explicit_content(image_bytes: bytes) -> dict:
    """
    Scan image using Google Cloud Vision SafeSearch Detection.

    Returns dict with:
      - result: ModerationResult
      - details: dict of category -> likelihood string
      - message: human-readable explanation
    """
    try:
        client = vision.ImageAnnotatorClient()
        image = vision.Image(content=image_bytes)
        response = client.safe_search_detection(image=image)

        if response.error.message:
            logger.error("Vision API error: %s", response.error.message)
            return {
                "result": ModerationResult.SCAN_FAILED,
                "details": {},
                "message": "Image scan failed. Please try again.",
            }

        safe = response.safe_search_annotation

        likelihood_name = (
            "UNKNOWN", "VERY_UNLIKELY", "UNLIKELY",
            "POSSIBLE", "LIKELY", "VERY_LIKELY",
        )

        details = {
            "adult": likelihood_name[safe.adult],
            "violence": likelihood_name[safe.violence],
            "racy": likelihood_name[safe.racy],
            "medical": likelihood_name[safe.medical],
            "spoof": likelihood_name[safe.spoof],
        }

        # Reject adult content (LIKELY or VERY_LIKELY)
        if safe.adult >= vision.Likelihood.LIKELY:
            return {
                "result": ModerationResult.REJECTED_ADULT,
                "details": details,
                "message": "Image rejected: contains adult content.",
            }

        # Reject violent content (LIKELY or VERY_LIKELY)
        if safe.violence >= vision.Likelihood.LIKELY:
            return {
                "result": ModerationResult.REJECTED_VIOLENCE,
                "details": details,
                "message": "Image rejected: contains violent content.",
            }

        # Reject very racy content (only VERY_LIKELY — LIKELY is too strict)
        if safe.racy >= vision.Likelihood.VERY_LIKELY:
            return {
                "result": ModerationResult.REJECTED_RACY,
                "details": details,
                "message": "Image rejected: contains inappropriate content.",
            }

        return {
            "result": ModerationResult.APPROVED,
            "details": details,
            "message": "Image approved.",
        }

    except Exception as e:
        logger.exception("Vision API scan failed: %s", e)
        return {
            "result": ModerationResult.SCAN_FAILED,
            "details": {},
            "message": "Image scan failed. Please try again.",
        }
