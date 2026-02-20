"""Avatar upload service — stores user profile images in Google Cloud Storage.

Accepts image bytes (JPEG/PNG/WebP), validates MIME type, resizes to a
standard 256×256 square, and writes to GCS_BUCKET_AVATARS.

The public URL is https://storage.googleapis.com/{bucket}/{object} when
the object is publicly readable, which is the expected bucket ACL.

Settings used:
  GCS_PROJECT_ID        — GCP project
  GCS_BUCKET_AVATARS    — bucket name for user avatar images

Falls back gracefully if google-cloud-storage is not installed or
credentials are unavailable (returns None instead of raising).
"""

import io
import logging
import uuid
from typing import BinaryIO

from app.core.config import settings

logger = logging.getLogger(__name__)

ALLOWED_MIME_TYPES = {"image/jpeg", "image/png", "image/webp"}
AVATAR_SIZE = (256, 256)
AVATAR_QUALITY = 85  # JPEG quality when re-encoding


def _get_gcs_client():
    """Lazy-load GCS client; returns None if unavailable."""
    try:
        from google.cloud import storage  # type: ignore
        return storage.Client(project=settings.GCS_PROJECT_ID)
    except Exception as exc:
        logger.warning("GCS client unavailable: %s", exc)
        return None


def _resize_image(image_bytes: bytes, content_type: str) -> bytes:
    """Resize image to AVATAR_SIZE, returning JPEG bytes.

    Uses Pillow.  If Pillow is not installed, returns the original bytes
    unchanged (upload proceeds without resize).
    """
    try:
        from PIL import Image  # type: ignore

        img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        img.thumbnail(AVATAR_SIZE, Image.LANCZOS)

        # Create a square canvas and paste centred
        canvas = Image.new("RGB", AVATAR_SIZE, (255, 255, 255))
        offset = ((AVATAR_SIZE[0] - img.size[0]) // 2, (AVATAR_SIZE[1] - img.size[1]) // 2)
        canvas.paste(img, offset)

        out = io.BytesIO()
        canvas.save(out, format="JPEG", quality=AVATAR_QUALITY, optimize=True)
        return out.getvalue()
    except ImportError:
        logger.debug("Pillow not installed — skipping image resize")
        return image_bytes
    except Exception as exc:
        logger.warning("Image resize failed: %s — uploading original", exc)
        return image_bytes


async def upload_avatar(
    user_id: uuid.UUID,
    image_data: bytes | BinaryIO,
    content_type: str,
) -> str | None:
    """Upload a user avatar to GCS and return the public URL.

    Args:
        user_id: The user's UUID (used as the GCS object name prefix).
        image_data: Raw image bytes or a file-like object.
        content_type: MIME type of the image (must be JPEG, PNG, or WebP).

    Returns:
        Public GCS URL string on success, or None on failure.

    Raises:
        ValueError: If the content_type is not in ALLOWED_MIME_TYPES.
    """
    if content_type not in ALLOWED_MIME_TYPES:
        raise ValueError(
            f"Unsupported image type '{content_type}'. "
            f"Allowed: {', '.join(ALLOWED_MIME_TYPES)}"
        )

    if hasattr(image_data, "read"):
        image_bytes = image_data.read()
    else:
        image_bytes = image_data  # type: ignore[assignment]

    # Resize / normalise
    processed = _resize_image(image_bytes, content_type)
    final_content_type = "image/jpeg"

    object_name = f"avatars/{user_id}/avatar.jpg"

    client = _get_gcs_client()
    if client is None:
        logger.warning("GCS unavailable — avatar not uploaded for user %s", user_id)
        return None

    try:
        bucket = client.bucket(settings.GCS_BUCKET_AVATARS)
        blob = bucket.blob(object_name)
        blob.upload_from_string(processed, content_type=final_content_type)
        blob.make_public()

        public_url = f"https://storage.googleapis.com/{settings.GCS_BUCKET_AVATARS}/{object_name}"
        logger.info("Avatar uploaded for user %s: %s", user_id, public_url)
        return public_url

    except Exception as exc:
        logger.error("GCS avatar upload failed for user %s: %s", user_id, exc)
        return None


async def delete_avatar(user_id: uuid.UUID) -> bool:
    """Delete a user's avatar from GCS.

    Args:
        user_id: The user's UUID.

    Returns:
        True if deleted, False if not found or GCS unavailable.
    """
    client = _get_gcs_client()
    if client is None:
        return False

    object_name = f"avatars/{user_id}/avatar.jpg"
    try:
        bucket = client.bucket(settings.GCS_BUCKET_AVATARS)
        blob = bucket.blob(object_name)
        blob.delete()
        logger.info("Avatar deleted for user %s", user_id)
        return True
    except Exception as exc:
        logger.warning("Avatar delete failed for user %s: %s", user_id, exc)
        return False


def get_avatar_url(user_id: uuid.UUID) -> str:
    """Return the expected GCS public URL for a user's avatar.

    Does NOT verify the object exists — use for URL construction only.
    """
    return (
        f"https://storage.googleapis.com/{settings.GCS_BUCKET_AVATARS}"
        f"/avatars/{user_id}/avatar.jpg"
    )
