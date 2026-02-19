import type { CachedEmote } from './emote-store'

export type TextSegment = { type: 'text'; value: string }
export type EmoteSegment = { type: 'emote'; emote: CachedEmote; zeroWidth: boolean }
export type Segment = TextSegment | EmoteSegment

export function parseMessageToSegments(
  content: string,
  emoteMap: Map<string, CachedEmote>,
): Segment[] {
  if (!content || emoteMap.size === 0) {
    return content ? [{ type: 'text', value: content }] : []
  }

  // Split preserving whitespace tokens
  const tokens = content.split(/(\s+)/)
  const segments: Segment[] = []
  let prevWasEmote = false

  for (const token of tokens) {
    // Whitespace tokens
    if (/^\s+$/.test(token)) {
      segments.push({ type: 'text', value: token })
      continue
    }

    const emote = emoteMap.get(token)
    if (emote) {
      const isZeroWidth = emote.zeroWidth && prevWasEmote
      segments.push({ type: 'emote', emote, zeroWidth: isZeroWidth })
      prevWasEmote = true
    } else {
      segments.push({ type: 'text', value: token })
      prevWasEmote = false
    }
  }

  return segments
}

export function searchEmotes(
  query: string,
  emoteList: CachedEmote[],
  limit = 50,
): CachedEmote[] {
  if (!query) return emoteList.slice(0, limit)
  const lower = query.toLowerCase()
  return emoteList
    .filter(e => e.name.toLowerCase().includes(lower))
    .slice(0, limit)
}

export function prefixMatchEmotes(
  prefix: string,
  emoteList: CachedEmote[],
  limit = 5,
): CachedEmote[] {
  if (prefix.length < 2) return []
  const lower = prefix.toLowerCase()
  return emoteList
    .filter(e => e.name.toLowerCase().startsWith(lower))
    .slice(0, limit)
}
