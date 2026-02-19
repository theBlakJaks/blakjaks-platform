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
    try {
      const res = await fetch(`${SEVEN_TV_API}/emote-sets/global`)
      if (!res.ok) throw new Error(`7TV API error: ${res.status}`)
      const data = await res.json()

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
    } catch {
      set({ status: 'error' })
    }
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

  // Search the full 7TV database via GraphQL (1.5M+ emotes)
  searchOnline: async (query: string, page: number = 1): Promise<CachedEmote[]> => {
    if (!query || query.length < 2) return []
    try {
      const res = await fetch(SEVEN_TV_GQL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          query: `query SearchEmotes($query: String!, $page: Int!, $limit: Int!) {
            emotes(query: $query, page: $page, limit: $limit) {
              items { id name flags animated }
            }
          }`,
          variables: { query, page, limit: 16 },
        }),
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
