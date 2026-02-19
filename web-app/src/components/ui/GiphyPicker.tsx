'use client'

import { useState, useEffect, useRef, useCallback } from 'react'
import { Search, X, Loader2 } from 'lucide-react'

interface GiphyGif {
  id: string
  title: string
  images: {
    fixed_width: { url: string; width: string; height: string }
    fixed_width_small: { url: string; width: string; height: string }
    original: { url: string; width: string; height: string }
  }
}

interface GiphyPickerProps {
  onSelect: (gifUrl: string) => void
  onClose: () => void
}

const GIPHY_API_KEY = process.env.NEXT_PUBLIC_GIPHY_API_KEY
const GIPHY_BASE = 'https://api.giphy.com/v1/gifs'

export default function GiphyPicker({ onSelect, onClose }: GiphyPickerProps) {
  const [query, setQuery] = useState('')
  const [gifs, setGifs] = useState<GiphyGif[]>([])
  const [loading, setLoading] = useState(false)
  const [mode, setMode] = useState<'trending' | 'search'>('trending')
  const inputRef = useRef<HTMLInputElement>(null)
  const pickerRef = useRef<HTMLDivElement>(null)
  const debounceRef = useRef<NodeJS.Timeout>(null)

  // Close on outside click
  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (pickerRef.current && !pickerRef.current.contains(e.target as Node)) {
        onClose()
      }
    }
    document.addEventListener('mousedown', handleClick)
    return () => document.removeEventListener('mousedown', handleClick)
  }, [onClose])

  // Focus input on mount
  useEffect(() => {
    inputRef.current?.focus()
  }, [])

  // Fetch trending on mount
  useEffect(() => {
    fetchTrending()
  }, [])

  async function fetchTrending() {
    setLoading(true)
    try {
      const res = await fetch(
        `${GIPHY_BASE}/trending?api_key=${GIPHY_API_KEY}&limit=20&rating=pg-13`
      )
      const data = await res.json()
      setGifs(data.data || [])
      setMode('trending')
    } catch {
      setGifs([])
    } finally {
      setLoading(false)
    }
  }

  async function fetchSearch(q: string) {
    if (!q.trim()) {
      fetchTrending()
      return
    }
    setLoading(true)
    try {
      const res = await fetch(
        `${GIPHY_BASE}/search?api_key=${GIPHY_API_KEY}&q=${encodeURIComponent(q)}&limit=20&rating=pg-13`
      )
      const data = await res.json()
      setGifs(data.data || [])
      setMode('search')
    } catch {
      setGifs([])
    } finally {
      setLoading(false)
    }
  }

  const handleInputChange = useCallback((value: string) => {
    setQuery(value)
    if (debounceRef.current) clearTimeout(debounceRef.current)
    debounceRef.current = setTimeout(() => fetchSearch(value), 400)
  }, [])

  return (
    <div
      ref={pickerRef}
      className="absolute bottom-full mb-2 left-0 z-50 w-[340px] rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-card)] shadow-2xl overflow-hidden"
    >
      {/* Header */}
      <div className="flex items-center justify-between px-3 py-2 border-b border-[var(--color-border)]">
        <span className="text-xs font-semibold text-white">GIF</span>
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
            onChange={e => handleInputChange(e.target.value)}
            placeholder="Search GIFs..."
            className="w-full rounded-lg border border-[var(--color-border)] bg-[var(--color-bg-surface)] pl-8 pr-3 py-1.5 text-xs text-[var(--color-text)] placeholder-[var(--color-text-dim)] focus:border-[var(--color-gold)] focus:outline-none"
          />
        </div>
      </div>

      {/* GIF Grid */}
      <div className="h-[280px] overflow-y-auto px-2 pb-2">
        {loading ? (
          <div className="flex items-center justify-center h-full">
            <Loader2 size={20} className="animate-spin text-[var(--color-text-dim)]" />
          </div>
        ) : gifs.length === 0 ? (
          <div className="flex items-center justify-center h-full">
            <p className="text-xs text-[var(--color-text-dim)]">
              {mode === 'search' ? 'No GIFs found' : 'Could not load GIFs'}
            </p>
          </div>
        ) : (
          <div className="columns-2 gap-1.5">
            {gifs.map(gif => (
              <button
                key={gif.id}
                onClick={() => {
                  onSelect(gif.images.fixed_width.url)
                  onClose()
                }}
                className="mb-1.5 w-full rounded-lg overflow-hidden hover:ring-2 hover:ring-[var(--color-gold)] transition-all break-inside-avoid"
                title={gif.title}
              >
                <img
                  src={gif.images.fixed_width_small.url}
                  alt={gif.title}
                  width={Number(gif.images.fixed_width_small.width)}
                  height={Number(gif.images.fixed_width_small.height)}
                  className="w-full h-auto"
                  loading="lazy"
                />
              </button>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
