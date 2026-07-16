// TJ-ARCH-MOB-001 compliant — store layer (the ONLY place invoke() is called).
import { create } from 'zustand'
import { invoke, isTauri } from '@tauri-apps/api/core'

export type StartupPhase = 'migrations' | 'seeds' | 'shapes' | 'ready'

export const PHASE_ORDER: StartupPhase[] = ['migrations', 'seeds', 'shapes', 'ready']

const PHASE_PROGRESS: Record<StartupPhase, number> = {
  migrations: 0.25,
  seeds: 0.5,
  shapes: 0.85,
  ready: 1,
}
export const phaseProgress = (p: StartupPhase): number => PHASE_PROGRESS[p]

interface StartupState {
  phase: StartupPhase
  error: string | null
  run: () => Promise<void>
}

// Boot-order invariant: migrations → seeds → shapes. Sync shapes fail on unknown
// columns, so migrations+seeds MUST run first. On web the wasm core runs the same
// sequence; until wired, the steps resolve immediately so the gate opens.
export const useStartupStore = create<StartupState>((set) => ({
  phase: 'migrations',
  error: null,
  run: async () => {
    try {
      set({ phase: 'migrations', error: null })
      if (isTauri()) await invoke<void>('run_migrations')
      set({ phase: 'seeds' })
      if (isTauri()) await invoke<void>('load_seeds')
      set({ phase: 'shapes' })
      if (isTauri()) await invoke<void>('attach_sync_shapes')
      set({ phase: 'ready' })
    } catch (e) {
      set({ error: String(e) })
    }
  },
}))
