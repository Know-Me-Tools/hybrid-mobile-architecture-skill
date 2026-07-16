// TJ-ARCH-MOB-001 compliant — store layer (the ONLY place invoke() is called).
import { create } from 'zustand'
import { immer } from 'zustand/middleware/immer'
import { invoke, isTauri } from '@tauri-apps/api/core'

/** Mirror of gen_ui_db::graph::EntityHit — the fused RRF result. snake_case wire. */
export interface MemoryHit {
  id: string
  name: string
  score: number
  snippet?: string | null
}

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
        if (isTauri()) await invoke<string>('memory_ingest', { text })
      } catch (e) {
        set((s) => { s.error = String(e) })
      } finally {
        set((s) => { s.isIngesting = false })
      }
    },

    search: async (query: string) => {
      set((s) => { s.isSearching = true; s.error = null; s.query = query })
      try {
        const hits = isTauri()
          ? await invoke<MemoryHit[]>('memory_search', { query, k: 8 })
          : []
        set((s) => { s.hits = hits })
      } catch (e) {
        set((s) => { s.error = String(e); s.hits = [] })
      } finally {
        set((s) => { s.isSearching = false })
      }
    },
  })),
)
