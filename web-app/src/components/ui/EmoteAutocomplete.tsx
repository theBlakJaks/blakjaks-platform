'use client'

import { getEmoteUrl } from '@/lib/emote-store'
import type { CachedEmote } from '@/lib/emote-store'

interface EmoteAutocompleteProps {
  matches: CachedEmote[]
  onSelect: (name: string) => void
  onDismiss: () => void
}

export default function EmoteAutocomplete({ matches, onSelect }: EmoteAutocompleteProps) {
  if (matches.length === 0) return null

  return (
    <div className="absolute bottom-full left-0 mb-1 z-50 w-full max-w-[280px] rounded-lg border border-[var(--color-border)] bg-[var(--color-bg-card)] shadow-xl overflow-hidden">
      {matches.map((emote, i) => (
        <button
          key={emote.id}
          onMouseDown={e => {
            e.preventDefault() // prevent input blur
            onSelect(emote.name)
          }}
          className="flex w-full items-center gap-2.5 px-3 py-1.5 text-left hover:bg-[var(--color-bg-hover)] transition-colors"
        >
          <img
            src={getEmoteUrl(emote.id, '1x')}
            alt={emote.name}
            className="h-5 w-auto"
          />
          <span className="text-xs text-[var(--color-text)]">{emote.name}</span>
          {i === 0 && (
            <span className="ml-auto text-[10px] text-[var(--color-text-dim)] bg-[var(--color-bg-surface)] rounded px-1.5 py-0.5">
              Tab
            </span>
          )}
        </button>
      ))}
    </div>
  )
}
