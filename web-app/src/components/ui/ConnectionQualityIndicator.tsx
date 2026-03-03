'use client'

import type { ConnectionQuality } from '@/lib/chat/types'

interface ConnectionQualityIndicatorProps {
  quality: ConnectionQuality
}

const DOT_COLORS: Record<ConnectionQuality, string> = {
  good: 'bg-green-500',
  degraded: 'bg-yellow-500',
  poor: 'bg-red-500',
}

export function ConnectionQualityDot({ quality }: ConnectionQualityIndicatorProps) {
  return (
    <span
      className={`inline-block w-2 h-2 rounded-full ${DOT_COLORS[quality]}`}
      title={`Connection: ${quality}`}
    />
  )
}

export function ConnectionQualityBanner({ quality }: ConnectionQualityIndicatorProps) {
  if (quality === 'good') return null

  if (quality === 'degraded') {
    return (
      <div className="flex items-center gap-1.5 px-3 py-1 text-xs text-yellow-300 bg-yellow-900/30 border-b border-yellow-800/50">
        <span className="inline-block w-2 h-2 rounded-full bg-yellow-500" />
        Slow connection
      </div>
    )
  }

  return (
    <div className="flex items-center gap-1.5 px-3 py-1.5 text-xs text-red-300 bg-red-900/30 border-b border-red-800/50">
      <span className="inline-block w-2 h-2 rounded-full bg-red-500" />
      Connection is unstable — messages may be delayed
    </div>
  )
}
