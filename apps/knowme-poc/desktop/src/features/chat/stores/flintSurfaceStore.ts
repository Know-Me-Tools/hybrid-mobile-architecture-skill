// TJ-ARCH-MOB-001 compliant — core-fed A2UI surface state; no Flint network transport.
import { listen } from '@tauri-apps/api/event'
import { create } from 'zustand'
import type { A2uiComponentSpec } from '@flint/react'

interface SurfaceState {
  surfaces: Record<string, A2uiComponentSpec[]>
  start: () => () => void
}

export const useFlintSurfaceStore = create<SurfaceState>((set) => ({
  surfaces: {},
  start: () => {
    const pending = listen<{ surfaceId: string; components: A2uiComponentSpec[] }>(
      'a2ui_surface_event',
      ({ payload }) => set((state) => ({ surfaces: { ...state.surfaces, [payload.surfaceId]: payload.components } })),
    )
    return () => { void pending.then((unlisten) => unlisten()) }
  },
}))
