"use strict";
var BlakJaksChat = (() => {
  var __defProp = Object.defineProperty;
  var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
  var __getOwnPropNames = Object.getOwnPropertyNames;
  var __hasOwnProp = Object.prototype.hasOwnProperty;
  var __export = (target, all) => {
    for (var name in all)
      __defProp(target, name, { get: all[name], enumerable: true });
  };
  var __copyProps = (to, from, except, desc) => {
    if (from && typeof from === "object" || typeof from === "function") {
      for (let key of __getOwnPropNames(from))
        if (!__hasOwnProp.call(to, key) && key !== except)
          __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
    }
    return to;
  };
  var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

  // src/lib/chat/worker-engine-entry.ts
  var worker_engine_entry_exports = {};
  __export(worker_engine_entry_exports, {
    ChatEngine: () => ChatEngine,
    ConnectionQualityMonitor: () => ConnectionQualityMonitor
  });

  // src/lib/chat/connection-quality.ts
  var WINDOW_SIZE = 5;
  var GOOD_THRESHOLD_MS = 200;
  var POOR_THRESHOLD_MS = 800;
  var ConnectionQualityMonitor = class {
    constructor() {
      this._samples = [];
      this._quality = "good";
      this.onChange = null;
    }
    get quality() {
      return this._quality;
    }
    get averageRtt() {
      if (this._samples.length === 0) return 0;
      return this._samples.reduce((a, b) => a + b, 0) / this._samples.length;
    }
    recordRtt(ms) {
      this._samples.push(ms);
      if (this._samples.length > WINDOW_SIZE) {
        this._samples.shift();
      }
      this._evaluate();
    }
    recordMissedPong() {
      this._setQuality("poor");
    }
    reset() {
      this._samples = [];
      this._setQuality("good");
    }
    _evaluate() {
      const avg = this.averageRtt;
      if (avg > POOR_THRESHOLD_MS) {
        this._setQuality("poor");
      } else if (avg > GOOD_THRESHOLD_MS) {
        this._setQuality("degraded");
      } else {
        this._setQuality("good");
      }
    }
    _setQuality(q) {
      if (this._quality === q) return;
      this._quality = q;
      this.onChange?.(q);
    }
  };

  // src/lib/chat/chat-engine.ts
  var BASE_URL = "http://localhost:8000".replace(/\/api\/?$/, "");
  var QUEUE_STORAGE_KEY = "blakjaks_chat_queue";
  var MAX_QUEUE_SIZE = 20;
  var QUEUE_TTL_MS = 5 * 60 * 1e3;
  var QUEUE_FLUSH_DELAY_MS = 100;
  var ZOMBIE_TIMEOUT_MS = 35e3;
  var DEDUP_MAX_SIZE = 1e3;
  var MAX_RECONNECT_DELAY_MS = 1e4;
  var RECONNECT_JITTER_MS = 500;
  var MAX_RECONNECT_ATTEMPTS = 10;
  var RAPID_CLOSE_MS = 2e3;
  var ChatEngine = class {
    constructor() {
      // ── Connection state ──
      this._state = "disconnected";
      this._ws = null;
      this._sessionId = null;
      this._userId = null;
      this._getToken = null;
      this._reconnectAttempts = 0;
      this._rapidCloseCount = 0;
      // consecutive connections that closed within RAPID_CLOSE_MS
      this._connectTime = 0;
      // timestamp when current WS opened
      this._reconnectTimer = null;
      this._zombieTimer = null;
      this._visibilityDelay = null;
      // ── Per-channel sequence tracking ──
      this._lastSequence = /* @__PURE__ */ new Map();
      // ── Outbound queue (persisted to localStorage) ──
      this._outboundQueue = /* @__PURE__ */ new Map();
      // ── Replay buffer ──
      this._replayBuffer = /* @__PURE__ */ new Map();
      this._replayFullResync = /* @__PURE__ */ new Map();
      this._catchingUp = /* @__PURE__ */ new Set();
      // ── Dedup ──
      this._seenIds = [];
      // ── Connection quality ──
      this._qualityMonitor = new ConnectionQualityMonitor();
      this._pingTimestamp = null;
      this._rttInterval = null;
      // ── Event handlers ──
      this._handlers = /* @__PURE__ */ new Map();
      // ── Joined channels ──
      this._joinedChannels = /* @__PURE__ */ new Set();
      // ── Confirmation timeouts ──
      this._confirmationTimeouts = /* @__PURE__ */ new Map();
      // ── Visibility (inline mode only, not SharedWorker) ──
      this._visibilityHandler = null;
      this._restoreQueue();
      this._qualityMonitor.onChange = (q) => {
        this._emit("qualityChange", q);
        this._startRttInterval();
      };
    }
    // ═══════════════════════════════════════════════════════════════════════════
    // Public API
    // ═══════════════════════════════════════════════════════════════════════════
    connect(getToken) {
      this._getToken = getToken;
      this._doConnect();
      this._bindVisibility();
    }
    disconnect() {
      this._unbindVisibility();
      this._clearReconnect();
      this._clearZombieTimer();
      this._stopRttInterval();
      if (this._ws) {
        this._ws.onclose = null;
        this._ws.close(1e3);
        this._ws = null;
      }
      this._setState("disconnected");
    }
    joinChannel(channelId) {
      this._joinedChannels.add(channelId);
      this._send({ type: "join_channel", channel_id: channelId });
    }
    leaveChannel(channelId) {
      this._joinedChannels.delete(channelId);
      this._send({ type: "leave_channel", channel_id: channelId });
    }
    resumeChannel(channelId) {
      const lastSeq = this._lastSequence.get(channelId) ?? 0;
      this._joinedChannels.add(channelId);
      this._send({ type: "resume", channel_id: channelId, last_sequence: lastSeq });
    }
    sendMessage(channelId, content, replyToId, existingIdempotencyKey) {
      const idempotencyKey = existingIdempotencyKey ?? crypto.randomUUID();
      const queued = {
        idempotencyKey,
        channelId,
        content,
        replyToId,
        status: "sending",
        queuedAt: Date.now()
      };
      this._outboundQueue.set(idempotencyKey, queued);
      this._persistQueue();
      this._emit("messageQueued", queued);
      const timeout = setTimeout(() => {
        const q = this._outboundQueue.get(idempotencyKey);
        if (q && q.status === "sending") {
          q.status = "failed";
          this._persistQueue();
          this._emit("messageFailed", idempotencyKey);
        }
        this._confirmationTimeouts.delete(idempotencyKey);
      }, 1e4);
      this._confirmationTimeouts.set(idempotencyKey, timeout);
      if (this._ws?.readyState === WebSocket.OPEN) {
        this._send({
          type: "send_message",
          channel_id: channelId,
          content,
          reply_to_id: replyToId,
          idempotency_key: idempotencyKey
        });
      }
      return queued;
    }
    addReaction(messageId, emoji, channelId) {
      this._send({ type: "add_reaction", message_id: messageId, emoji, channel_id: channelId });
    }
    removeReaction(messageId, emoji, channelId) {
      this._send({ type: "remove_reaction", message_id: messageId, emoji, channel_id: channelId });
    }
    sendTyping(channelId) {
      if (this._qualityMonitor.quality !== "good") return;
      this._send({ type: "typing", channel_id: channelId });
    }
    deleteMessage(messageId, channelId) {
      this._send({ type: "delete_message", message_id: messageId, channel_id: channelId });
    }
    getState() {
      return this._state;
    }
    getQuality() {
      return this._qualityMonitor.quality;
    }
    getPresence() {
      return /* @__PURE__ */ new Map();
    }
    getLastSequence(channelId) {
      return this._lastSequence.get(channelId) ?? 0;
    }
    getSessionId() {
      return this._sessionId;
    }
    getUserId() {
      return this._userId;
    }
    on(event, handler) {
      if (!this._handlers.has(event)) {
        this._handlers.set(event, /* @__PURE__ */ new Set());
      }
      this._handlers.get(event).add(handler);
      return () => {
        this._handlers.get(event)?.delete(handler);
      };
    }
    // ═══════════════════════════════════════════════════════════════════════════
    // Connection
    // ═══════════════════════════════════════════════════════════════════════════
    _doConnect() {
      if (this._ws?.readyState === WebSocket.CONNECTING || this._ws?.readyState === WebSocket.OPEN) {
        return;
      }
      const token = this._getToken?.();
      if (!token) {
        this._setState("disconnected");
        return;
      }
      this._setState(this._reconnectAttempts > 0 ? "reconnecting" : "connecting");
      const wsUrl = BASE_URL.replace(/^http/, "ws") + `/social/ws?token=${token}`;
      const ws = new WebSocket(wsUrl);
      this._ws = ws;
      this._connectTime = Date.now();
      ws.onopen = () => {
      };
      ws.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data);
          this._handleMessage(data);
        } catch {
        }
      };
      ws.onclose = (event) => {
        this._ws = null;
        this._clearZombieTimer();
        this._stopRttInterval();
        if (event.code === 4001) {
          this._setState("session_expired");
          return;
        }
        if (this._state === "disconnected") {
          return;
        }
        const wasRapidClose = Date.now() - this._connectTime < RAPID_CLOSE_MS;
        if (wasRapidClose && this._state !== "connected") {
          this._rapidCloseCount++;
        } else {
          this._rapidCloseCount = 0;
        }
        if (this._reconnectAttempts >= MAX_RECONNECT_ATTEMPTS || this._rapidCloseCount >= 3) {
          this._setState("session_expired");
          return;
        }
        if (event.code === 4e3) {
          this._scheduleReconnect(0);
        } else {
          this._scheduleReconnect();
        }
      };
      ws.onerror = () => {
      };
    }
    // ═══════════════════════════════════════════════════════════════════════════
    // Message handling
    // ═══════════════════════════════════════════════════════════════════════════
    _handleMessage(data) {
      switch (data.type) {
        case "auth_success":
          this._sessionId = data.session_id;
          this._userId = data.user_id;
          this._reconnectAttempts = 0;
          this._rapidCloseCount = 0;
          this._setState("connected");
          this._resetZombieTimer();
          this._onConnected();
          break;
        case "new_message":
          this._handleNewMessage(data);
          break;
        case "message_deleted":
          this._emit("messageDeleted", data);
          break;
        case "reaction_update":
          this._emit("reactionUpdate", data);
          break;
        case "typing":
          this._emit("typing", data);
          break;
        case "presence_update":
          this._emit("presenceUpdate", data);
          break;
        case "stream_ended":
          this._emit("streamEnded", data);
          break;
        case "replay_start":
          this._catchingUp.add(data.channel_id);
          this._replayBuffer.set(data.channel_id, []);
          this._replayFullResync.set(data.channel_id, data.full_resync);
          this._emit("catchingUp", true);
          this._emit("replayStart", data);
          break;
        case "replay_message":
          this._trackSequence(data.channel_id, data.sequence);
          this._ack(data.channel_id, data.sequence);
          {
            const buf = this._replayBuffer.get(data.channel_id);
            if (buf) buf.push(data);
          }
          this._emit("replayMessage", data);
          break;
        case "replay_end":
          this._emit("replayEnd", data);
          this._catchingUp.delete(data.channel_id);
          if (this._catchingUp.size === 0) {
            this._emit("catchingUp", false);
          }
          this._replayBuffer.delete(data.channel_id);
          this._replayFullResync.delete(data.channel_id);
          this._flushQueue();
          break;
        case "ping":
          this._send({ type: "pong" });
          this._resetZombieTimer();
          break;
        case "pong":
          if (this._pingTimestamp !== null) {
            const rtt = Date.now() - this._pingTimestamp;
            this._qualityMonitor.recordRtt(rtt);
            this._pingTimestamp = null;
          }
          break;
        case "error":
          this._emit("error", data);
          break;
        case "session_expired":
          this._setState("session_expired");
          if (this._ws) {
            this._ws.onclose = null;
            this._ws.close();
            this._ws = null;
          }
          break;
      }
    }
    _handleNewMessage(msg) {
      this._trackSequence(msg.channel_id, msg.sequence);
      this._ack(msg.channel_id, msg.sequence);
      if (msg.idempotency_key) {
        const queued = this._outboundQueue.get(msg.idempotency_key);
        if (queued) {
          const timeout = this._confirmationTimeouts.get(msg.idempotency_key);
          if (timeout) {
            clearTimeout(timeout);
            this._confirmationTimeouts.delete(msg.idempotency_key);
          }
          this._outboundQueue.delete(msg.idempotency_key);
          this._persistQueue();
          if (!this._hasSeen(msg.id)) {
            this._markSeen(msg.id);
            this._emit("messageConfirmed", msg.idempotency_key, msg);
          }
          return;
        }
      }
      if (this._hasSeen(msg.id)) return;
      this._markSeen(msg.id);
      this._emit("message", msg);
    }
    // ═══════════════════════════════════════════════════════════════════════════
    // Reconnect + queue flush
    // ═══════════════════════════════════════════════════════════════════════════
    _onConnected() {
      for (const channelId of this._joinedChannels) {
        this.resumeChannel(channelId);
      }
      this._measureRtt();
      this._startRttInterval();
    }
    _flushQueue() {
      const now = Date.now();
      const toSend = [];
      const toDiscard = [];
      for (const [key, msg] of this._outboundQueue) {
        if (now - msg.queuedAt > QUEUE_TTL_MS) {
          toDiscard.push(key);
        } else if (msg.status === "sending") {
          toSend.push(msg);
        }
      }
      for (const key of toDiscard) {
        const timeout = this._confirmationTimeouts.get(key);
        if (timeout) {
          clearTimeout(timeout);
          this._confirmationTimeouts.delete(key);
        }
        this._outboundQueue.delete(key);
        this._emit("messageFailed", key);
      }
      if (toSend.length > 0) {
        this._flushWithDelay(toSend, 0);
      }
      this._persistQueue();
    }
    _flushWithDelay(messages, index) {
      if (index >= messages.length) return;
      if (this._ws?.readyState !== WebSocket.OPEN) return;
      const msg = messages[index];
      this._send({
        type: "send_message",
        channel_id: msg.channelId,
        content: msg.content,
        reply_to_id: msg.replyToId,
        idempotency_key: msg.idempotencyKey
      });
      if (index + 1 < messages.length) {
        setTimeout(() => this._flushWithDelay(messages, index + 1), QUEUE_FLUSH_DELAY_MS);
      }
    }
    _scheduleReconnect(delayMs) {
      this._clearReconnect();
      this._setState("reconnecting");
      const delay = delayMs ?? this._backoffDelay();
      this._reconnectAttempts++;
      this._reconnectTimer = setTimeout(() => {
        this._reconnectTimer = null;
        this._doConnect();
      }, delay);
    }
    _backoffDelay() {
      const base = Math.min(1e3 * Math.pow(2, this._reconnectAttempts), MAX_RECONNECT_DELAY_MS);
      const jitter = (Math.random() * 2 - 1) * RECONNECT_JITTER_MS;
      return Math.max(0, base + jitter);
    }
    _clearReconnect() {
      if (this._reconnectTimer) {
        clearTimeout(this._reconnectTimer);
        this._reconnectTimer = null;
      }
    }
    // ═══════════════════════════════════════════════════════════════════════════
    // Zombie detection (server ping timeout)
    // ═══════════════════════════════════════════════════════════════════════════
    _resetZombieTimer() {
      this._clearZombieTimer();
      this._zombieTimer = setTimeout(() => {
        if (this._ws && this._ws.readyState === WebSocket.OPEN) {
          this._ws.close(4e3, "zombie");
        }
      }, ZOMBIE_TIMEOUT_MS);
    }
    _clearZombieTimer() {
      if (this._zombieTimer) {
        clearTimeout(this._zombieTimer);
        this._zombieTimer = null;
      }
    }
    // ═══════════════════════════════════════════════════════════════════════════
    // RTT measurement via client-initiated ping
    // ═══════════════════════════════════════════════════════════════════════════
    _measureRtt() {
      if (this._ws?.readyState !== WebSocket.OPEN) return;
      this._pingTimestamp = Date.now();
      this._send({ type: "ping" });
    }
    _startRttInterval() {
      this._stopRttInterval();
      const intervalMs = this._qualityMonitor.quality === "poor" ? 1e4 : 25e3;
      this._rttInterval = setInterval(() => this._measureRtt(), intervalMs);
    }
    _stopRttInterval() {
      if (this._rttInterval) {
        clearInterval(this._rttInterval);
        this._rttInterval = null;
      }
    }
    // ═══════════════════════════════════════════════════════════════════════════
    // Sequence tracking & ACK
    // ═══════════════════════════════════════════════════════════════════════════
    _trackSequence(channelId, sequence) {
      const current = this._lastSequence.get(channelId) ?? 0;
      if (sequence > current) {
        this._lastSequence.set(channelId, sequence);
      }
    }
    _ack(channelId, sequence) {
      this._send({ type: "ack", sequence, channel_id: channelId });
    }
    // ═══════════════════════════════════════════════════════════════════════════
    // Dedup
    // ═══════════════════════════════════════════════════════════════════════════
    _hasSeen(id) {
      return this._seenIds.includes(id);
    }
    _markSeen(id) {
      this._seenIds.push(id);
      if (this._seenIds.length > DEDUP_MAX_SIZE) {
        this._seenIds = this._seenIds.slice(-DEDUP_MAX_SIZE);
      }
    }
    // ═══════════════════════════════════════════════════════════════════════════
    // Queue persistence (localStorage)
    // ═══════════════════════════════════════════════════════════════════════════
    _persistQueue() {
      try {
        const entries = Array.from(this._outboundQueue.values()).filter((m) => m.status === "sending").slice(-MAX_QUEUE_SIZE);
        localStorage.setItem(QUEUE_STORAGE_KEY, JSON.stringify(entries));
      } catch {
      }
    }
    _restoreQueue() {
      try {
        const raw = localStorage.getItem(QUEUE_STORAGE_KEY);
        if (!raw) return;
        const entries = JSON.parse(raw);
        const now = Date.now();
        for (const entry of entries) {
          if (now - entry.queuedAt < QUEUE_TTL_MS && entry.status === "sending") {
            this._outboundQueue.set(entry.idempotencyKey, entry);
          }
        }
      } catch {
      }
    }
    // ═══════════════════════════════════════════════════════════════════════════
    // Visibility handling (inline mode — not used in SharedWorker)
    // ═══════════════════════════════════════════════════════════════════════════
    _bindVisibility() {
      if (typeof document === "undefined") return;
      this._visibilityHandler = () => {
        if (document.visibilityState === "visible") {
          if (this._visibilityDelay) {
            clearTimeout(this._visibilityDelay);
            this._visibilityDelay = null;
          }
          if (this._state !== "connected" && this._state !== "connecting" && this._state !== "session_expired") {
            this._reconnectAttempts = 0;
            this._scheduleReconnect(0);
          }
          if (this._state === "connected") {
            this._measureRtt();
          }
        } else {
          if (this._state === "reconnecting") {
            this._clearReconnect();
            this._visibilityDelay = setTimeout(() => {
              this._visibilityDelay = null;
              if (this._state !== "connected" && this._state !== "session_expired") {
                this._scheduleReconnect();
              }
            }, 3e4);
          }
        }
      };
      document.addEventListener("visibilitychange", this._visibilityHandler);
    }
    _unbindVisibility() {
      if (this._visibilityHandler && typeof document !== "undefined") {
        document.removeEventListener("visibilitychange", this._visibilityHandler);
        this._visibilityHandler = null;
      }
      if (this._visibilityDelay) {
        clearTimeout(this._visibilityDelay);
        this._visibilityDelay = null;
      }
    }
    // ═══════════════════════════════════════════════════════════════════════════
    // Send helper
    // ═══════════════════════════════════════════════════════════════════════════
    _send(msg) {
      if (this._ws?.readyState === WebSocket.OPEN) {
        this._ws.send(JSON.stringify(msg));
      }
    }
    // ═══════════════════════════════════════════════════════════════════════════
    // State management
    // ═══════════════════════════════════════════════════════════════════════════
    _setState(state) {
      if (this._state === state) return;
      this._state = state;
      this._emit("stateChange", state);
    }
    // ═══════════════════════════════════════════════════════════════════════════
    // Event emitter
    // ═══════════════════════════════════════════════════════════════════════════
    _emit(event, ...args) {
      const handlers = this._handlers.get(event);
      if (!handlers) return;
      for (const handler of handlers) {
        try {
          ;
          handler(...args);
        } catch {
        }
      }
    }
  };
  return __toCommonJS(worker_engine_entry_exports);
})();
//# sourceMappingURL=chat-worker-engine.js.map
