'use client'

import { Clock, AlertTriangle } from 'lucide-react'
import type { MessageDeliveryStatus } from '@/lib/chat/types'

interface MessageStatusProps {
  status?: MessageDeliveryStatus
  onRetry?: () => void
}

export function MessageStatus({ status, onRetry }: MessageStatusProps) {
  if (!status || status === 'sent') return null

  if (status === 'sending') {
    return (
      <span className="inline-flex items-center ml-1" title="Sending...">
        <Clock className="w-3 h-3 text-zinc-500" />
      </span>
    )
  }

  if (status === 'failed') {
    return (
      <span className="inline-flex items-center gap-1 ml-1">
        <AlertTriangle className="w-3 h-3 text-red-500" />
        {onRetry && (
          <button
            onClick={onRetry}
            className="text-xs text-red-400 hover:text-red-300 underline"
          >
            Retry
          </button>
        )}
      </span>
    )
  }

  return null
}
