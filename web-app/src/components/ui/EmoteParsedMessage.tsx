'use client'

import { useMemo } from 'react'
import { useEmoteStore, getEmoteUrl } from '@/lib/emote-store'
import { parseMessageToSegments } from '@/lib/emote-utils'

interface EmoteParsedMessageProps {
  content: string
  className?: string
  emoteSize?: 'sm' | 'md'
}

export default function EmoteParsedMessage({
  content,
  className,
  emoteSize = 'md',
}: EmoteParsedMessageProps) {
  const emotes = useEmoteStore(s => s.emotes)

  const segments = useMemo(
    () => parseMessageToSegments(content, emotes),
    [content, emotes],
  )

  // If no emotes found, render as plain text (fast path)
  if (segments.length === 1 && segments[0].type === 'text') {
    return <p className={className}>{content}</p>
  }

  const sizeClass = emoteSize === 'sm' ? 'h-[28px]' : 'h-[32px]'

  return (
    <span className={className}>
      {segments.map((seg, i) => {
        if (seg.type === 'text') {
          return <span key={i}>{seg.value}</span>
        }

        const emote = seg.emote
        const img = (
          <img
            src={getEmoteUrl(emote.id, '2x')}
            alt={emote.name}
            width={32}
            height={32}
            className={`inline-block object-contain align-middle ${sizeClass} w-auto`}
            loading="lazy"
            decoding="async"
          />
        )

        if (seg.zeroWidth) {
          return (
            <span
              key={i}
              className="inline-block"
              style={{ width: 0, overflow: 'visible' }}
              title={emote.name}
            >
              <span className="absolute top-0 left-0 pointer-events-none">
                {img}
              </span>
            </span>
          )
        }

        return (
          <span key={i} className="group/emote relative inline-block align-middle">
            {img}
            {/* Hover tooltip */}
            <span className="pointer-events-none absolute bottom-full left-1/2 -translate-x-1/2 mb-1.5 z-50 flex flex-col items-center rounded-lg border border-[var(--color-border)] bg-[var(--color-bg-card)] px-2.5 py-2 shadow-xl opacity-0 invisible group-hover/emote:opacity-100 group-hover/emote:visible transition-opacity duration-150 whitespace-nowrap">
              <img
                src={getEmoteUrl(emote.id, '4x')}
                alt={emote.name}
                className="h-14 w-auto mb-1"
              />
              <span className="text-[11px] font-medium text-white">{emote.name}</span>
              <span className="text-[9px] font-bold text-[var(--color-text-dim)] uppercase tracking-wider">7TV</span>
            </span>
          </span>
        )
      })}
    </span>
  )
}
