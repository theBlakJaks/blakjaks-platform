"""Tests for avatar_service.py — mocks GCS, no real uploads."""

import uuid
import pytest
from unittest.mock import MagicMock, patch


def test_get_avatar_url_format():
    from app.services.avatar_service import get_avatar_url
    from app.core.config import settings

    uid = uuid.uuid4()
    with patch.object(settings, "GCS_BUCKET_AVATARS", "test-bucket"):
        url = get_avatar_url(uid)

    assert url.startswith("https://storage.googleapis.com/test-bucket/")
    assert str(uid) in url
    assert url.endswith("avatar.jpg")


@pytest.mark.asyncio
async def test_upload_avatar_raises_for_invalid_content_type():
    from app.services.avatar_service import upload_avatar

    with pytest.raises(ValueError, match="Unsupported image type"):
        await upload_avatar(uuid.uuid4(), b"fake", "image/gif")


@pytest.mark.asyncio
async def test_upload_avatar_returns_none_when_gcs_unavailable():
    from app.services.avatar_service import upload_avatar

    with patch("app.services.avatar_service._get_gcs_client", return_value=None):
        result = await upload_avatar(uuid.uuid4(), b"\xff\xd8\xff", "image/jpeg")

    assert result is None


@pytest.mark.asyncio
async def test_upload_avatar_returns_public_url_on_success():
    from app.services.avatar_service import upload_avatar
    from app.core.config import settings

    uid = uuid.uuid4()

    mock_blob = MagicMock()
    mock_blob.upload_from_string = MagicMock()
    mock_blob.make_public = MagicMock()

    mock_bucket = MagicMock()
    mock_bucket.blob.return_value = mock_blob

    mock_client = MagicMock()
    mock_client.bucket.return_value = mock_bucket

    with patch("app.services.avatar_service._get_gcs_client", return_value=mock_client), \
         patch("app.services.avatar_service._resize_image", return_value=b"resized-jpeg"), \
         patch.object(settings, "GCS_BUCKET_AVATARS", "test-avatars"):
        result = await upload_avatar(uid, b"\xff\xd8\xff", "image/jpeg")

    assert result is not None
    assert "test-avatars" in result
    assert str(uid) in result
    mock_blob.upload_from_string.assert_called_once_with(b"resized-jpeg", content_type="image/jpeg")
    mock_blob.make_public.assert_called_once()


@pytest.mark.asyncio
async def test_upload_avatar_returns_none_on_gcs_error():
    from app.services.avatar_service import upload_avatar

    mock_blob = MagicMock()
    mock_blob.upload_from_string = MagicMock(side_effect=Exception("GCS error"))

    mock_bucket = MagicMock()
    mock_bucket.blob.return_value = mock_blob

    mock_client = MagicMock()
    mock_client.bucket.return_value = mock_bucket

    with patch("app.services.avatar_service._get_gcs_client", return_value=mock_client), \
         patch("app.services.avatar_service._resize_image", return_value=b"data"):
        result = await upload_avatar(uuid.uuid4(), b"data", "image/png")

    assert result is None


@pytest.mark.asyncio
async def test_delete_avatar_returns_false_when_gcs_unavailable():
    from app.services.avatar_service import delete_avatar

    with patch("app.services.avatar_service._get_gcs_client", return_value=None):
        result = await delete_avatar(uuid.uuid4())

    assert result is False


@pytest.mark.asyncio
async def test_delete_avatar_returns_true_on_success():
    from app.services.avatar_service import delete_avatar

    mock_blob = MagicMock()
    mock_blob.delete = MagicMock()

    mock_bucket = MagicMock()
    mock_bucket.blob.return_value = mock_blob

    mock_client = MagicMock()
    mock_client.bucket.return_value = mock_bucket

    with patch("app.services.avatar_service._get_gcs_client", return_value=mock_client):
        result = await delete_avatar(uuid.uuid4())

    assert result is True
    mock_blob.delete.assert_called_once()


@pytest.mark.asyncio
async def test_delete_avatar_returns_false_on_error():
    from app.services.avatar_service import delete_avatar

    mock_blob = MagicMock()
    mock_blob.delete = MagicMock(side_effect=Exception("not found"))

    mock_bucket = MagicMock()
    mock_bucket.blob.return_value = mock_blob

    mock_client = MagicMock()
    mock_client.bucket.return_value = mock_bucket

    with patch("app.services.avatar_service._get_gcs_client", return_value=mock_client):
        result = await delete_avatar(uuid.uuid4())

    assert result is False
