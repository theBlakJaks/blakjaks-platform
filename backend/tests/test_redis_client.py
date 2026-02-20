"""Tests for redis_client.py — verifies singleton behaviour and ping."""

import pytest
from unittest.mock import AsyncMock, patch

import app.services.redis_client as redis_module


@pytest.fixture(autouse=True)
async def reset_singleton():
    """Reset the module-level singleton between tests."""
    redis_module._redis_client = None
    yield
    if redis_module._redis_client is not None:
        await redis_module.close_redis()


@pytest.mark.asyncio
async def test_get_redis_returns_client():
    mock_redis = AsyncMock()
    with patch("app.services.redis_client.aioredis.from_url", return_value=mock_redis):
        client = await redis_module.get_redis()
        assert client is mock_redis


@pytest.mark.asyncio
async def test_get_redis_singleton():
    """Repeated calls return the same instance without re-initialising."""
    mock_redis = AsyncMock()
    with patch("app.services.redis_client.aioredis.from_url", return_value=mock_redis) as mock_factory:
        c1 = await redis_module.get_redis()
        c2 = await redis_module.get_redis()
        assert c1 is c2
        assert mock_factory.call_count == 1


@pytest.mark.asyncio
async def test_ping_redis_returns_true_on_success():
    mock_redis = AsyncMock()
    mock_redis.ping.return_value = True
    with patch("app.services.redis_client.aioredis.from_url", return_value=mock_redis):
        result = await redis_module.ping_redis()
    assert result is True


@pytest.mark.asyncio
async def test_ping_redis_returns_false_on_failure():
    mock_redis = AsyncMock()
    mock_redis.ping.side_effect = ConnectionError("redis unreachable")
    with patch("app.services.redis_client.aioredis.from_url", return_value=mock_redis):
        result = await redis_module.ping_redis()
    assert result is False


@pytest.mark.asyncio
async def test_close_redis_clears_singleton():
    mock_redis = AsyncMock()
    with patch("app.services.redis_client.aioredis.from_url", return_value=mock_redis):
        await redis_module.get_redis()
        await redis_module.close_redis()
    assert redis_module._redis_client is None
    mock_redis.aclose.assert_called_once()
