"""Avatar image validation and processing."""

import io
from pathlib import Path

from PIL import Image

ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".gif", ".webp"}
ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/gif", "image/webp"}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB
MIN_DIMENSIONS = (64, 64)
MAX_DIMENSIONS = (4096, 4096)

AVATAR_SIZES = {
    "original": 512,
    "medium": 128,
    "small": 48,
    "tiny": 24,
}


def validate_image_file(
    filename: str | None,
    content_type: str | None,
    file_size: int,
) -> str | None:
    """Validate file metadata. Returns error message or None if valid."""
    if not filename:
        return "No filename provided."

    ext = Path(filename).suffix.lower()
    if ext not in ALLOWED_EXTENSIONS:
        return f"Invalid file type. Allowed: {', '.join(ALLOWED_EXTENSIONS)}"

    if content_type and content_type not in ALLOWED_CONTENT_TYPES:
        return f"Invalid content type: {content_type}"

    if file_size > MAX_FILE_SIZE:
        return f"File too large. Maximum size is {MAX_FILE_SIZE // (1024 * 1024)} MB."

    if file_size == 0:
        return "File is empty."

    return None


def validate_image_dimensions(image_bytes: bytes) -> str | None:
    """Validate image dimensions. Returns error message or None if valid."""
    try:
        img = Image.open(io.BytesIO(image_bytes))
        img.verify()  # Verify it's a valid image
    except Exception:
        return "Invalid or corrupted image file."

    # Re-open after verify (verify closes the file)
    img = Image.open(io.BytesIO(image_bytes))
    width, height = img.size

    if width < MIN_DIMENSIONS[0] or height < MIN_DIMENSIONS[1]:
        return f"Image too small. Minimum size is {MIN_DIMENSIONS[0]}x{MIN_DIMENSIONS[1]} pixels."

    if width > MAX_DIMENSIONS[0] or height > MAX_DIMENSIONS[1]:
        return f"Image too large. Maximum size is {MAX_DIMENSIONS[0]}x{MAX_DIMENSIONS[1]} pixels."

    return None


def process_avatar(image_bytes: bytes) -> dict[str, bytes]:
    """
    Process an approved avatar image into multiple sizes.

    Returns dict of size_name -> processed WebP bytes.
    """
    img = Image.open(io.BytesIO(image_bytes))

    # Convert to RGB/RGBA for WebP compatibility
    if img.mode not in ("RGB", "RGBA"):
        img = img.convert("RGBA" if "A" in (img.mode or "") else "RGB")

    # For animated GIFs, take the first frame only
    if hasattr(img, "n_frames") and img.n_frames > 1:
        img.seek(0)
        if img.mode == "P":
            img = img.convert("RGBA")

    # Center-crop to square
    width, height = img.size
    min_dim = min(width, height)
    left = (width - min_dim) // 2
    top = (height - min_dim) // 2
    img = img.crop((left, top, left + min_dim, top + min_dim))

    results = {}
    for name, size in AVATAR_SIZES.items():
        resized = img.resize((size, size), Image.Resampling.LANCZOS)
        buffer = io.BytesIO()
        resized.save(buffer, format="WEBP", quality=85)
        results[name] = buffer.getvalue()

    return results
