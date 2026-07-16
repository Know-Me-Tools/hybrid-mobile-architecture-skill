// TJ-ARCH-MOB-001 compliant — store layer (the ONLY place invoke() is called).
import { create } from 'zustand'
import { immer } from 'zustand/middleware/immer'
import { isTauri } from '@tauri-apps/api/core'
import { memoryIngest, memorySearch } from '@prometheus-ags/tauri-plugin-gen-ui'

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
        // NOTE: the plugin's memory_search currently returns string[] (a stub —
        // real graph-RAG search lands in C-104), not MemoryHit[] as this store's
        // type expects. Cast is a known, tracked mismatch, not a silent fix.
        const hits = isTauri() ? ((await memorySearch(query, 8)) as unknown as MemoryHit[]) : []
        set((s) => { s.hits = hits })
      } catch (e) {
        set((s) => { s.error = String(e); s.hits = [] })
      } finally {
        set((s) => { s.isSearching = false })
      }
    },
  })),
)
