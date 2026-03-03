"""WebSocket endpoint for real-time chat messaging.

Uses Redis pub/sub so messages broadcast across all backend replicas.
"""

import asyncio
import json
import logging
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from jose import JWTError
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import decode_token
from app.db.session import async_session_factory
from app.models.user import User
from app.services.chat_service import send_message, add_reaction, remove_reaction, _can_access_channel
from app.models.channel import Channel
from app.models.message import Message
from app.services.redis_client import get_redis

logger = logging.getLogger(__name__)

router = APIRouter(tags=["social-ws"])


# ── Connection manager (Redis pub/sub) ───────────────────────────────


class ConnectionManager:
    """Manages active WebSocket connections per channel.

    Every broadcast is published to Redis so that all backend pods receive
    the message.  A background subscriber task listens on ``chat:*`` and
    delivers incoming messages to the local WebSocket connections.
    """

    CHANNEL_PREFIX = "chat:"

    def __init__(self):
        # channel_id -> set of (websocket, user_id)
        self.channels: dict[uuid.UUID, set[tuple[WebSocket, uuid.UUID]]] = {}
        self._subscriber_task: asyncio.Task | None = None
        self._running = False

    # ── lifecycle ────────────────────────────────────────────────────

    async def start_subscriber(self):
        """Start the Redis pub/sub listener.  Called from FastAPI lifespan."""
        self._running = True
        self._subscriber_task = asyncio.create_task(self._redis_listener())
        logger.info("Redis pub/sub subscriber started for chat.")

    async def stop_subscriber(self):
        """Stop the Redis pub/sub listener.  Called from FastAPI lifespan."""
        self._running = False
        if self._subscriber_task:
            self._subscriber_task.cancel()
            try:
                await self._subscriber_task
            except asyncio.CancelledError:
                pass
            self._subscriber_task = None
        logger.info("Redis pub/sub subscriber stopped.")

    # ── Redis listener ───────────────────────────────────────────────

    async def _redis_listener(self):
        """Subscribe to ``chat:*`` and deliver messages to local sockets."""
        while self._running:
            try:
                redis = await get_redis()
                # Create a *separate* connection for subscribe (required by
                # redis-py: a subscribed connection cannot issue other cmds).
                pubsub = redis.pubsub()
                await pubsub.psubscribe(f"{self.CHANNEL_PREFIX}*")
                logger.info("Subscribed to Redis pattern %s*", self.CHANNEL_PREFIX)

                async for raw_msg in pubsub.listen():
                    if not self._running:
                        break
                    if raw_msg["type"] not in ("pmessage",):
                        continue

                    # raw_msg["channel"] is e.g. "chat:<uuid>"
                    chan_name: str = raw_msg["channel"]
                    try:
                        channel_id = uuid.UUID(chan_name[len(self.CHANNEL_PREFIX):])
                    except (ValueError, IndexError):
                        continue

                    data: dict = json.loads(raw_msg["data"])
                    await self._deliver_local(channel_id, data)

                await pubsub.punsubscribe()
                await pubsub.aclose()
            except asyncio.CancelledError:
                raise
            except Exception:
                logger.exception("Redis subscriber error — reconnecting in 2s")
                await asyncio.sleep(2)

    async def _deliver_local(self, channel_id: uuid.UUID, message: dict):
        """Send a message to all local WebSocket connections for a channel."""
        conns = self.channels.get(channel_id)
        if not conns:
            return
        for ws, _ in list(conns):
            try:
                await ws.send_json(message)
            except Exception:
                pass

    # ── public API ───────────────────────────────────────────────────

    async def join(self, channel_id: uuid.UUID, websocket: WebSocket, user_id: uuid.UUID):
        self.channels.setdefault(channel_id, set()).add((websocket, user_id))

    async def leave(self, channel_id: uuid.UUID, websocket: WebSocket, user_id: uuid.UUID):
        if channel_id in self.channels:
            self.channels[channel_id].discard((websocket, user_id))
            if not self.channels[channel_id]:
                del self.channels[channel_id]

    async def leave_all(self, websocket: WebSocket, user_id: uuid.UUID):
        for channel_id in list(self.channels.keys()):
            self.channels[channel_id].discard((websocket, user_id))
            if not self.channels[channel_id]:
                del self.channels[channel_id]

    async def broadcast(self, channel_id: uuid.UUID, message: dict, exclude_ws: WebSocket | None = None):
        """Publish a message to Redis.  The subscriber delivers it locally."""
        try:
            redis = await get_redis()
            await redis.publish(
                f"{self.CHANNEL_PREFIX}{channel_id}",
                json.dumps(message, default=str),
            )
        except Exception:
            logger.exception("Failed to publish chat message to Redis")
            # Fallback: deliver directly to local connections only
            await self._deliver_local(channel_id, message)

    async def publish_to_redis(self, channel_id: uuid.UUID, message: dict):
        """Publish an event (e.g. reaction update) from outside the WS handler."""
        await self.broadcast(channel_id, message)


