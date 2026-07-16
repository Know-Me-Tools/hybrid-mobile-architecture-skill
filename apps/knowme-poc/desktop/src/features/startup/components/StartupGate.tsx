// TJ-ARCH-MOB-001 compliant — component imports the hook only.
import type { ReactNode } from 'react'
import { useStartup } from '../hooks/useStartup'

export function StartupGate({ children }: { children: ReactNode }) {
  const { error, isReady, label, progress } = useStartup()
  if (error) return <div role="alert">Startup failed: {error}</div>
  if (isReady) return <>{children}</>
  return (
    <div aria-live="polite" aria-busy="true">
      <progress value={progress} max={1} />
      <p>{label}</p>
    </div>
  )
}
