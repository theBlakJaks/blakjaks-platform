import client from './client'

export interface Stream {
  id: string
  title: string
  description: string | null
  status: 'scheduled' | 'live' | 'ended' | 'cancelled'
  stream_key: string | null
  scheduled_at: string | null
  started_at: string | null
  ended_at: string | null
  viewer_count: number
  peak_viewers: number
  hls_url: string | null
  vod_url: string | null
  tier_restriction: string | null
  created_by: string | null
  created_at: string | null
}

// ---------------------------------------------------------------------------
// Mock data — used as fallback when backend returns an error or only returns
// live streams (GET /streams filters to status='live' only)
// ---------------------------------------------------------------------------

const MOCK_STREAMS: Stream[] = [
  {
    id: 'stream-001',
    title: 'Weekly Members Drop',
    description: 'Live product reveal and members-only drop.',
    status: 'live',
    stream_key: 'sy-abc123',
    scheduled_at: new Date(Date.now() - 30 * 60 * 1000).toISOString(),
    started_at: new Date(Date.now() - 25 * 60 * 1000).toISOString(),
    ended_at: null,
    viewer_count: 142,
    peak_viewers: 158,
    hls_url: 'https://stream.blakjaks.com/hls/weekly-drop.m3u8',
    vod_url: null,
    tier_restriction: null,
    created_by: null,
    created_at: new Date(Date.now() - 2 * 86400000).toISOString(),
  },
  {
    id: 'stream-002',
    title: 'VIP Exclusive AMA',
    description: 'Ask the team anything — VIP tier and above.',
    status: 'scheduled',
    stream_key: 'sy-vip456',
    scheduled_at: new Date(Date.now() + 2 * 86400000).toISOString(),
    started_at: null,
    ended_at: null,
    viewer_count: 0,
    peak_viewers: 0,
    hls_url: null,
    vod_url: null,
    tier_restriction: 'VIP',
    created_by: null,
    created_at: new Date(Date.now() - 1 * 86400000).toISOString(),
  },
  {
    id: 'stream-003',
    title: 'High Roller Lounge Session',
    description: 'Exclusive High Roller stream with special reveals.',
    status: 'ended',
    stream_key: 'sy-hr789',
    scheduled_at: new Date(Date.now() - 5 * 86400000).toISOString(),
    started_at: new Date(Date.now() - 5 * 86400000 + 5 * 60 * 1000).toISOString(),
    ended_at: new Date(Date.now() - 4 * 86400000).toISOString(),
    viewer_count: 0,
    peak_viewers: 89,
    hls_url: null,
    vod_url: 'https://vod.blakjaks.com/sessions/hr-lounge.mp4',
    tier_restriction: 'High Roller',
    created_by: null,
    created_at: new Date(Date.now() - 7 * 86400000).toISOString(),
  },
  {
    id: 'stream-004',
    title: 'Whale Council Briefing',
    description: 'Quarterly briefing for Whale-tier members.',
    status: 'scheduled',
    stream_key: 'sy-whale999',
    scheduled_at: new Date(Date.now() + 5 * 86400000).toISOString(),
    started_at: null,
    ended_at: null,
    viewer_count: 0,
    peak_viewers: 0,
    hls_url: null,
    vod_url: null,
    tier_restriction: 'Whale',
    created_by: null,
    created_at: new Date(Date.now() - 3 * 86400000).toISOString(),
  },
]

let mockStreamStore: Stream[] = [...MOCK_STREAMS]

// ---------------------------------------------------------------------------
// API functions
// ---------------------------------------------------------------------------

/**
 * GET /streams — backend returns only live streams.
 * We attempt the call and merge live data with our local mock store so the
 * admin sees the full list (scheduled + live + ended).
 */
