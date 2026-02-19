"""WebSocket endpoint for real-time chat messaging."""

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
from app.services.chat_service import send_message, _can_access_channel
from app.models.channel import Channel

logger = logging.getLogger(__name__)

router = APIRouter(tags=["social-ws"])


# ── Connection manager ───────────────────────────────────────────────


class ConnectionManager:
    """Manages active WebSocket connections per channel."""

    def __init__(self):
        # channel_id -> set of (websocket, user_id)
        self.channels: dict[uuid.UUID, set[tuple[WebSocket, uuid.UUID]]] = {}

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
        if channel_id not in self.channels:
            return
        for ws, _ in list(self.channels[channel_id]):
            if ws == exclude_ws:
                continue
            try:
                await ws.send_json(message)
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

            elif msg_type == "typing":
                channel_id = uuid.UUID(data["channel_id"])
                async with async_session_factory() as db:
                    user_result = await db.execute(select(User.username).where(User.id == user_id))
                    username = user_result.scalar_one_or_none() or "Unknown"
                await manager.broadcast(
                    channel_id,
                    {"type": "typing", "channel_id": str(channel_id), "user_id": str(user_id), "username": username},
                    exclude_ws=websocket,
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
