// TJ-ARCH-MOB-001 compliant
import { useEffect } from 'react'
import { useFlintSurfaceStore } from '../stores/flintSurfaceStore'

export function useFlintSurface(surfaceId: string) {
  const components = useFlintSurfaceStore((state) => state.surfaces[surfaceId] ?? [])
  const start = useFlintSurfaceStore((state) => state.start)
  useEffect(() => start(), [start])
  return { components }
}
