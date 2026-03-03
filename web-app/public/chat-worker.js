/**
 * BlakJaks Chat SharedWorker
 *
 * Manages a single ChatEngine instance shared across all browser tabs.
 * Each tab connects via a MessagePort. The worker:
 *   - Maintains one WebSocket connection regardless of tab count
 *   - Broadcasts all engine events to all connected ports
 *   - Routes tab commands to the engine
 *   - Tracks per-port visibility for passive mode
 *   - Caches last 50 messages per channel for new-tab hydration
 *   - Emits presence online/offline only on 0↔1 port transitions
 *
 * Debug: chrome://inspect/#workers (Chrome), about:debugging#workers (Firefox)
 */

/* global BlakJaksChat */
importScripts('/chat-worker-engine.js')

// ═══════════════════════════════════════════════════════════════════════════════
// State
// ═══════════════════════════════════════════════════════════════════════════════

/** @type {Set<MessagePort>} */
const ports = new Set()

/** @type {Set<MessagePort>} - ports whose tab is currently visible */
const visiblePorts = new Set()

/** @type {InstanceType<typeof BlakJaksChat.ChatEngine>} */
let engine = null

/** @type {string | null} - current auth token */
let currentToken = null

/** @type {Map<string, Array>} - channelId → last N messages for new-tab hydration */
const messageCache = new Map()
const MAX_CACHE_PER_CHANNEL = 50

/** @type {boolean} - whether engine is connected and serving */
let isConnected = false

/** @type {ReturnType<typeof setTimeout> | null} */
let passiveTimer = null

const PASSIVE_DELAY_MS = 30_000

// ═══════════════════════════════════════════════════════════════════════════════
// Engine setup
// ═══════════════════════════════════════════════════════════════════════════════

function initEngine() {
  engine = new BlakJaksChat.ChatEngine()

  // --- State change ---
  engine.on('stateChange', (state) => {
    isConnected = state === 'connected'
    broadcast({ type: 'STATE_UPDATE', state })
  })

  // --- Connection quality ---
  engine.on('qualityChange', (quality) => {
    broadcast({ type: 'CONNECTION_QUALITY', quality })
  })

  // --- Catching up ---
  engine.on('catchingUp', (catching) => {
    broadcast({ type: 'CATCHING_UP', catching })
  })

  // --- New message ---
  engine.on('message', (msg) => {
    cacheMessage(msg.channel_id, msg)
    broadcast({ type: 'MESSAGE', data: msg })
  })

  // --- Message confirmed (optimistic → sent) ---
  engine.on('messageConfirmed', (idempotencyKey, serverMsg) => {
    cacheMessage(serverMsg.channel_id, serverMsg)
    broadcast({ type: 'MESSAGE_CONFIRMED', idempotencyKey, serverMsg })
  })

  // --- Message failed ---
  engine.on('messageFailed', (idempotencyKey) => {
    broadcast({ type: 'MESSAGE_FAILED', idempotencyKey })
  })

  // --- Message queued ---
  engine.on('messageQueued', (queued) => {
    broadcast({ type: 'MESSAGE_QUEUED', data: queued })
  })

  // --- Message deleted ---
  engine.on('messageDeleted', (msg) => {
    // Remove from cache
    const cached = messageCache.get(msg.channel_id)
    if (cached) {
      const idx = cached.findIndex((m) => m.id === msg.message_id)
      if (idx !== -1) cached.splice(idx, 1)
    }
    broadcast({ type: 'MESSAGE_DELETED', data: msg })
  })

  // --- Reaction update ---
  engine.on('reactionUpdate', (msg) => {
    broadcast({ type: 'REACTION_UPDATE', data: msg })
  })

  // --- Typing ---
  engine.on('typing', (msg) => {
    broadcast({ type: 'TYPING', data: msg })
  })

  // --- Presence update ---
  engine.on('presenceUpdate', (msg) => {
    broadcast({ type: 'PRESENCE_UPDATE', data: msg })
  })

  // --- Stream ended ---
  engine.on('streamEnded', (msg) => {
    broadcast({ type: 'STREAM_ENDED', data: msg })
  })

  // --- Replay start ---
  engine.on('replayStart', (msg) => {
    // Clear cache on full resync
    if (msg.full_resync) {
      messageCache.delete(msg.channel_id)
    }
    broadcast({ type: 'REPLAY_START', data: msg })
  })

  // --- Replay message ---
  engine.on('replayMessage', (msg) => {
    cacheMessage(msg.channel_id, msg)
    broadcast({ type: 'REPLAY_MESSAGE', data: msg })
  })

  // --- Replay end ---
  engine.on('replayEnd', (msg) => {
    broadcast({ type: 'REPLAY_END', data: msg })
  })

  // --- Error ---
  engine.on('error', (msg) => {
    broadcast({ type: 'ERROR', data: msg })
  })
}

// ═══════════════════════════════════════════════════════════════════════════════
// Message cache
// ═══════════════════════════════════════════════════════════════════════════════

