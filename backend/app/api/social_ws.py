"""WebSocket endpoint for real-time chat messaging.

Uses Redis pub/sub so messages broadcast across all backend replicas.
Implements sequence numbering, replay, ACK tracking, presence, and
server-side pong validation for production-grade reliability.

Redis Key Schema (used by this handler + chat_buffer/chat_presence):
    channel:{channel_id}:seq              — Per-channel sequence counter (INCR)
    channel:{channel_id}:messages         — Message buffer sorted set (score=seq)
    stream:{stream_id}:messages           — Livestream buffer sorted set
    channel:{channel_id}:presence         — Connected user IDs (SET)
    presence:{channel_id}:{user_id}       — Heartbeat key (60s TTL)
    msg:idem:{idempotency_key}            — Idempotency dedup (5m TTL)
    chat:rate:{user_id}                   — Rate limit timestamp
    chat:spam:{user_id}                   — Spam detection list

WebSocket Close Codes:
    4000 — Resumable disconnect (missed pongs, server restart)
    4001 — Auth failure (not resumable, do not reconnect)
"""

import asyncio
import json
import logging
import time
import uuid
from dataclasses import dataclass, field

from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from jose import JWTError
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import decode_token
from app.db.session import async_session_factory
from app.models.channel import Channel
from app.models.message import Message
from app.models.user import User
from app.services.chat_ack import AckTracker
from app.services.chat_buffer import (
    buffer_message,
    get_buffer_range,
    get_messages_after,
    remove_message_by_sequence,
)
from app.services.chat_presence import (
    add_presence,
    refresh_presence,
    remove_presence,
)
from app.services.chat_service import (
    _can_access_channel,
    add_reaction,
    hard_delete_message,
    remove_reaction,
    send_message,
)
from app.services.redis_client import get_redis

logger = logging.getLogger(__name__)

router = APIRouter(tags=["social-ws"])


# ── Per-connection state ─────────────────────────────────────────────


@dataclass
class ConnectionState:
    """Tracks state for a single WebSocket connection."""

    websocket: WebSocket
    user_id: uuid.UUID
    connection_id: str = field(default_factory=lambda: str(uuid.uuid4()))
    joined_channels: set[uuid.UUID] = field(default_factory=set)
    ack_tracker: AckTracker | None = None
    last_pong: float = field(default_factory=time.time)
    missed_pongs: int = 0
    username: str = "Unknown"
    avatar_url: str | None = None


# ── Connection manager (Redis pub/sub) ───────────────────────────────