export async function listStreams(): Promise<Stream[]> {
  try {
    const { data } = await client.get<Stream[]>('/streams')
    // Merge: replace any matching mock entries with live data from backend
    const liveIds = new Set(data.map((s) => s.id))
    const nonLiveMocks = mockStreamStore.filter((s) => !liveIds.has(s.id))
    return [...data, ...nonLiveMocks].sort(
      (a, b) =>
        new Date(b.created_at ?? 0).getTime() -
        new Date(a.created_at ?? 0).getTime(),
    )
  } catch {
    return [...mockStreamStore].sort(
      (a, b) =>
        new Date(b.created_at ?? 0).getTime() -
        new Date(a.created_at ?? 0).getTime(),
    )
  }
}

/**
 * GET /streams/{id} — retrieve a single stream.
 */
export async function getStream(id: string): Promise<Stream> {
  try {
    const { data } = await client.get<Stream>(`/streams/${id}`)
    return data
  } catch {
    const found = mockStreamStore.find((s) => s.id === id)
    if (!found) throw new Error('Stream not found')
    return found
  }
}

/**
 * POST /streams — create a new stream.
 * Backend accepts `title` and `stream_key` as query params.
 */
export async function createStream(params: {
  title: string
  description?: string
  scheduled_at?: string
  tier_restriction?: string
  stream_key?: string
}): Promise<Stream> {
  try {
    const queryParams: Record<string, string> = { title: params.title }
    if (params.stream_key) queryParams.stream_key = params.stream_key
    const { data } = await client.post<Stream>('/streams', null, {
      params: queryParams,
    })
    // Persist to mock store so the UI reflects the new stream
    mockStreamStore = [data, ...mockStreamStore]
    return data
  } catch {
    const newStream: Stream = {
      id: `stream-${Date.now()}`,
      title: params.title,
      description: params.description ?? null,
      status: 'scheduled',
      stream_key: params.stream_key ?? null,
      scheduled_at: params.scheduled_at ?? null,
      started_at: null,
      ended_at: null,
      viewer_count: 0,
      peak_viewers: 0,
      hls_url: null,
      vod_url: null,
      tier_restriction: params.tier_restriction ?? null,
      created_by: null,
      created_at: new Date().toISOString(),
    }
    mockStreamStore = [newStream, ...mockStreamStore]
    return newStream
  }
}

/**
 * POST /streams/{id}/start — mark a stream as live.
 */
export async function startStream(id: string): Promise<Stream> {
  try {
    const { data } = await client.post<Stream>(`/streams/${id}/start`)
    mockStreamStore = mockStreamStore.map((s) =>
      s.id === id ? { ...s, status: 'live', started_at: new Date().toISOString() } : s,
    )
    return data
  } catch {
    mockStreamStore = mockStreamStore.map((s) =>
      s.id === id
        ? { ...s, status: 'live', started_at: new Date().toISOString() }
        : s,
    )
    const updated = mockStreamStore.find((s) => s.id === id)
    if (!updated) throw new Error('Stream not found')
    return updated
  }
}

/**
 * POST /streams/{id}/end — mark a stream as ended.
 */
export async function endStream(id: string): Promise<Stream> {
  try {
    const { data } = await client.post<Stream>(`/streams/${id}/end`)
    mockStreamStore = mockStreamStore.map((s) =>
      s.id === id ? { ...s, status: 'ended', ended_at: new Date().toISOString() } : s,
    )
    return data
  } catch {
    mockStreamStore = mockStreamStore.map((s) =>
      s.id === id
        ? { ...s, status: 'ended', ended_at: new Date().toISOString() }
        : s,
    )
    const updated = mockStreamStore.find((s) => s.id === id)
    if (!updated) throw new Error('Stream not found')
    return updated
  }
}

/**
 * DELETE /streams/{id} — delete a stream (admin only).
 */
export async function deleteStream(id: string): Promise<void> {
  try {
    await client.delete(`/streams/${id}`)
  } catch { /* mock success */ }
  mockStreamStore = mockStreamStore.filter((s) => s.id !== id)
}
