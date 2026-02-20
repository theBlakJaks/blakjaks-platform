"""Tests for giphy_service.py — mocks httpx, no real Giphy calls."""

import json
import pytest
from unittest.mock import AsyncMock, MagicMock, patch


def _make_gif(gif_id="abc123", title="Test GIF"):
    return {
        "id": gif_id,
        "title": title,
        "url": f"https://giphy.com/gifs/{gif_id}",
        "images": {
            "fixed_height": {
                "url": f"https://media.giphy.com/media/{gif_id}/200.gif",
                "mp4": f"https://media.giphy.com/media/{gif_id}/200.mp4",
                "width": "356",
                "height": "200",
            },
            "original": {
                "url": f"https://media.giphy.com/media/{gif_id}/giphy.gif",
                "mp4": f"https://media.giphy.com/media/{gif_id}/giphy.mp4",
            },
        },
    }


def _mock_redis(cached_value=None):
    mock = AsyncMock()
    mock.get = AsyncMock(return_value=cached_value)
    mock.setex = AsyncMock()
    return mock


def _mock_httpx_response(gifs: list):
    resp = MagicMock()
    resp.status_code = 200
    resp.json.return_value = {"data": gifs, "pagination": {"count": len(gifs)}}
    resp.raise_for_status = MagicMock()
    return resp


@pytest.mark.asyncio
async def test_search_gifs_returns_empty_when_no_api_key():
    from app.services.giphy_service import search_gifs
    from app.core.config import settings

    with patch.object(settings, "GIPHY_API_KEY", ""):
        results = await search_gifs("funny")

    assert results == []


@pytest.mark.asyncio
async def test_search_gifs_returns_results():
    from app.services.giphy_service import search_gifs
    from app.core.config import settings

    mock_resp = _mock_httpx_response([_make_gif("g1"), _make_gif("g2")])
    mock_redis = _mock_redis()

    mock_client = AsyncMock()
    mock_client.__aenter__ = AsyncMock(return_value=mock_client)
    mock_client.__aexit__ = AsyncMock(return_value=False)
    mock_client.get = AsyncMock(return_value=mock_resp)

    with patch.object(settings, "GIPHY_API_KEY", "fake-key"), \
         patch("app.services.giphy_service._get_redis", return_value=AsyncMock(return_value=mock_redis)), \
         patch("app.services.giphy_service.httpx.AsyncClient", return_value=mock_client):
        results = await search_gifs("cat")

    assert len(results) == 2
    assert results[0]["id"] == "g1"


@pytest.mark.asyncio
async def test_search_gifs_returns_cached_result():
    from app.services.giphy_service import search_gifs
    from app.core.config import settings

    cached_gifs = [{"id": "cached1", "title": "Cached"}]
    mock_redis = _mock_redis(cached_value=json.dumps(cached_gifs))

    with patch.object(settings, "GIPHY_API_KEY", "fake-key"), \
         patch("app.services.giphy_service._get_redis", return_value=AsyncMock(return_value=mock_redis)):
        results = await search_gifs("cats")

    assert results == cached_gifs
    # No httpx call should have been made
    mock_redis.setex.assert_not_called()


@pytest.mark.asyncio
async def test_search_gifs_returns_empty_on_http_error():
    from app.services.giphy_service import search_gifs
    from app.core.config import settings
    import httpx

    mock_redis = _mock_redis()
    mock_client = AsyncMock()
    mock_client.__aenter__ = AsyncMock(return_value=mock_client)
    mock_client.__aexit__ = AsyncMock(return_value=False)
    mock_client.get = AsyncMock(
        side_effect=httpx.HTTPStatusError(
            "429", request=MagicMock(), response=MagicMock(status_code=429)
        )
    )

    with patch.object(settings, "GIPHY_API_KEY", "fake-key"), \
         patch("app.services.giphy_service._get_redis", return_value=AsyncMock(return_value=mock_redis)), \
         patch("app.services.giphy_service.httpx.AsyncClient", return_value=mock_client):
        results = await search_gifs("error")

    assert results == []


@pytest.mark.asyncio
async def test_get_trending_gifs_returns_empty_when_no_api_key():
    from app.services.giphy_service import get_trending_gifs
    from app.core.config import settings

    with patch.object(settings, "GIPHY_API_KEY", ""):
        results = await get_trending_gifs()

    assert results == []


@pytest.mark.asyncio
async def test_get_trending_gifs_returns_results():
    from app.services.giphy_service import get_trending_gifs
    from app.core.config import settings

    mock_resp = _mock_httpx_response([_make_gif("t1"), _make_gif("t2"), _make_gif("t3")])
    mock_redis = _mock_redis()

    mock_client = AsyncMock()
    mock_client.__aenter__ = AsyncMock(return_value=mock_client)
    mock_client.__aexit__ = AsyncMock(return_value=False)
    mock_client.get = AsyncMock(return_value=mock_resp)

    with patch.object(settings, "GIPHY_API_KEY", "fake-key"), \
         patch("app.services.giphy_service._get_redis", return_value=AsyncMock(return_value=mock_redis)), \
         patch("app.services.giphy_service.httpx.AsyncClient", return_value=mock_client):
        results = await get_trending_gifs(limit=3)

    assert len(results) == 3


@pytest.mark.asyncio
async def test_get_trending_gifs_cached():
    from app.services.giphy_service import get_trending_gifs
    from app.core.config import settings

    cached = [{"id": "trend1", "title": "Trending"}]
    mock_redis = _mock_redis(cached_value=json.dumps(cached))

    with patch.object(settings, "GIPHY_API_KEY", "fake-key"), \
         patch("app.services.giphy_service._get_redis", return_value=AsyncMock(return_value=mock_redis)):
        results = await get_trending_gifs()

    assert results == cached


def test_extract_gif_fields():
    from app.services.giphy_service import _extract_gif

    raw = _make_gif("xyz789", "Funny Cat")
    result = _extract_gif(raw)

    assert result["id"] == "xyz789"
    assert result["title"] == "Funny Cat"
    assert "preview_url" in result
    assert "mp4_url" in result