function cacheMessage(channelId, msg) {
  if (!messageCache.has(channelId)) {
    messageCache.set(channelId, [])
  }
  const cache = messageCache.get(channelId)
  // Dedup by id
  const existingIdx = cache.findIndex((m) => m.id === msg.id)
  if (existingIdx !== -1) {
    cache[existingIdx] = msg
  } else {
    cache.push(msg)
    if (cache.length > MAX_CACHE_PER_CHANNEL) {
      cache.shift()
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Port management
// ═══════════════════════════════════════════════════════════════════════════════

function addPort(port) {
  const wasEmpty = ports.size === 0
  ports.add(port)
  visiblePorts.add(port) // assume visible on connect

  port.onmessage = (event) => handlePortMessage(port, event.data)

  // Detect tab close — port will error when the tab dies
  port.onmessageerror = () => removePort(port)

  // If this is the first port (fresh worker or all tabs were closed), cancel passive mode
  if (wasEmpty) {
    clearPassiveTimer()
  }

  port.start()
}

function removePort(port) {
  ports.delete(port)
  visiblePorts.delete(port)

  if (ports.size === 0) {
    // Last tab closed — disconnect after a grace period
    // (allows for quick tab refresh without dropping the connection)
    schedulePassiveShutdown()
  }
}

function schedulePassiveShutdown() {
  clearPassiveTimer()
  passiveTimer = setTimeout(() => {
    passiveTimer = null
    if (ports.size === 0 && engine) {
      engine.disconnect()
    }
  }, 5000) // 5s grace period for tab refreshes
}

function clearPassiveTimer() {
  if (passiveTimer) {
    clearTimeout(passiveTimer)
    passiveTimer = null
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Visibility tracking
// ═══════════════════════════════════════════════════════════════════════════════

function checkAllHidden() {
  if (visiblePorts.size === 0 && ports.size > 0) {
    // All tabs hidden — don't disconnect, just let the engine manage
    // (the engine's zombie timer will handle stale connections)
  }
}

function checkAnyVisible() {
  // A tab came back to foreground — if disconnected, reconnect immediately
  if (engine && engine.getState() !== 'connected' &&
      engine.getState() !== 'connecting' &&
      engine.getState() !== 'session_expired' &&
      currentToken) {
    engine.connect(() => currentToken)
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Handle messages from tabs
// ═══════════════════════════════════════════════════════════════════════════════

function handlePortMessage(port, msg) {
  if (!engine) return

  switch (msg.type) {
    case 'CONNECT': {
      currentToken = msg.token
      if (engine.getState() === 'disconnected' || engine.getState() === 'session_expired') {
        engine.connect(() => currentToken)
      }
      // Send current state to the connecting tab
      port.postMessage({
        type: 'CURRENT_STATE',
        state: engine.getState(),
        quality: engine.getQuality(),
        userId: engine.getUserId(),
      })
      break
    }

    case 'DISCONNECT': {
      removePort(port)
      break
    }

    case 'JOIN_CHANNEL': {
      engine.joinChannel(msg.channelId)
      break
    }

    case 'LEAVE_CHANNEL': {
      engine.leaveChannel(msg.channelId)
      break
    }

    case 'RESUME_CHANNEL': {
      engine.resumeChannel(msg.channelId)
      break
    }

    case 'SEND_MESSAGE': {
      const queued = engine.sendMessage(msg.channelId, msg.content, msg.replyToId)
      // Send the queued message back to the sending tab so it has the idempotencyKey
      port.postMessage({ type: 'MESSAGE_QUEUED', data: queued })
      break
    }

    case 'ADD_REACTION': {
      engine.addReaction(msg.messageId, msg.emoji, msg.channelId)
      break
    }

    case 'REMOVE_REACTION': {
      engine.removeReaction(msg.messageId, msg.emoji, msg.channelId)
      break
    }

    case 'SEND_TYPING': {
      engine.sendTyping(msg.channelId)
      break
    }

    case 'DELETE_MESSAGE': {
      engine.deleteMessage(msg.messageId, msg.channelId)
      break
    }

    case 'GET_STATE': {
      port.postMessage({
        type: 'CURRENT_STATE',
        state: engine.getState(),
        quality: engine.getQuality(),
        userId: engine.getUserId(),
      })
      break
    }

    case 'TAB_VISIBLE': {
      visiblePorts.add(port)
      checkAnyVisible()
      break
    }

    case 'TAB_HIDDEN': {
      visiblePorts.delete(port)
      checkAllHidden()
      break
    }

    case 'UPDATE_TOKEN': {
      currentToken = msg.token
      break
    }

    case 'REQUEST_CACHE': {
      const cached = messageCache.get(msg.channelId) || []
      port.postMessage({
        type: 'CACHE_SYNC',
        channelId: msg.channelId,
        messages: cached.slice(), // defensive copy
      })
      break
    }

    case 'RESTORE_QUEUE': {
      // Restore persisted queue entries from localStorage (tab sends on startup).
      // Preserves original idempotency keys so the server can dedup if the
      // message was already delivered before the tab crashed.
      if (msg.entries && Array.isArray(msg.entries)) {
        for (const entry of msg.entries) {
          if (entry.status === 'sending' && entry.content && entry.channelId) {
            engine.sendMessage(entry.channelId, entry.content, entry.replyToId, entry.idempotencyKey)
          }
        }
      }
      break
    }

    case 'GET_LAST_SEQUENCE': {
      port.postMessage({
        type: 'LAST_SEQUENCE_RESPONSE',
        requestId: msg.requestId,
        sequence: engine.getLastSequence(msg.channelId),
      })
      break
    }

    case 'GET_USER_ID': {
      port.postMessage({
        type: 'USER_ID_RESPONSE',
        requestId: msg.requestId,
        userId: engine.getUserId(),
      })
      break
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Broadcast to all ports
// ═══════════════════════════════════════════════════════════════════════════════

function broadcast(msg) {
  for (const port of ports) {
    try {
      port.postMessage(msg)
    } catch {
      // Port died (tab closed) — clean up
      removePort(port)
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SharedWorker entry point
// ═══════════════════════════════════════════════════════════════════════════════

initEngine()

// eslint-disable-next-line no-restricted-globals
self.onconnect = (event) => {
  const port = event.ports[0]
  addPort(port)
}
