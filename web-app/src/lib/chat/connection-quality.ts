/**
 * Connection quality monitor — tracks RTT and derives quality level.
 *
 * RTT is measured by client-initiated ping: the client sends {type: 'ping'}
 * with an internal timestamp and measures the time until the server responds
 * with {type: 'pong'}. This measures actual network latency, not server
 * scheduling jitter.
 *
 * Thresholds:
 *   good     — avg RTT < 200ms
 *   degraded — avg RTT 200–800ms
 *   poor     — avg RTT > 800ms or missed pong
 */

import type { ConnectionQuality } from './types'

const WINDOW_SIZE = 5
const GOOD_THRESHOLD_MS = 200
const POOR_THRESHOLD_MS = 800

export class ConnectionQualityMonitor {
  private _samples: number[] = []
  private _quality: ConnectionQuality = 'good'

  onChange: ((quality: ConnectionQuality) => void) | null = null

  get quality(): ConnectionQuality {
    return this._quality
  }

  get averageRtt(): number {
    if (this._samples.length === 0) return 0
    return this._samples.reduce((a, b) => a + b, 0) / this._samples.length
  }

  recordRtt(ms: number): void {
    this._samples.push(ms)
    if (this._samples.length > WINDOW_SIZE) {
      this._samples.shift()
    }
    this._evaluate()
  }

  recordMissedPong(): void {
    this._setQuality('poor')
  }

  reset(): void {
    this._samples = []
    this._setQuality('good')
  }

  private _evaluate(): void {
    const avg = this.averageRtt
    if (avg > POOR_THRESHOLD_MS) {
      this._setQuality('poor')
    } else if (avg > GOOD_THRESHOLD_MS) {
      this._setQuality('degraded')
    } else {
      this._setQuality('good')
    }
  }

  private _setQuality(q: ConnectionQuality): void {
    if (this._quality === q) return
    this._quality = q
    this.onChange?.(q)
  }
}
