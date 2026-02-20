'use client'

import { create } from 'zustand'

export interface CachedEmote {
  id: string
  name: string
  animated: boolean
  zeroWidth: boolean
}

interface EmoteStore {
  emotes: Map<string, CachedEmote>
  emoteList: CachedEmote[]
  recentlyUsed: string[]
  status: 'idle' | 'loading' | 'ready' | 'error'
  lastFetchedAt: number | null

  initializeEmotes: () => Promise<void>
  addRecentlyUsed: (name: string) => void
  addEmote: (emote: CachedEmote) => void
  searchOnline: (query: string, page?: number) => Promise<CachedEmote[]>
}

const BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:8000'

// Fallback direct 7TV endpoints — used when the backend proxy is unavailable
const SEVEN_TV_API = 'https://7tv.io/v3'
const SEVEN_TV_GQL = 'https://7tv.io/v3/gql'

const REFRESH_INTERVAL = 30 * 60 * 1000 // 30 minutes
const MAX_RECENT = 24
const STORAGE_KEY = 'blakjaks_emote_recent'

function getStoredRecent(): string[] {
  if (typeof window === 'undefined') return []
  try {
    const stored = localStorage.getItem(STORAGE_KEY)
    return stored ? JSON.parse(stored) : []
  } catch {
    return []
  }
}

export function getEmoteUrl(id: string, size: '1x' | '2x' | '3x' | '4x' = '2x'): string {
  return `https://cdn.7tv.app/emote/${id}/${size}.webp`
}

function normalizeGqlEmote(e: {
  id: string
  name: string
  animated: boolean
  flags: number
}): CachedEmote {
  return {
    id: e.id,
    name: e.name,
    animated: e.animated,
    zeroWidth: (e.flags & 1) === 1,
  }
}

export const useEmoteStore = create<EmoteStore>((set, get) => ({
  emotes: new Map(),
  emoteList: [],
  recentlyUsed: getStoredRecent(),
  status: 'idle',
  lastFetchedAt: null,

  initializeEmotes: async () => {
    const { lastFetchedAt, status } = get()
    if (status === 'loading') return
    if (lastFetchedAt && Date.now() - lastFetchedAt < REFRESH_INTERVAL) return

    set({ status: 'loading' })

    /**
     * Attempt 1: fetch from the backend proxy at GET /api/emotes.
     * The backend is expected to cache and return the same shape as the
     * 7TV global emote-set endpoint: { emotes: Array<{ id, name, data: { animated, flags } }> }
     *
     * Attempt 2 (fallback): fetch directly from 7TV CDN if the backend
     * proxy returns a non-OK status or the request fails entirely.
     */
    const token = typeof window !== 'undefined' ? localStorage.getItem('blakjaks_token') : null
    const headers: Record<string, string> = {}
    if (token) headers['Authorization'] = `Bearer ${token}`

    let data: { emotes?: Array<{ id: string; name: string; data?: { animated?: boolean; flags?: number } }> } | null = null

    try {
      const res = await fetch(`${BASE_URL}/api/emotes`, { headers })
      if (res.ok) {
        data = await res.json()
      }
    } catch {
      // Backend unavailable — fall through to 7TV direct
    }

    if (!data) {
      // Fallback: fetch directly from 7TV
      try {
        const res = await fetch(`${SEVEN_TV_API}/emote-sets/global`)
        if (res.ok) {
          data = await res.json()
        }
      } catch {
        // Both attempts failed
      }
    }

    if (!data) {
      set({ status: 'error' })
      return
    }

    const emoteMap = new Map<string, CachedEmote>()
    const emoteList: CachedEmote[] = []

    for (const e of data.emotes ?? []) {
      const emote: CachedEmote = {
        id: e.id,
        name: e.name,
        animated: e.data?.animated ?? false,
        zeroWidth: ((e.data?.flags ?? 0) & 1) === 1,
      }
      emoteMap.set(e.name, emote)
      emoteList.push(emote)
    }

    emoteList.sort((a, b) => a.name.localeCompare(b.name))

    set({
      emotes: emoteMap,
      emoteList,
      status: 'ready',
      lastFetchedAt: Date.now(),
    })
  },

  addRecentlyUsed: (name: string) => {
    const { recentlyUsed } = get()
    if (recentlyUsed.includes(name)) return
    const updated = [name, ...recentlyUsed].slice(0, MAX_RECENT)
    if (typeof window !== 'undefined') {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(updated))
    }
    set({ recentlyUsed: updated })
  },

  // Add an emote to the local cache (so it renders in chat after being selected from search)
  addEmote: (emote: CachedEmote) => {
    const { emotes, emoteList } = get()
    if (emotes.has(emote.name)) return
    const newMap = new Map(emotes)
    newMap.set(emote.name, emote)
    set({
      emotes: newMap,
      emoteList: [...emoteList, emote].sort((a, b) => a.name.localeCompare(b.name)),
    })
  },

  /**
   * Search the full 7TV database via GraphQL (1.5M+ emotes).
   *
   * Primary: POST /api/emotes/search on the backend proxy.
   * Fallback: POST directly to 7TV GQL endpoint.
   */
  searchOnline: async (query: string, page: number = 1): Promise<CachedEmote[]> => {
    if (!query || query.length < 2) return []

    const gqlBody = JSON.stringify({
      query: `query SearchEmotes($query: String!, $page: Int!, $limit: Int!) {
        emotes(query: $query, page: $page, limit: $limit) {
          items { id name flags animated }
        }
      }`,
      variables: { query, page, limit: 16 },
    })

    // Try backend proxy first
    try {
      const token = typeof window !== 'undefined' ? localStorage.getItem('blakjaks_token') : null
      const headers: Record<string, string> = { 'Content-Type': 'application/json' }
      if (token) headers['Authorization'] = `Bearer ${token}`

      const res = await fetch(`${BASE_URL}/api/emotes/search`, {
        method: 'POST',
        headers,
        body: gqlBody,
      })

      if (res.ok) {
        const data = await res.json()
        const items = data?.data?.emotes?.items ?? []
        return items.map(normalizeGqlEmote)
      }
    } catch {
      // Fall through to direct 7TV
    }

    // Fallback: direct 7TV GQL
    try {
      const res = await fetch(SEVEN_TV_GQL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: gqlBody,
      })
      if (!res.ok) return []
      const data = await res.json()
      const items = data?.data?.emotes?.items ?? []
      return items.map(normalizeGqlEmote)
    } catch {
      return []
    }
  },
}))
