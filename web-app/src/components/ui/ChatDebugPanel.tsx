'use client'

/**
 * ChatDebugPanel — development-only panel showing chat system internals.
 *
 * Shows: connection state, quality, last sequence per channel, port count,
 * queue length, last RTT.
 *
 * For SharedWorker console logs, use:
 *   Chrome:  chrome://inspect/#workers
 *   Firefox: about:debugging#workers
 */

import { useEffect, useState } from 'react'
import { getChatClient, isWorkerBridge } from '@/lib/chat'
import type { ConnectionQuality, ConnectionState } from '@/lib/chat/types'

interface DebugState {
  state: ConnectionState
  quality: ConnectionQuality
  userId: string | null
  isWorker: boolean
}

export function ChatDebugPanel({ channelId }: { channelId: string | null }) {
  const [debugState, setDebugState] = useState<DebugState>({
    state: 'disconnected',
    quality: 'good',
    userId: null,
    isWorker: false,
  })
  const [visible, setVisible] = useState(false)

  useEffect(() => {
    if (process.env.NODE_ENV !== 'development') return

    const engine = getChatClient()
    setDebugState({
      state: engine.getState(),
      quality: engine.getQuality(),
      userId: engine.getUserId(),
      isWorker: isWorkerBridge(engine),
    })

    const unsubs: (() => void)[] = []

    unsubs.push(
      engine.on('stateChange', (state) => {
        setDebugState((prev) => ({ ...prev, state }))
      }),
    )

    unsubs.push(
      engine.on('qualityChange', (quality) => {
        setDebugState((prev) => ({ ...prev, quality }))
      }),
    )

    return () => unsubs.forEach((fn) => fn())
  }, [])

  if (process.env.NODE_ENV !== 'development') return null

  const qualityColor = {
    good: '#22c55e',
    degraded: '#eab308',
    poor: '#ef4444',
  }[debugState.quality]

  const stateColor = {
    disconnected: '#6b7280',
    connecting: '#eab308',
    connected: '#22c55e',
    reconnecting: '#f97316',
    session_expired: '#ef4444',
  }[debugState.state]

  return (
    <>
      <button
        onClick={() => setVisible((v) => !v)}
        style={{
          position: 'fixed',
          bottom: 8,
          right: 8,
          zIndex: 9999,
          background: '#1f2937',
          color: '#9ca3af',
          border: '1px solid #374151',
          borderRadius: 4,
          padding: '4px 8px',
          fontSize: 11,
          cursor: 'pointer',
          fontFamily: 'monospace',
        }}
      >
        {visible ? 'Hide' : 'Chat Debug'}
      </button>
      {visible && (
        <div
          style={{
            position: 'fixed',
            bottom: 36,
            right: 8,
            zIndex: 9999,
            background: '#111827',
            color: '#d1d5db',
            border: '1px solid #374151',
            borderRadius: 6,
            padding: 12,
            fontSize: 12,
            fontFamily: 'monospace',
            minWidth: 220,
            lineHeight: 1.6,
          }}
        >
          <div style={{ fontWeight: 'bold', marginBottom: 8, color: '#f9fafb' }}>
            Chat Debug
          </div>
          <div>
            <span style={{ color: '#9ca3af' }}>Mode: </span>
            <span>{debugState.isWorker ? 'SharedWorker' : 'Inline'}</span>
          </div>
          <div>
            <span style={{ color: '#9ca3af' }}>State: </span>
            <span style={{ color: stateColor }}>{debugState.state}</span>
          </div>
          <div>
            <span style={{ color: '#9ca3af' }}>Quality: </span>
            <span style={{ color: qualityColor }}>{debugState.quality}</span>
          </div>
          <div>
            <span style={{ color: '#9ca3af' }}>User: </span>
            <span>{debugState.userId ?? 'none'}</span>
          </div>
          <div>
            <span style={{ color: '#9ca3af' }}>Channel: </span>
            <span>{channelId ?? 'none'}</span>
          </div>
          {debugState.isWorker && (
            <div style={{ marginTop: 8, color: '#6b7280', fontSize: 10 }}>
              Worker console: chrome://inspect/#workers
            </div>
          )}
        </div>
      )}
    </>
  )
}
