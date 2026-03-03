"""In-memory per-connection ACK tracker with retry logic.

Each WebSocket connection gets its own AckTracker instance. When a
new_message is sent to a client, it is tracked here. If the client
does not ACK the message within 10 seconds, the message is re-emitted
up to 3 times. After 3 failed retries, the message is dropped and
a warning is logged.

This is intentionally in-memory (not Redis) because ACK state is
ephemeral and per-connection — if the server dies, the client
reconnects and resumes via sequence numbers anyway.
"""

from __future__ import annotations

import asyncio
import logging
import time
import uuid
from dataclasses import dataclass, field

from fastapi import WebSocket

logger = logging.getLogger(__name__)

# How often the retry loop checks for unACKed messages
RETRY_CHECK_INTERVAL = 5.0
# How long to wait before retrying an unACKed message
ACK_TIMEOUT_SECONDS = 10.0
# Maximum retry attempts per message
MAX_RETRIES = 3


@dataclass
class PendingMessage:
    """A message awaiting ACK from the client."""

    sequence: int
    channel_id: uuid.UUID
    payload: dict
    retry_count: int = 0
    first_sent_at: float = field(default_factory=time.time)


class AckTracker:
    """Track pending ACKs for a single WebSocket connection.

    Usage:
        tracker = AckTracker(connection_id, websocket)
        await tracker.start()
        # ... on message send:
        await tracker.track(channel_id, sequence, payload)
        # ... on client ACK:
        tracker.acknowledge(channel_id, sequence)
        # ... on disconnect:
        await tracker.stop()
    """

    def __init__(self, connection_id: str, websocket: WebSocket) -> None:
        self._connection_id = connection_id
        self._ws = websocket
        # (channel_id, sequence) -> PendingMessage
        self._pending: dict[tuple[uuid.UUID, int], PendingMessage] = {}
        self._retry_task: asyncio.Task | None = None

    async def start(self) -> None:
        """Start the background retry loop."""
        self._retry_task = asyncio.create_task(self._retry_loop())

    async def stop(self) -> None:
        """Cancel the retry loop and clear pending messages."""
        if self._retry_task:
            self._retry_task.cancel()
            try:
                await self._retry_task
            except asyncio.CancelledError:
                pass
            self._retry_task = None
        self._pending.clear()

    async def track(
        self, channel_id: uuid.UUID, sequence: int, payload: dict
    ) -> None:
        """Register a message as pending ACK."""
        key = (channel_id, sequence)
        self._pending[key] = PendingMessage(
            sequence=sequence,
            channel_id=channel_id,
            payload=payload,
        )

    def acknowledge(self, channel_id: uuid.UUID, sequence: int) -> bool:
        """Mark a message as ACKed. Returns True if it was pending."""
        key = (channel_id, sequence)
        return self._pending.pop(key, None) is not None

    @property
    def pending_count(self) -> int:
        """Number of messages awaiting ACK."""
        return len(self._pending)

    async def _retry_loop(self) -> None:
        """Periodically check for unACKed messages and re-emit them."""
        try:
            while True:
                await asyncio.sleep(RETRY_CHECK_INTERVAL)
                now = time.time()
                to_remove: list[tuple[uuid.UUID, int]] = []

                for key, msg in list(self._pending.items()):
                    elapsed = now - msg.first_sent_at
                    if elapsed < ACK_TIMEOUT_SECONDS:
                        continue

                    if msg.retry_count >= MAX_RETRIES:
                        logger.warning(
                            "Message seq=%d ch=%s dropped after %d retries "
                            "(conn=%s)",
                            msg.sequence,
                            msg.channel_id,
                            MAX_RETRIES,
                            self._connection_id,
                        )
                        to_remove.append(key)
                        continue

                    # Re-emit the message
                    msg.retry_count += 1
                    msg.first_sent_at = now  # Reset timer for next retry
                    try:
                        await self._ws.send_json(msg.payload)
                        logger.debug(
                            "Retried message seq=%d ch=%s attempt=%d (conn=%s)",
                            msg.sequence,
                            msg.channel_id,
                            msg.retry_count,
                            self._connection_id,
                        )
                    except Exception:
                        # Connection is dead — will be cleaned up by disconnect
                        to_remove.append(key)

                for key in to_remove:
                    self._pending.pop(key, None)

        except asyncio.CancelledError:
            pass
