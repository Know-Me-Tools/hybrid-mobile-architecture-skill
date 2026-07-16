// TJ-ARCH-MOB-001 compliant — store layer (the ONLY place invoke() is called).
import { create } from 'zustand'
import { immer } from 'zustand/middleware/immer'
import { isTauri } from '@tauri-apps/api/core'
import { memoryIngest, memorySearch } from '@prometheus-ags/tauri-plugin-gen-ui'
import type { MemoryHit } from '@prometheus-ags/tauri-plugin-gen-ui'

// MemoryHit is re-exported from the plugin's typed bindings rather than
// hand-mirrored here. It used to be a local interface with `name`/`snippet`,
// which drifted from the Rust type (`text`/`kind`) when C-104 landed — Flutter
// was updated, this wasn't, and an `as unknown as` cast at the call site kept
// tsc quiet about it. One definition, generated from the source of truth.
export type { MemoryHit }

interface MemoryState {
  query: string
  hits: MemoryHit[]
  isIngesting: boolean
  isSearching: boolean
  error: string | null
}

interface MemoryActions {
  ingest: (text: string) => Promise<void>
  search: (query: string) => Promise<void>
}

// memory_search / memory_ingest are the ONLY graph surface the UI sees. On web
// (no Tauri) the wasm core still owns the store; until it is wired, ingest/search
// no-op rather than reaching into the browser for graph logic (layer contract).
export const useMemoryStore = create<MemoryState & MemoryActions>()(
  immer((set) => ({
    query: '',
    hits: [],
    isIngesting: false,
    isSearching: false,
    error: null,

    ingest: async (text: string) => {
      set((s) => { s.isIngesting = true; s.error = null })
      try {
        if (isTauri()) await memoryIngest(text)
      } catch (e) {
        set((s) => { s.error = String(e) })
      } finally {
        set((s) => { s.isIngesting = false })
      }
    },

    search: async (query: string) => {
      set((s) => { s.isSearching = true; s.error = null; s.query = query })
      try {
        // No cast: memory_search now returns real MemoryHits (C-104's agent
        // delegation reached the desktop command in C-113). Outside Tauri there
        // is no Rust side to ask, so results stay empty.
        const hits = isTauri() ? await memorySearch(query, 8) : []
        set((s) => { s.hits = hits })
      } catch (e) {
        set((s) => { s.error = String(e); s.hits = [] })
      } finally {
        set((s) => { s.isSearching = false })
      }
    },
  })),
)
