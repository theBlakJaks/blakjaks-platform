"""Avatar file storage using Google Cloud Storage."""

import logging
import uuid

from google.cloud import storage

logger = logging.getLogger(__name__)

BUCKET_NAME = "blakjaks-avatars"
CDN_BASE = "https://storage.googleapis.com/blakjaks-avatars"


def _get_client() -> storage.Client:
    """Get GCS client using Application Default Credentials."""
    return storage.Client(project="blakjaks-production")


def upload_avatar_to_gcs(
    user_id: uuid.UUID,
    processed_images: dict[str, bytes],
) -> str:
    """
    Upload processed avatar images to GCS.

    Returns the base avatar path (e.g., "avatars/user_id").
    """
    client = _get_client()
    bucket = client.bucket(BUCKET_NAME)

    for size_name, image_bytes in processed_images.items():
        blob_path = f"{user_id}/{size_name}.webp"
        blob = bucket.blob(blob_path)
        blob.upload_from_string(
            image_bytes,
            content_type="image/webp",
        )
        blob.cache_control = "public, max-age=86400"
        blob.patch()

    base_path = f"avatars/{user_id}"
    logger.info("Uploaded avatar for user %s to GCS", user_id)
    return base_path


def delete_avatar_from_gcs(user_id: uuid.UUID) -> None:
    """Delete all avatar size variants from GCS."""
    client = _get_client()
    bucket = client.bucket(BUCKET_NAME)

    for size_name in ("original", "medium", "small", "tiny"):
        blob_path = f"{user_id}/{size_name}.webp"
        blob = bucket.blob(blob_path)
        try:
            blob.delete()
        except Exception:
            pass  # Ignore if already deleted

    logger.info("Deleted avatar for user %s from GCS", user_id)


def get_avatar_urls(user_id: uuid.UUID) -> dict[str, str]:
    """Get the CDN URLs for all avatar sizes."""
    base = f"{CDN_BASE}/{user_id}"
    return {
        "original": f"{base}/original.webp",
        "medium": f"{base}/medium.webp",
        "small": f"{base}/small.webp",
        "tiny": f"{base}/tiny.webp",
    }
