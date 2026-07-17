// TJ-ARCH-MOB-001 compliant
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { AppProviders } from './app/providers'
import { StartupGate } from './features/startup/components/StartupGate'
import { useChatStore } from './features/chat/stores/chatStore'
import { EntityRuntimeBoundary } from './features/entities/components/EntityRuntimeBoundary'
import './index.css'

// Initialize Rust event listeners (store-level, not component-level)
const cleanup = useChatStore.getState().initListeners()
window.addEventListener('beforeunload', cleanup)

// StartupGate blocks the app until the first-run boot sequence (migrations →
// seeds → shapes) reaches ready — the boot-order invariant made visible.
createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <StartupGate>
      <EntityRuntimeBoundary>
        <AppProviders />
      </EntityRuntimeBoundary>
    </StartupGate>
  </StrictMode>
)