class ConnectionManager:
    """Manages active WebSocket connections per channel.

    Every broadcast is published to Redis so that all backend pods receive
    the message.  A background subscriber task listens on ``chat:*`` and
    delivers incoming messages to the local WebSocket connections.
    """

    CHANNEL_PREFIX = "chat:"

    def __init__(self):
        # connection_id -> ConnectionState
        self.connections: dict[str, ConnectionState] = {}
        # channel_id -> set of connection_ids
        self.channels: dict[uuid.UUID, set[str]] = {}
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
                pubsub = redis.pubsub()
                await pubsub.psubscribe(f"{self.CHANNEL_PREFIX}*")
                logger.info("Subscribed to Redis pattern %s*", self.CHANNEL_PREFIX)

                async for raw_msg in pubsub.listen():
                    if not self._running:
                        break
                    if raw_msg["type"] not in ("pmessage",):
                        continue

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
        conn_ids = self.channels.get(channel_id)
        if not conn_ids:
            return

        msg_type = message.get("type")
        sequence = message.get("sequence")

        for conn_id in list(conn_ids):
            state = self.connections.get(conn_id)
            if not state:
                continue
            try:
                await state.websocket.send_json(message)
                # Track ACK for new_message events only
                if msg_type == "new_message" and sequence and state.ack_tracker:
                    await state.ack_tracker.track(channel_id, sequence, message)
            except Exception:
                pass

    # ── public API ───────────────────────────────────────────────────

    def register(self, state: ConnectionState):
        """Register a new connection."""
        self.connections[state.connection_id] = state

    def unregister(self, connection_id: str):
        """Remove a connection from all tracking."""
        self.connections.pop(connection_id, None)

    async def join(self, channel_id: uuid.UUID, connection_id: str):
        """Add a connection to a channel."""
        self.channels.setdefault(channel_id, set()).add(connection_id)
        state = self.connections.get(connection_id)
        if state:
            state.joined_channels.add(channel_id)

    async def leave(self, channel_id: uuid.UUID, connection_id: str):
        """Remove a connection from a channel."""
        if channel_id in self.channels:
            self.channels[channel_id].discard(connection_id)
            if not self.channels[channel_id]:
                del self.channels[channel_id]
        state = self.connections.get(connection_id)
        if state:
            state.joined_channels.discard(channel_id)

    async def leave_all(self, connection_id: str):
        """Remove a connection from all channels."""
        state = self.connections.get(connection_id)
        if not state:
            return
        for channel_id in list(state.joined_channels):
            if channel_id in self.channels:
                self.channels[channel_id].discard(connection_id)
                if not self.channels[channel_id]:
                    del self.channels[channel_id]
        state.joined_channels.clear()

    async def broadcast(self, channel_id: uuid.UUID, message: dict):
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

    async def send_to_connection(self, connection_id: str, message: dict):
        """Send a message to a specific connection only."""
        state = self.connections.get(connection_id)
        if state:
            try:
                await state.websocket.send_json(message)
            except Exception:
                pass


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
        await websocket.send_json({"type": "error", "code": "AUTH_FAILED", "message": "Authentication failed"})
        await websocket.close(code=4001)
        return

    # Fetch user info for broadcasts
    username = "Unknown"
    avatar_url = None
    try:
        async with async_session_factory() as db:
            user_result = await db.execute(
                select(User.username, User.avatar_url).where(User.id == user_id)
            )
            row = user_result.one_or_none()
            if row:
                username = row[0]
                avatar_url = row[1]
    except Exception:
        pass

    # Create connection state
    conn_state = ConnectionState(
        websocket=websocket,
        user_id=user_id,
        username=username,
        avatar_url=avatar_url,
    )
    conn_state.ack_tracker = AckTracker(conn_state.connection_id, websocket)
    await conn_state.ack_tracker.start()
    manager.register(conn_state)

    await websocket.send_json({
        "type": "auth_success",
        "session_id": conn_state.connection_id,
        "user_id": str(user_id),
    })

    # ── Ping loop with pong validation ──

    async def _ping_loop():
        try:
            while True:
                await asyncio.sleep(20)
                conn_state.missed_pongs += 1
                if conn_state.missed_pongs >= 2:
                    logger.info(
                        "Connection %s missed 2 pongs — closing (4000)",
                        conn_state.connection_id,
                    )
                    await websocket.close(code=4000)
                    return
                await websocket.send_json({"type": "ping"})
        except Exception:
            pass

    ping_task = asyncio.create_task(_ping_loop())

    try:
        while True:
            data = await websocket.receive_json()
            msg_type = data.get("type")

            # ── pong ──
            if msg_type == "pong":
                conn_state.missed_pongs = 0
                conn_state.last_pong = time.time()
                # Refresh presence heartbeat for all joined channels
                for ch_id in conn_state.joined_channels:
                    try:
                        await refresh_presence(ch_id, user_id)
                    except Exception:
                        pass
                continue

            # ── ping (client-initiated, for RTT measurement) ──
            if msg_type == "ping":
                await websocket.send_json({"type": "pong"})
                continue

            # ── join_channel ──
            if msg_type == "join_channel":
                channel_id = uuid.UUID(data["channel_id"])
                async with async_session_factory() as db:
                    ch_result = await db.execute(select(Channel).where(Channel.id == channel_id))
                    channel = ch_result.scalar_one_or_none()
                    if channel and await _can_access_channel(db, user_id, channel):
                        await manager.join(channel_id, conn_state.connection_id)
                        await websocket.send_json({"type": "joined", "channel_id": str(channel_id)})

                        # Add to presence and broadcast
                        try:
                            await add_presence(channel_id, user_id)
                            await manager.broadcast(channel_id, {
                                "type": "presence_update",
                                "channel_id": str(channel_id),
                                "user_id": str(user_id),
                                "username": username,
                                "status": "online",
                            })
                        except Exception:
                            logger.debug("Presence update failed for join")
                    else:
                        await websocket.send_json({
                            "type": "error",
                            "code": "FORBIDDEN",
                            "message": "Cannot join channel",
                        })

            # ── leave_channel ──
            elif msg_type == "leave_channel":
                channel_id = uuid.UUID(data["channel_id"])
                await manager.leave(channel_id, conn_state.connection_id)
                await websocket.send_json({"type": "left", "channel_id": str(channel_id)})

                # Remove presence and broadcast
                try:
                    await remove_presence(channel_id, user_id)
                    await manager.broadcast(channel_id, {
                        "type": "presence_update",
                        "channel_id": str(channel_id),
                        "user_id": str(user_id),
                        "username": username,
                        "status": "offline",
                    })
                except Exception:
                    logger.debug("Presence update failed for leave")

            # ── resume ──
            elif msg_type == "resume":
                channel_id = uuid.UUID(data["channel_id"])
                last_sequence = int(data.get("last_sequence", 0))

                async with async_session_factory() as db:
                    ch_result = await db.execute(select(Channel).where(Channel.id == channel_id))
                    channel = ch_result.scalar_one_or_none()
                    if not channel or not await _can_access_channel(db, user_id, channel):
                        await websocket.send_json({
                            "type": "error",
                            "code": "CHANNEL_NOT_FOUND",
                            "message": "Channel not found or access denied",
                        })
                        continue

                # Join the channel if not already
                await manager.join(channel_id, conn_state.connection_id)

                # Add presence
                try:
                    await add_presence(channel_id, user_id)
                    await manager.broadcast(channel_id, {
                        "type": "presence_update",
                        "channel_id": str(channel_id),
                        "user_id": str(user_id),
                        "username": username,
                        "status": "online",
                    })
                except Exception:
                    pass

                # Fetch missed messages from buffer
                buf_range = await get_buffer_range(channel_id)
                buf_min, buf_max = buf_range

                if last_sequence == 0:
                    # Fresh connect — send entire buffer
                    full_resync = True
                    try:
                        missed = await get_messages_after(channel_id, 0)
                    except Exception:
                        missed = []
                    from_seq = buf_min or 0
                    to_seq = buf_max or 0
                elif buf_min is not None and last_sequence < buf_min:
                    # Client's sequence is older than buffer start — gap detected
                    full_resync = True
                    try:
                        missed = await get_messages_after(channel_id, 0)
                    except Exception:
                        missed = []
                    from_seq = buf_min
                    to_seq = buf_max or last_sequence
                else:
                    # Normal resume — fetch only messages after client's last sequence
                    full_resync = False
                    try:
                        missed = await get_messages_after(channel_id, last_sequence)
                    except Exception:
                        missed = []
                    from_seq = last_sequence
                    to_seq = buf_max or last_sequence

                await websocket.send_json({
                    "type": "replay_start",
                    "channel_id": str(channel_id),
                    "from_sequence": from_seq,
                    "to_sequence": to_seq,
                    "full_resync": full_resync,
                    "message_count": len(missed),
                })

                for msg in missed:
                    replay_msg = {**msg, "type": "replay_message"}
                    await websocket.send_json(replay_msg)

                await websocket.send_json({
                    "type": "replay_end",
                    "channel_id": str(channel_id),
                    "to_sequence": to_seq,
                })

            # ── send_message ──
            elif msg_type == "send_message":
                channel_id = uuid.UUID(data["channel_id"])
                content = data.get("content", "")
                reply_to_id = uuid.UUID(data["reply_to_id"]) if data.get("reply_to_id") else None
                idempotency_key = data.get("idempotency_key")

                async with async_session_factory() as db:
                    result = await send_message(
                        db, channel_id, user_id, content, reply_to_id, idempotency_key
                    )
                    if isinstance(result, str):
                        # Determine error code from message
                        code = "VALIDATION_ERROR"
                        if "rate limit" in result.lower():
                            code = "RATE_LIMITED"
                        elif "access" in result.lower() or "post" in result.lower():
                            code = "FORBIDDEN"
                        elif "muted" in result.lower():
                            code = "MUTED"
                        elif "spam" in result.lower():
                            code = "SPAM_DETECTED"
                        await websocket.send_json({
                            "type": "error",
                            "code": code,
                            "message": result,
                        })
                    else:
                        # Get reply preview data
                        reply_to_content = None
                        reply_to_username = None
                        if result.reply_to_id:
                            rp_result = await db.execute(
                                select(Message.content, Message.user_id).where(
                                    Message.id == result.reply_to_id
                                )
                            )
                            rp_row = rp_result.one_or_none()
                            if rp_row:
                                reply_to_content = rp_row[0][:100] if rp_row[0] else None
                                rp_user = await db.execute(
                                    select(User.username).where(User.id == rp_row[1])
                                )
                                reply_to_username = rp_user.scalar_one_or_none()

                        msg_data = {
                            "type": "new_message",
                            "id": str(result.id),
                            "channel_id": str(result.channel_id),
                            "user_id": str(result.user_id),
                            "username": username,
                            "avatar_url": avatar_url,
                            "content": result.content,
                            "sequence": result.sequence,
                            "timestamp": result.created_at.isoformat() if result.created_at else None,
                            "reply_to_id": str(result.reply_to_id) if result.reply_to_id else None,
                            "reply_to_content": reply_to_content,
                            "reply_to_username": reply_to_username,
                            "is_system": result.is_system,
                            "is_pinned": result.is_pinned,
                            "idempotency_key": idempotency_key,
                            "status": "sent",
                        }

                        # Buffer the message in Redis
                        if result.sequence:
                            try:
                                await buffer_message(channel_id, result.sequence, msg_data)
                            except Exception:
                                logger.warning("Failed to buffer message in Redis")

                        await manager.broadcast(channel_id, msg_data)

            # ── ack ──
            elif msg_type == "ack":
                channel_id = uuid.UUID(data["channel_id"])
                sequence = int(data["sequence"])
                if conn_state.ack_tracker:
                    conn_state.ack_tracker.acknowledge(channel_id, sequence)

            # ── delete_message (admin only) ──
            elif msg_type == "delete_message":
                message_id = uuid.UUID(data["message_id"])
                channel_id = uuid.UUID(data["channel_id"])

                async with async_session_factory() as db:
                    # Verify admin
                    user_result = await db.execute(
                        select(User.is_admin).where(User.id == user_id)
                    )
                    is_admin = user_result.scalar_one_or_none()
                    if not is_admin:
                        await websocket.send_json({
                            "type": "error",
                            "code": "FORBIDDEN",
                            "message": "Admin access required",
                        })
                        continue

                    deleted_msg = await hard_delete_message(db, message_id)
                    if deleted_msg:
                        # Remove from Redis buffer
                        if deleted_msg.sequence:
                            try:
                                await remove_message_by_sequence(
                                    channel_id, deleted_msg.sequence
                                )
                            except Exception:
                                logger.warning("Failed to remove message from Redis buffer")

                        await manager.broadcast(channel_id, {
                            "type": "message_deleted",
                            "message_id": str(message_id),
                            "channel_id": str(channel_id),
                            "deleted_by": str(user_id),
                        })
                    else:
                        await websocket.send_json({
                            "type": "error",
                            "code": "NOT_FOUND",
                            "message": "Message not found",
                        })

            # ── add_reaction ──
            elif msg_type == "add_reaction":
                message_id = uuid.UUID(data["message_id"])
                emoji = data.get("emoji", "")
                channel_id_str = data.get("channel_id")
                async with async_session_factory() as db:
                    result = await add_reaction(db, message_id, user_id, emoji)
                    if isinstance(result, str):
                        await websocket.send_json({"type": "error", "code": "VALIDATION_ERROR", "message": result})
                    elif channel_id_str:
                        await manager.broadcast(
                            uuid.UUID(channel_id_str),
                            {
                                "type": "reaction_update",
                                "message_id": str(message_id),
                                "channel_id": channel_id_str,
                                "emoji": emoji,
                                "user_id": str(user_id),
                                "action": "add",
                            },
                        )

            # ── remove_reaction ──
            elif msg_type == "remove_reaction":
                message_id = uuid.UUID(data["message_id"])
                emoji = data.get("emoji", "")
                channel_id_str = data.get("channel_id")
                async with async_session_factory() as db:
                    await remove_reaction(db, message_id, user_id, emoji)
                    if channel_id_str:
                        await manager.broadcast(
                            uuid.UUID(channel_id_str),
                            {
                                "type": "reaction_update",
                                "message_id": str(message_id),
                                "channel_id": channel_id_str,
                                "emoji": emoji,
                                "user_id": str(user_id),
                                "action": "remove",
                            },
                        )

            # ── typing ──
            elif msg_type == "typing":
                channel_id = uuid.UUID(data["channel_id"])
                await manager.broadcast(
                    channel_id,
                    {
                        "type": "typing",
                        "channel_id": str(channel_id),
                        "user_id": str(user_id),
                        "username": username,
                    },
                )

    except WebSocketDisconnect:
        pass
    except Exception as e:
        logger.exception("WebSocket error: %s", e)
    finally:
        ping_task.cancel()

        # Clean up presence for all joined channels
        for ch_id in list(conn_state.joined_channels):
            try:
                await remove_presence(ch_id, user_id)
                await manager.broadcast(ch_id, {
                    "type": "presence_update",
                    "channel_id": str(ch_id),
                    "user_id": str(user_id),
                    "username": username,
                    "status": "offline",
                })
            except Exception:
                pass

        # Stop ACK tracker
        if conn_state.ack_tracker:
            await conn_state.ack_tracker.stop()

        await manager.leave_all(conn_state.connection_id)
        manager.unregister(conn_state.connection_id)


def _authenticate_token(token: str) -> uuid.UUID | None:
    """Validate a JWT token and return the user_id, or None."""
    try:
        payload = decode_token(token)
        if payload.get("type") != "access":
            return None
        return uuid.UUID(payload["sub"])
    except (JWTError, KeyError, ValueError):
        return None