manager = ConnectionManager()


# ── WebSocket endpoint ───────────────────────────────────────────────


@router.websocket("/social/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()

    # Authenticate via query param or first message
    token = websocket.query_params.get("token")
    user_id: uuid.UUID | None = None

    if token:
        user_id = _authenticate_token(token)

    if user_id is None:
        # Wait for auth message
        try:
            data = await websocket.receive_json()
            if data.get("type") == "auth" and data.get("token"):
                user_id = _authenticate_token(data["token"])
        except Exception:
            pass

    if user_id is None:
        await websocket.send_json({"type": "error", "message": "Authentication failed"})
        await websocket.close(code=4001)
        return

    await websocket.send_json({"type": "auth_success", "user_id": str(user_id)})

    try:
        while True:
            data = await websocket.receive_json()
            msg_type = data.get("type")

            if msg_type == "join_channel":
                channel_id = uuid.UUID(data["channel_id"])
                async with async_session_factory() as db:
                    ch_result = await db.execute(select(Channel).where(Channel.id == channel_id))
                    channel = ch_result.scalar_one_or_none()
                    if channel and await _can_access_channel(db, user_id, channel):
                        await manager.join(channel_id, websocket, user_id)
                        await websocket.send_json({"type": "joined", "channel_id": str(channel_id)})
                    else:
                        await websocket.send_json({"type": "error", "message": "Cannot join channel"})

            elif msg_type == "leave_channel":
                channel_id = uuid.UUID(data["channel_id"])
                await manager.leave(channel_id, websocket, user_id)
                await websocket.send_json({"type": "left", "channel_id": str(channel_id)})

            elif msg_type == "send_message":
                channel_id = uuid.UUID(data["channel_id"])
                content = data.get("content", "")
                reply_to_id = uuid.UUID(data["reply_to_id"]) if data.get("reply_to_id") else None

                async with async_session_factory() as db:
                    result = await send_message(db, channel_id, user_id, content, reply_to_id)
                    if isinstance(result, str):
                        await websocket.send_json({"type": "error", "message": result})
                    else:
                        # Get username and avatar
                        user_result = await db.execute(
                            select(User.username, User.avatar_url).where(User.id == user_id)
                        )
                        user_row = user_result.one_or_none()
                        username = user_row[0] if user_row else "Unknown"
                        avatar_url = user_row[1] if user_row else None

                        msg_data = {
                            "type": "new_message",
                            "id": str(result.id),
                            "channel_id": str(result.channel_id),
                            "user_id": str(result.user_id),
                            "username": username,
                            "avatar_url": avatar_url,
                            "content": result.content,
                            "reply_to_id": str(result.reply_to_id) if result.reply_to_id else None,
                            "is_pinned": result.is_pinned,
                            "is_system": result.is_system,
                            "created_at": result.created_at.isoformat() if result.created_at else None,
                        }
                        await manager.broadcast(channel_id, msg_data)

            elif msg_type == "add_reaction":
                message_id = uuid.UUID(data["message_id"])
                emoji = data.get("emoji", "")
                channel_id_str = data.get("channel_id")
                async with async_session_factory() as db:
                    result = await add_reaction(db, message_id, user_id, emoji)
                    if isinstance(result, str):
                        await websocket.send_json({"type": "error", "message": result})
                    elif channel_id_str:
                        await manager.broadcast(
                            uuid.UUID(channel_id_str),
                            {"type": "reaction_update", "message_id": str(message_id),
                             "emoji": emoji, "user_id": str(user_id), "action": "add"},
                        )

            elif msg_type == "remove_reaction":
                message_id = uuid.UUID(data["message_id"])
                emoji = data.get("emoji", "")
                channel_id_str = data.get("channel_id")
                async with async_session_factory() as db:
                    await remove_reaction(db, message_id, user_id, emoji)
                    if channel_id_str:
                        await manager.broadcast(
                            uuid.UUID(channel_id_str),
                            {"type": "reaction_update", "message_id": str(message_id),
                             "emoji": emoji, "user_id": str(user_id), "action": "remove"},
                        )

            elif msg_type == "typing":
                channel_id = uuid.UUID(data["channel_id"])
                async with async_session_factory() as db:
                    user_result = await db.execute(select(User.username).where(User.id == user_id))
                    username = user_result.scalar_one_or_none() or "Unknown"
                await manager.broadcast(
                    channel_id,
                    {"type": "typing", "channel_id": str(channel_id), "user_id": str(user_id), "username": username},
                )

    except WebSocketDisconnect:
        pass
    except Exception as e:
        logger.exception("WebSocket error: %s", e)
    finally:
        await manager.leave_all(websocket, user_id)


def _authenticate_token(token: str) -> uuid.UUID | None:
    """Validate a JWT token and return the user_id, or None."""
    try:
        payload = decode_token(token)
        if payload.get("type") != "access":
            return None
        return uuid.UUID(payload["sub"])
    except (JWTError, KeyError, ValueError):
        return None
