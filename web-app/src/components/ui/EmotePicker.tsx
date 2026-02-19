'use client'

import { useState, useEffect, useRef, useCallback } from 'react'
import { Search, X, Loader2 } from 'lucide-react'
import { useEmoteStore, getEmoteUrl } from '@/lib/emote-store'
import type { CachedEmote } from '@/lib/emote-store'

interface EmotePickerProps {
  onSelect: (emote: CachedEmote) => void
  onClose: () => void
}

export default function EmotePicker({ onSelect, onClose }: EmotePickerProps) {
  const { emoteList, recentlyUsed, status, addRecentlyUsed, addEmote, searchOnline } = useEmoteStore()
  const emotes = useEmoteStore(s => s.emotes)
  const [query, setQuery] = useState('')
  const [searchResults, setSearchResults] = useState<CachedEmote[]>([])
  const [searching, setSearching] = useState(false)
  const [searchPage, setSearchPage] = useState(1)
  const [loadingMore, setLoadingMore] = useState(false)
  const [hasMore, setHasMore] = useState(false)
  const pickerRef = useRef<HTMLDivElement>(null)
  const inputRef = useRef<HTMLInputElement>(null)
  const debounceRef = useRef<NodeJS.Timeout>(null)
  const currentQueryRef = useRef('')

  // Outside click dismissal
  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (pickerRef.current && !pickerRef.current.contains(e.target as Node)) {
        onClose()
      }
    }
    document.addEventListener('mousedown', handleClick)
    return () => document.removeEventListener('mousedown', handleClick)
  }, [onClose])

  useEffect(() => {
    inputRef.current?.focus()
  }, [])

  const handleLoadMore = async () => {
    const q = currentQueryRef.current
    if (!q || q.length < 2 || loadingMore) return

    setLoadingMore(true)
    const nextPage = searchPage + 1
    const results = await searchOnline(q, nextPage)
    setSearchResults(prev => [...prev, ...results])
    setSearchPage(nextPage)
    setHasMore(results.length >= 16)
    setLoadingMore(false)
  }

  const handleSearch = useCallback((q: string) => {
    setQuery(q)
    currentQueryRef.current = q
    if (debounceRef.current) clearTimeout(debounceRef.current)

    if (!q || q.length < 2) {
      setSearchResults([])
      setSearching(false)
      setSearchPage(1)
      setHasMore(false)
      return
    }

    setSearching(true)
    debounceRef.current = setTimeout(async () => {
      const results = await searchOnline(q, 1)
      setSearchResults(results)
      setSearchPage(1)
      setHasMore(results.length >= 16)
      setSearching(false)
    }, 400)
  }, [searchOnline])

  // Build recently used emote objects
  const recentEmotes = recentlyUsed
    .map(name => emotes.get(name))
    .filter(Boolean) as CachedEmote[]

  function handleSelect(emote: CachedEmote) {
    addEmote(emote) // cache so it renders in chat
    addRecentlyUsed(emote.name)
    onSelect(emote) // pass full emote object
    // Don't close — stays open so users can click multiple emotes (Twitch-style)
  }

  // What to show in the grid
  const isSearching = query.length >= 2
  const displayEmotes = isSearching ? searchResults : emoteList

  return (
    <div
      ref={pickerRef}
      className="absolute bottom-full mb-2 left-0 z-50 w-[340px] rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-card)] shadow-2xl overflow-hidden"
    >
      {/* Header */}
      <div className="flex items-center justify-between px-3 py-2 border-b border-[var(--color-border)]">
        <span className="text-xs font-semibold text-white">Emotes</span>
        <button onClick={onClose} className="text-[var(--color-text-dim)] hover:text-white transition-colors">
          <X size={14} />
        </button>
      </div>

      {/* Search */}
      <div className="px-3 py-2">
        <div className="relative">
          <Search size={14} className="absolute left-2.5 top-1/2 -translate-y-1/2 text-[var(--color-text-dim)]" />
          <input
            ref={inputRef}
            type="text"
            value={query}
            onChange={e => handleSearch(e.target.value)}
            placeholder="Search all 7TV emotes..."
            className="w-full rounded-lg border border-[var(--color-border)] bg-[var(--color-bg-surface)] pl-8 pr-3 py-1.5 text-xs text-[var(--color-text)] placeholder-[var(--color-text-dim)] focus:border-[var(--color-gold)] focus:outline-none"
          />
        </div>
      </div>

      {/* Emote Grid */}
      <div className="h-[280px] overflow-y-auto px-2 pb-2">
        {status === 'loading' && !isSearching ? (
          <div className="flex items-center justify-center h-full">
            <Loader2 size={20} className="animate-spin text-[var(--color-text-dim)]" />
          </div>
        ) : (
          <>
            {/* Recently Used — only when not searching */}
            {!isSearching && recentEmotes.length > 0 && (
              <div className="mb-2">
                <p className="text-[10px] font-semibold uppercase tracking-wider text-[var(--color-text-dim)] px-1 mb-1">Recently Used</p>
                <div className="grid grid-cols-8 gap-1">
                  {recentEmotes.map(emote => (
                    <button
                      key={`recent-${emote.id}`}
                      onClick={() => handleSelect(emote)}
                      title={emote.name}
                      className="flex items-center justify-center rounded-md p-1 hover:bg-[var(--color-bg-hover)] transition-colors"
                    >
                      <img
                        src={getEmoteUrl(emote.id, '3x')}
                        alt={emote.name}
                        className="h-8 w-auto"
                        loading="lazy"
                      />
                    </button>
                  ))}
                </div>
              </div>
            )}

            {/* Section label */}
            <p className="text-[10px] font-semibold uppercase tracking-wider text-[var(--color-text-dim)] px-1 mb-1">
              {isSearching
                ? searching ? 'Searching...' : `${searchResults.length} result${searchResults.length !== 1 ? 's' : ''}`
                : 'Global 7TV'
              }
            </p>

            {/* Loading state for search */}
            {searching ? (
              <div className="flex items-center justify-center py-8">
                <Loader2 size={20} className="animate-spin text-[var(--color-text-dim)]" />
              </div>
            ) : displayEmotes.length === 0 ? (
              <p className="text-xs text-[var(--color-text-dim)] text-center py-4">
                {isSearching ? 'No emotes found' : 'No emotes loaded'}
              </p>
            ) : (
              <div className="grid grid-cols-8 gap-1">
                {displayEmotes.map(emote => (
                  <button
                    key={emote.id}
                    onClick={() => handleSelect(emote)}
                    title={emote.name}
                    className="flex items-center justify-center rounded-md p-1 hover:bg-[var(--color-bg-hover)] transition-colors"
                  >
                    <img
                      src={getEmoteUrl(emote.id, '3x')}
                      alt={emote.name}
                      className="h-8 w-auto"
                      loading="lazy"
                    />
                  </button>
                ))}
              </div>
            )}

            {/* Load more button */}
            {isSearching && hasMore && (
              <button
                onClick={handleLoadMore}
                disabled={loadingMore}
                className="mt-2 w-full rounded-lg border border-[var(--color-border)] py-1.5 text-[11px] font-medium text-[var(--color-text-dim)] hover:text-white hover:border-[var(--color-gold)] transition-colors disabled:opacity-50"
              >
                {loadingMore ? <Loader2 size={14} className="animate-spin mx-auto" /> : 'Load More'}
              </button>
            )}
          </>
        )}
      </div>
    </div>
  )
}
