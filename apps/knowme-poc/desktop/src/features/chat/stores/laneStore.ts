// TJ-ARCH-MOB-001 compliant — store layer
//
// Which inference lane chat runs on, and the throughput of the last local run.
//
// Three surfaces, one toggle:
//   - Tauri desktop → the Rust local lane (mistral.rs), via the plugin.
//   - Plain web     → the WebLLM lane (webllmLane.ts), driven in-browser.
//   - Neither       → cloud only; the toggle is hidden rather than shown broken.
import { create } from 'zustand'
import { immer } from 'zustand/middleware/immer'
import { isTauri } from '@tauri-apps/api/core'
import { getActiveLane, setActiveLane, hasLocalEngine } from '@prometheus-ags/tauri-plugin-gen-ui'
import type { ChatLane } from '@prometheus-ags/tauri-plugin-gen-ui'
import { isWebGpuAvailable, loadWebLlm, unloadWebLlm } from '../api/webllmLane'

/** Tokens/sec for a completed local run — the honest cost of on-device inference. */
export interface Throughput {
  tokens: number
  seconds: number
  tokensPerSecond: number
}

/** Model-download/init progress, 0..1, while the local lane warms up. */
export interface LaneLoadProgress {
  progress: number
  text: string
}

interface LaneState {
  lane: ChatLane
  /** False when neither a Rust engine nor WebGPU is available — hide the toggle. */
  localAvailable: boolean
  /** Non-null only while the web lane is fetching/initialising weights. */
  loadProgress: LaneLoadProgress | null
  /** Last completed local run's throughput. Null on cloud or before a first run. */
  throughput: Throughput | null
  /** Why the last lane switch failed, for surfacing instead of silently reverting. */
  error: string | null
}

interface LaneActions {
  init: () => Promise<void>
  switchLane: (lane: ChatLane) => Promise<void>
  recordThroughput: (tokens: number, seconds: number) => void
  clearThroughput: () => void
}

export const useLaneStore = create<LaneState & LaneActions>()(
  immer((set) => ({
    lane: 'cloud',
    localAvailable: false,
    loadProgress: null,
    throughput: null,
    error: null,

    init: async () => {
      if (isTauri()) {
        // Store is the only layer that calls invoke().
        const [available, lane] = await Promise.all([
          hasLocalEngine().catch(() => false),
          getActiveLane().catch((): ChatLane => 'cloud'),
        ])
        set((s) => { s.localAvailable = available; s.lane = lane })
        return
      }
      // Plain web: WebGPU decides. Lane choice isn't persisted here — the Rust
      // config DB isn't reachable from the browser bundle — so the web lane
      // starts on cloud each session.
      set((s) => { s.localAvailable = isWebGpuAvailable() })
    },

    switchLane: async (lane) => {
      set((s) => { s.error = null })
      try {
        if (isTauri()) {
          await setActiveLane(lane)
          set((s) => { s.lane = lane; if (lane === 'cloud') s.throughput = null })
          return
        }
        if (lane === 'local') {
          // Warm the engine at switch time, not at first message: a ~1GB download
          // is not something to discover mid-conversation.
          await loadWebLlm((p) => set((s) => { s.loadProgress = p }))
        } else {
          await unloadWebLlm()
        }
        set((s) => {
          s.lane = lane
          s.loadProgress = null
          if (lane === 'cloud') s.throughput = null
        })
      } catch (e: unknown) {
        // Stay on the current lane and say why. Never silently fall back to
        // cloud — a user who asked for on-device inference must not be quietly
        // switched to a network provider.
        set((s) => {
          s.error = e instanceof Error ? e.message : 'failed to switch lane'
          s.loadProgress = null
        })
      }
    },

    recordThroughput: (tokens, seconds) =>
      set((s) => {
        // Guard against a zero/absurd elapsed time producing an Infinity readout.
        s.throughput = seconds > 0
          ? { tokens, seconds, tokensPerSecond: tokens / seconds }
          : null
      }),

    clearThroughput: () => set((s) => { s.throughput = null }),
  })),
)
