// TJ-ARCH-MOB-001 compliant
import { useEffect } from 'react'
import { startEntityRuntime } from '../stores/entityRuntime'

export function useEntityRuntime(tenantId: string | null): void {
  useEffect(() => {
    if (!tenantId) return
    let dispose: (() => void) | undefined
    void startEntityRuntime(tenantId).then((cleanup) => { dispose = cleanup })
    return () => dispose?.()
  }, [tenantId])
}
