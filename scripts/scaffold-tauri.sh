#!/usr/bin/env bash
# scripts/scaffold-tauri.sh
# Scaffold a Tauri 2.x + React 19 + Vite 8 desktop/web app
# Usage: bash scripts/scaffold-tauri.sh <output-dir> <app-name>

set -euo pipefail

OUT="${1:-desktop}"
APP_NAME="${2:-my-desktop-app}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# A standalone Tauri scaffold still needs the shared ContentBlock package. In a
# full hybrid scaffold C-007 already emitted it before this script runs.
if [[ ! -f "$OUT/../packages/gen-ui-react/package.json" ]]; then
  bash "$SCRIPT_DIR/scaffold-packages.sh" "$OUT/.."
fi

GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
step() { echo -e "\n${CYAN}── $1${NC}"; }
ok()   { echo -e "${GREEN}  ✓${NC} $1"; }

step "Creating Tauri + React 19 app: $APP_NAME"
mkdir -p "$OUT"
cd "$OUT"

# ── package.json ───────────────────────────────────────────────────────────
step "Writing package.json"
cat > package.json << PKGEOF
{
  "name": "${APP_NAME}",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev":         "vite",
    "build":       "tsc && vite build",
    "preview":     "vite preview",
    "tauri":       "tauri",
    "tauri:dev":   "tauri dev",
    "tauri:build": "tauri build",
    "lint":        "eslint src --ext .ts,.tsx",
    "format":      "prettier --write src",
    "test":        "vitest run",
    "test:watch":  "vitest"
  },
  "dependencies": {
    "react":                  "^19.0.0",
    "react-dom":              "^19.0.0",
    "@tauri-apps/api":        "^2.0.0",
    "@tauri-apps/plugin-shell": "^2.0.0",
    "@tauri-apps/plugin-store": "^2.0.0",
    "@tauri-apps/plugin-os":  "^2.0.0",
    "zustand":                "^5.0.0",
    "immer":                  "^10.0.0",
    "@tanstack/react-query":  "^5.0.0",
    "@tanstack/react-router": "^1.0.0",
    "@tanstack/react-table":  "^8.0.0",
    "@tanstack/react-virtual": "^3.0.0",
    "@electric-sql/pglite":   "0.5.4",
    "@electric-sql/pglite-sync": "^0.4.0",
    "@prometheus-ags/prometheus-entity-management": "3.0.0-alpha.0",
    "@prometheus-ags/gen-ui-react": "file:../packages/gen-ui-react",
    "@prometheus-ags/tauri-plugin-gen-ui": "file:../rust/crates/tauri-plugin-gen-ui/guest-js",
    "@flint/react": "git+https://github.com/Know-Me-Tools/flint-forge.git#1cae090d2cc02675eb99ba7a599735d339e53e38&path:packages/flint-react",
    "tailwindcss":            "^4.0.0",
    "@tailwindcss/vite":      "^4.0.0",
    "lucide-react":           "^0.400.0",
    "class-variance-authority": "^0.7.0",
    "clsx":                   "^2.1.0",
    "tailwind-merge":         "^2.0.0",
    "react-markdown":         "^9.0.0",
    "@codemirror/view":       "^6.0.0",
    "@codemirror/lang-javascript": "^6.0.0",
    "@codesandbox/sandpack-react": "^2.20.0",
    "framer-motion":          "^11.0.0",
    "@assistant-ui/react":    "^0.8.0"
  },
  "devDependencies": {
    "@tauri-apps/cli":        "^2.10.3",
    "vite":                   "^8.0.0",
    "@vitejs/plugin-react":   "^6.0.0",
    "typescript":             "^7.0.0",
    "@types/react":           "^19.0.0",
    "@types/react-dom":       "^19.0.0",
    "@typescript-eslint/eslint-plugin": "^8.0.0",
    "@typescript-eslint/parser": "^8.0.0",
    "eslint":                 "^9.0.0",
    "eslint-plugin-react-hooks": "^5.0.0",
    "prettier":               "^3.0.0",
    "vitest":                 "^3.0.0",
    "@testing-library/react": "^16.0.0",
    "@testing-library/user-event": "^14.0.0",
    "jsdom":                  "^25.0.0"
  }
}
PKGEOF
ok "package.json"

cat > index.html << EOF
<!doctype html>
<html lang="en">
  <head><meta charset="UTF-8" /><meta name="viewport" content="width=device-width, initial-scale=1.0" /><link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Ctext y='26' font-size='28'%3EK%3C/text%3E%3C/svg%3E" /><title>${APP_NAME}</title></head>
  <body><div id="root"></div><script type="module" src="/src/main.tsx"></script></body>
</html>
EOF

# ── tsconfig.json ──────────────────────────────────────────────────────────
cat > tsconfig.json << EOF
{
  "compilerOptions": {
    "target": "ES2022",
    "useDefineForClassFields": true,
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "paths": { "@/*": ["./src/*"] }
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
EOF
ok "tsconfig.json"

cat > tsconfig.node.json << 'EOF'
{
  "compilerOptions": {
    "composite": true,
    "skipLibCheck": true,
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowSyntheticDefaultImports": true
  },
  "include": ["vite.config.ts"]
}
EOF

# ── vite.config.ts ─────────────────────────────────────────────────────────
cat > vite.config.ts << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import path from 'path'

const host = process.env.TAURI_DEV_HOST

export default defineConfig({
  plugins: [react(), tailwindcss()],
  clearScreen: false,
  server: {
    port: 1420,
    strictPort: true,
    host: host || false,
    hmr: host ? { protocol: 'ws', host, port: 1421 } : undefined,
    watch: { ignored: ['**/src-tauri/**'] },
  },
  resolve: { alias: { '@': path.resolve(__dirname, './src') } },
  envPrefix: ['VITE_', 'TAURI_'],
  build: { target: process.env.TAURI_ENV_PLATFORM === 'windows' ? 'chrome105' : 'safari15', minify: !process.env.TAURI_ENV_DEBUG ? 'esbuild' : false, sourcemap: !!process.env.TAURI_ENV_DEBUG },
})
EOF
ok "vite.config.ts"

# ── Feature-based src structure ────────────────────────────────────────────
step "Creating feature-based clean architecture"
mkdir -p src/{app,core/{types,errors,utils,theme},shared/{components/ui,hooks,stores},bridge/{a2ui,agui},features/{chat/{api,stores,queries,hooks,components},entities/{api,stores,queries,hooks,components},memory/{api,stores,queries,hooks,components},settings/{stores,components}}}
ok "src/ directory structure"

# ── App providers ──────────────────────────────────────────────────────────
cat > src/app/providers.tsx << 'EOF'
// TJ-ARCH-MOB-001 compliant
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { RouterProvider } from '@tanstack/react-router'
import { router } from './router'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: { staleTime: 30_000, retry: 1 },
    mutations: { retry: 0 },
  },
})

export function AppProviders() {
  return (
    <QueryClientProvider client={queryClient}>
      <RouterProvider router={router} context={{ queryClient }} />
    </QueryClientProvider>
  )
}
EOF
ok "src/app/providers.tsx"

# ── Router stub ────────────────────────────────────────────────────────────
cat > src/app/router.tsx << 'EOF'
// TJ-ARCH-MOB-001 compliant
import { createRouter, createRootRouteWithContext } from '@tanstack/react-router'
import type { QueryClient } from '@tanstack/react-query'

interface RouterContext { queryClient: QueryClient }

const rootRoute = createRootRouteWithContext<RouterContext>()({
  component: () => <div className="h-screen bg-background">outlet placeholder</div>,
})

export const router = createRouter({
  routeTree: rootRoute,
  context: { queryClient: undefined! },
})

declare module '@tanstack/react-router' {
  interface Register { router: typeof router }
}
EOF
ok "src/app/router.tsx"

# ── Chat store stub ────────────────────────────────────────────────────────
cat > src/features/chat/stores/chatStore.ts << 'EOF'
// TJ-ARCH-MOB-001 compliant — store layer
import { create } from 'zustand'
import { immer } from 'zustand/middleware/immer'
import { subscribeWithSelector } from 'zustand/middleware'
import { listen } from '@tauri-apps/api/event'
import { invoke } from '@tauri-apps/api/core'
import type { ContentBlock, Message, MessageUsage } from '@/bridge/a2ui/types'
import { applyA2uiEvent } from '@/bridge/a2ui/driver'

interface ChatState {
  messages: Message[]
  isStreaming: boolean
  activeRunId: string | null
}

interface ChatActions {
  sendMessage: (text: string) => Promise<void>
  streamBlock: (params: { messageId: string; blockIndex?: number; block: ContentBlock }) => void
  finalizeMessage: (messageId: string, usage?: MessageUsage) => void
  initListeners: () => () => void
}

export const useChatStore = create<ChatState & ChatActions>()(
  subscribeWithSelector(
    immer((set, get) => ({
      messages: [],
      isStreaming: false,
      activeRunId: null,

      streamBlock: ({ messageId, blockIndex, block }) =>
        set((s) => {
          const msg = s.messages.find((m) => m.id === messageId)
          if (!msg) return
          if (blockIndex !== undefined && blockIndex < msg.content.length) {
            msg.content[blockIndex] = block
          } else {
            msg.content.push(block)
          }
        }),

      finalizeMessage: (messageId, usage) =>
        set((s) => {
          const msg = s.messages.find((m) => m.id === messageId)
          if (msg) { msg.isStreaming = false; if (usage) msg.usage = usage }
          s.isStreaming = false
        }),

      sendMessage: async (text: string) => {
        const userMsg: Message = { id: crypto.randomUUID(), role: 'user', content: [{ type: 'text', text }], timestamp: new Date().toISOString() }
        const assistantId = crypto.randomUUID()
        const assistantMsg: Message = { id: assistantId, role: 'assistant', content: [], timestamp: new Date().toISOString(), isStreaming: true }
        set((s) => { s.messages.push(userMsg, assistantMsg); s.isStreaming = true })
        // Store calls invoke() — never component or hook
        await invoke('stream_agent_a2ui', {
          userMessage: text,
          messages: get().messages.slice(0, -1).flatMap((m) => [m.role, m.content.find(b => b.type === 'text')?.text ?? '']),
        }).catch(console.error)
      },

      initListeners: () => {
        // Wire A2UI events from Rust to store
        const unlistenPromise = listen('a2ui_event', (event: { payload: unknown }) => {
          const store = useChatStore.getState()
          applyA2uiEvent(event.payload as never, store.streamBlock, store.finalizeMessage)
        })
        return () => { unlistenPromise.then((fn) => fn()) }
      },
    }))
  )
)
EOF
ok "src/features/chat/stores/chatStore.ts"

# ── Bridge types stub ──────────────────────────────────────────────────────
cat > src/bridge/a2ui/types.ts << 'EOF'
// TJ-ARCH-MOB-001 compliant
export type { ContentBlock } from '@prometheus-ags/gen-ui-react'
import type { ContentBlock } from '@prometheus-ags/gen-ui-react'
export interface MessageUsage { inputTokens?: number; outputTokens?: number; cacheReadTokens?: number; thinkingTokens?: number }
export interface Message { id: string; role: 'user' | 'assistant' | 'system'; content: ContentBlock[]; timestamp: string; isStreaming?: boolean; usage?: MessageUsage }
EOF
ok "src/bridge/a2ui/types.ts"

cat > src/bridge/a2ui/driver.ts << 'EOF'
// TJ-ARCH-MOB-001 compliant
import type { ContentBlock, MessageUsage } from './types'

export type CoreA2uiEvent =
  | { type: 'contentBlock'; messageId: string; blockIndex?: number; block: ContentBlock }
  | { type: 'messageComplete'; messageId: string; usage?: MessageUsage }

export function applyA2uiEvent(
  event: CoreA2uiEvent,
  streamBlock: (value: { messageId: string; blockIndex?: number; block: ContentBlock }) => void,
  finalize: (messageId: string, usage?: MessageUsage) => void,
): void {
  switch (event.type) {
    case 'contentBlock': streamBlock(event); break
    case 'messageComplete': finalize(event.messageId, event.usage); break
  }
}
EOF

# Shared relational DDL is consumed by Rust migrations and PEM registration.
cat > src/features/entities/schema.sql << 'EOF'
-- TJ-ARCH-MOB-001 compliant
CREATE TABLE IF NOT EXISTS projects (
  id uuid PRIMARY KEY,
  tenant_id uuid NOT NULL,
  name text NOT NULL,
  description text,
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS notes (
  id uuid PRIMARY KEY,
  tenant_id uuid NOT NULL,
  project_id uuid NOT NULL,
  title text NOT NULL,
  body text NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);
EOF

cat > src/features/entities/stores/entityRuntime.ts << 'EOF'
// TJ-ARCH-MOB-001 compliant — all Tauri IPC lives in this store module.
import { invoke, isTauri } from '@tauri-apps/api/core'
import { PGlite } from '@electric-sql/pglite'
import {
  createPGlitePersistenceAdapter,
  registerEntityFromSql,
  registerEntityTransport,
  startLocalFirstGraph,
  type EntityTransport,
} from '@prometheus-ags/prometheus-entity-management'
import schemaSql from '../schema.sql?raw'

export interface EntityRow { id: string; tenant_id: string; [key: string]: unknown }

interface EntityRuntimeSession {
  tenantId: string
  dispose: () => void
}

let session: EntityRuntimeSession | null = null
let sessionInflight: Promise<EntityRuntimeSession> | null = null
let consumers = 0

function tauriTransport(entityType: string): EntityTransport<EntityRow> {
  return {
    identify: (row) => row.id,
    authoritative: true,
    list: (query) => invoke('entity_list', { view: { entityType, ...query } }),
    get: (id) => invoke('entity_get', { entityType, id }),
  }
}

function pgliteTransport(db: PGlite, table: string, tenantId: string): EntityTransport<EntityRow> {
  return {
    identify: (row) => row.id,
    authoritative: true,
    list: async ({ limit = 100 }) => {
      const result = await db.query<EntityRow>(
        `SELECT * FROM ${table} WHERE tenant_id = $1 ORDER BY updated_at DESC LIMIT $2`,
        [tenantId, limit],
      )
      return { rows: result.rows, total: result.rows.length, nextCursor: null }
    },
    get: async (id) => {
      const result = await db.query<EntityRow>(
        `SELECT * FROM ${table} WHERE tenant_id = $1 AND id = $2 LIMIT 1`, [tenantId, id],
      )
      return result.rows[0] ?? null
    },
  }
}

async function createEntityRuntime(tenantId: string): Promise<EntityRuntimeSession> {
  const [projectsDdl, notesDdl] = schemaSql.split(';').filter((sql) => sql.includes('CREATE TABLE'))
  if (!projectsDdl || !notesDdl) throw new Error('shared entity DDL is incomplete')
  registerEntityFromSql({ entityType: 'Project', createTableSql: projectsDdl })
  registerEntityFromSql({ entityType: 'Note', createTableSql: notesDdl })

  if (isTauri()) {
    registerEntityTransport('Project', tauriTransport('projects'))
    registerEntityTransport('Note', tauriTransport('notes'))
    await invoke<void>('entity_runtime_start', { tenantId })
    return { tenantId, dispose: () => { void invoke<void>('entity_runtime_stop') } }
  }

  const db = await PGlite.create('idb://gen-ui', { relaxedDurability: true })
  await db.exec(schemaSql)
  registerEntityTransport('Project', pgliteTransport(db, 'projects', tenantId))
  registerEntityTransport('Note', pgliteTransport(db, 'notes', tenantId))
  const graph = startLocalFirstGraph({
    storage: await createPGlitePersistenceAdapter(db),
    key: `tenant:${tenantId}`,
    replayPendingActions: true,
  })
  return {
    tenantId,
    dispose: () => {
      graph.dispose()
      void db.close()
    },
  }
}

export async function startEntityRuntime(tenantId: string): Promise<() => void> {
  if (session && session.tenantId !== tenantId) {
    throw new Error(`entity runtime already active for tenant ${session.tenantId}`)
  }
  consumers += 1

  try {
    if (!session) {
      sessionInflight ??= createEntityRuntime(tenantId)
      const pending = sessionInflight
      session = await pending
      if (sessionInflight === pending) sessionInflight = null
    }
  } catch (cause) {
    consumers -= 1
    sessionInflight = null
    throw cause
  }

  const acquired = session
  let released = false
  return () => {
    if (released) return
    released = true
    consumers -= 1
    if (consumers === 0 && session === acquired) {
      acquired.dispose()
      session = null
    }
  }
}
EOF

cat > src/features/entities/hooks/useEntityRuntime.ts << 'EOF'
// TJ-ARCH-MOB-001 compliant
import { useEffect, useState } from 'react'
import { startEntityRuntime } from '../stores/entityRuntime'

export function useEntityRuntime(tenantId: string | null) {
  const [isReady, setIsReady] = useState(false)
  const [error, setError] = useState<string | null>(null)
  useEffect(() => {
    setIsReady(false)
    setError(null)
    if (!tenantId) return undefined
    let active = true
    let dispose: (() => void) | undefined
    void startEntityRuntime(tenantId)
      .then((cleanup) => {
        if (!active) { cleanup(); return }
        dispose = cleanup
        setIsReady(true)
      })
      .catch((cause: unknown) => { if (active) setError(String(cause)) })
    return () => { active = false; dispose?.() }
  }, [tenantId])
  return { isReady, error }
}
EOF

cat > src/features/entities/components/EntityRuntimeBoundary.tsx << 'EOF'
// TJ-ARCH-MOB-001 compliant — component imports the hook only.
import type { ReactNode } from 'react'
import { useEntityRuntime } from '../hooks/useEntityRuntime'

export function EntityRuntimeBoundary({ children }: { children: ReactNode }) {
  const { isReady, error } = useEntityRuntime('local-default')
  if (error) return <div role="alert">Entity runtime failed: {error}</div>
  if (!isReady) return <div aria-live="polite">Starting entity runtime…</div>
  return <>{children}</>
}
EOF

# ═══════════════════════════════════════════════════════════════════════════
# features/memory — memory / graph-RAG panel. Store is the ONLY IPC layer
# (invoke on desktop; the Rust core owns the graph store, never the browser).
# Hooks compose the store; components import hooks only. Hybrid fusion (vector
# recall → graph expansion → BM25 → RRF) lives entirely in Rust gen_ui_db.
# ═══════════════════════════════════════════════════════════════════════════
cat > src/features/memory/stores/memoryStore.ts << 'EOF'
// TJ-ARCH-MOB-001 compliant — store layer (the ONLY place invoke() is called).
import { create } from 'zustand'
import { immer } from 'zustand/middleware/immer'
import { isTauri } from '@tauri-apps/api/core'
import { memoryIngest, memorySearch, type MemoryHit } from '@prometheus-ags/tauri-plugin-gen-ui'

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
        const hits = isTauri()
          ? await memorySearch(query, 8)
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
EOF
ok "src/features/memory/stores/memoryStore.ts"

cat > src/features/memory/hooks/useMemory.ts << 'EOF'
// TJ-ARCH-MOB-001 compliant — hooks compose stores; no invoke() here.
import { useMemoryStore } from '../stores/memoryStore'

export function useMemory() {
  return {
    query: useMemoryStore((s) => s.query),
    hits: useMemoryStore((s) => s.hits),
    isIngesting: useMemoryStore((s) => s.isIngesting),
    isSearching: useMemoryStore((s) => s.isSearching),
    error: useMemoryStore((s) => s.error),
    ingest: useMemoryStore((s) => s.ingest),
    search: useMemoryStore((s) => s.search),
  }
}
EOF
ok "src/features/memory/hooks/useMemory.ts"

cat > src/features/memory/components/MemoryPanel.tsx << 'EOF'
// TJ-ARCH-MOB-001 compliant — component imports the hook only (no store, no invoke).
import { useState } from 'react'
import { useMemory } from '../hooks/useMemory'

export function MemoryPanel() {
  const { hits, query, isIngesting, isSearching, error, ingest, search } = useMemory()
  const [ingestText, setIngestText] = useState('')
  const [searchText, setSearchText] = useState('')

  return (
    <section aria-label="Memory graph-RAG panel">
      <form
        onSubmit={(e) => { e.preventDefault(); if (ingestText.trim()) { void ingest(ingestText.trim()); setIngestText('') } }}
      >
        <label htmlFor="mem-ingest">Ingest</label>
        <input id="mem-ingest" value={ingestText} onChange={(e) => setIngestText(e.target.value)} placeholder="Add a memory…" />
        <button type="submit" disabled={isIngesting}>{isIngesting ? 'Ingesting…' : 'Ingest'}</button>
      </form>

      <form
        onSubmit={(e) => { e.preventDefault(); if (searchText.trim()) void search(searchText.trim()) }}
      >
        <label htmlFor="mem-search">Search</label>
        <input id="mem-search" value={searchText} onChange={(e) => setSearchText(e.target.value)} placeholder="Hybrid graph-RAG search…" />
        <button type="submit" disabled={isSearching}>{isSearching ? 'Searching…' : 'Search'}</button>
      </form>

      {error ? <p role="alert">{error}</p> : null}

      <ol aria-label={`Results for ${query}`}>
        {hits.map((hit) => (
          <li key={hit.id}>
            <strong>{hit.text}</strong>
            <span> · {hit.score.toFixed(3)}</span>
            <p>{hit.kind}</p>
          </li>
        ))}
      </ol>
    </section>
  )
}
EOF
ok "src/features/memory/components/MemoryPanel.tsx"

# ═══════════════════════════════════════════════════════════════════════════
# features/startup — first-run boot flow demo (migrations → seeds → shapes).
# Store owns all invoke() and sequences the boot-order invariant; the hook gates
# rendering; the gate component blocks the app until ready. (analysis §1.8)
# ═══════════════════════════════════════════════════════════════════════════
mkdir -p src/features/startup/{stores,hooks,components}
cat > src/features/startup/stores/startupStore.ts << 'EOF'
// TJ-ARCH-MOB-001 compliant — store layer (the ONLY place invoke() is called).
import { create } from 'zustand'
import { isTauri } from '@tauri-apps/api/core'
import { attachSyncShapes, loadSeeds, runMigrations } from '@prometheus-ags/tauri-plugin-gen-ui'

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
let inflight: Promise<void> | null = null

export const useStartupStore = create<StartupState>((set) => ({
  phase: 'migrations',
  error: null,
  run: () => {
    inflight ??= (async () => {
      try {
        set({ phase: 'migrations', error: null })
        if (isTauri()) await runMigrations()
        set({ phase: 'seeds' })
        if (isTauri()) await loadSeeds()
        set({ phase: 'shapes' })
        if (isTauri()) await attachSyncShapes()
        set({ phase: 'ready' })
      } catch (e) {
        set({ error: String(e) })
      } finally {
        inflight = null
      }
    })()
    return inflight
  },
}))
EOF
ok "src/features/startup/stores/startupStore.ts"

cat > src/features/startup/hooks/useStartup.ts << 'EOF'
// TJ-ARCH-MOB-001 compliant — hook composes the store; no invoke() here.
// The hook is the layer boundary: it reads store state and derives everything
// the component needs (label, progress) so components import ONLY this hook.
import { useEffect } from 'react'
import { useStartupStore, phaseProgress } from '../stores/startupStore'

const PHASE_LABEL: Record<string, string> = {
  migrations: 'Applying migrations',
  seeds: 'Loading seed data',
  shapes: 'Attaching sync shapes',
  ready: 'Ready',
}

export function useStartup() {
  const phase = useStartupStore((s) => s.phase)
  const error = useStartupStore((s) => s.error)
  const run = useStartupStore((s) => s.run)
  useEffect(() => { void run() }, [run])
  return {
    phase,
    error,
    isReady: phase === 'ready',
    label: PHASE_LABEL[phase],
    progress: phaseProgress(phase),
  }
}
EOF
ok "src/features/startup/hooks/useStartup.ts"

cat > src/features/startup/components/StartupGate.tsx << 'EOF'
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
EOF
ok "src/features/startup/components/StartupGate.tsx"

cat > src/features/chat/stores/flintSurfaceStore.ts << 'EOF'
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
EOF

cat > src/features/chat/hooks/useFlintSurface.ts << 'EOF'
// TJ-ARCH-MOB-001 compliant
import { useEffect } from 'react'
import { useFlintSurfaceStore } from '../stores/flintSurfaceStore'

export function useFlintSurface(surfaceId: string) {
  const components = useFlintSurfaceStore((state) => state.surfaces[surfaceId] ?? [])
  const start = useFlintSurfaceStore((state) => state.start)
  useEffect(() => start(), [start])
  return { components }
}
EOF

cat > src/features/chat/components/CoreFlintSurface.tsx << 'EOF'
// TJ-ARCH-MOB-001 compliant
import { registerBaseComponents, resolveFlintComponent, type A2uiComponentSpec } from '@flint/react'
import { useFlintSurface } from '../hooks/useFlintSurface'

registerBaseComponents()

function CoreComponent({ spec }: { spec: A2uiComponentSpec }) {
  const Component = resolveFlintComponent(spec.slug, {})
  if (!Component) return <div role="alert">Unknown A2UI component: {spec.slug}</div>
  return <Component {...spec.props}>{spec.children?.map((child) => <CoreComponent key={child.id} spec={child} />)}</Component>
}

export function CoreFlintSurface({ surfaceId }: { surfaceId: string }) {
  const { components } = useFlintSurface(surfaceId)
  return <section aria-label={`Generated surface ${surfaceId}`}>{components.map((spec) => <CoreComponent key={spec.id} spec={spec} />)}</section>
}
EOF

cat > src/features/chat/hooks/useChat.ts << 'EOF'
// TJ-ARCH-MOB-001 compliant
import { useChatStore } from '../stores/chatStore'

export function useChat() {
  return {
    messages: useChatStore((state) => state.messages),
    isStreaming: useChatStore((state) => state.isStreaming),
    sendMessage: useChatStore((state) => state.sendMessage),
  }
}
EOF

cat > src/features/chat/components/ChatTranscript.tsx << 'EOF'
// TJ-ARCH-MOB-001 compliant
import { ContentBlockView } from '@prometheus-ags/gen-ui-react'
import { useChat } from '../hooks/useChat'

export function ChatTranscript() {
  const { messages } = useChat()
  return <ol aria-live="polite">{messages.map((message) => <li key={message.id}>{message.content.map((block, index) => <ContentBlockView key={`${message.id}:${index}`} block={block} />)}</li>)}</ol>
}
EOF

# ── vite-env.d.ts (declares .css / ?raw / import.meta.env types for tsc) ────
cat > src/vite-env.d.ts << 'EOF'
/// <reference types="vite/client" />
EOF
ok "src/vite-env.d.ts"

# ── main.tsx ───────────────────────────────────────────────────────────────
cat > src/main.tsx << 'EOF'
// TJ-ARCH-MOB-001 compliant
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { AppProviders } from './app/providers'
import { StartupGate } from './features/startup/components/StartupGate'
import { EntityRuntimeBoundary } from './features/entities/components/EntityRuntimeBoundary'
import { useChatStore } from './features/chat/stores/chatStore'
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
EOF
ok "src/main.tsx"

# ── index.css (Tailwind 4) ─────────────────────────────────────────────────
cat > src/index.css << 'EOF'
@import "tailwindcss";

@theme {
  --color-background: #0D0D18;
  --color-surface: #121220;
  --color-ember: #FF6A3D;
  --color-violet: #8B78FF;
  --color-text-primary: #F2F2FF;
  --color-text-secondary: #9898C0;
  --font-sans: 'Inter', sans-serif;
  --font-display: 'Space Grotesk', sans-serif;
  --font-mono: 'JetBrains Mono', monospace;
}

:root { color-scheme: dark; }
body { background: var(--color-background); color: var(--color-text-primary); font-family: var(--font-sans); }
EOF
ok "src/index.css"

# ── Vitest config + boundary tests ─────────────────────────────────────────
# Features-first testing (references/tauri/testing.md): a few behavior tests at
# the public boundary. The ONLY thing faked is the Tauri IPC edge (@tauri-apps/
# api/core) — a real IO boundary. Stores/hooks/components run for real.
step "Writing Vitest config + boundary tests"
cat > vitest.config.ts << 'EOF'
// TJ-ARCH-MOB-001 compliant
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  resolve: { alias: { '@': new URL('./src', import.meta.url).pathname } },
  test: {
    environment: 'jsdom',
    globals: true,
    restoreMocks: true,
    server: { deps: { inline: [/@prometheus-ags\//] } },
  },
})
EOF

mkdir -p src/features/memory/__tests__ src/features/startup/__tests__
cat > src/features/memory/__tests__/memoryStore.test.ts << 'EOF'
// TJ-ARCH-MOB-001 compliant
import { beforeEach, describe, expect, it, vi } from 'vitest'

// Fake ONLY the Tauri IPC edge — a real IO boundary. The store logic is real.
const invoke = vi.fn()
vi.mock('@tauri-apps/api/core', () => ({
  invoke: (...args: unknown[]) => invoke(...args),
  isTauri: () => true,
}))

import { useMemoryStore, type MemoryHit } from '../stores/memoryStore'

const initial = useMemoryStore.getState()
beforeEach(() => {
  useMemoryStore.setState(initial, true)
  invoke.mockReset()
})

describe('memoryStore', () => {
  it('folds ranked hits from memory_search into state', async () => {
    const hits: MemoryHit[] = [
      { id: 'entity:1', text: 'Alpha', kind: 'note', score: 0.91 },
      { id: 'entity:2', text: 'Beta', kind: 'note', score: 0.42 },
    ]
    invoke.mockResolvedValueOnce(hits)

    await useMemoryStore.getState().search('alpha')

    const s = useMemoryStore.getState()
    expect(invoke).toHaveBeenCalledWith('plugin:gen-ui|memory_search', {
      query: 'alpha',
      k: 8,
      mode: undefined,
    })
    expect(s.query).toBe('alpha')
    expect(s.hits).toHaveLength(2)
    expect(s.hits[0].score).toBeGreaterThan(s.hits[1].score)
    expect(s.isSearching).toBe(false)
  })

  it('surfaces a Rust domain error instead of throwing or retrying', async () => {
    invoke.mockRejectedValueOnce('surreal: index not ready')

    await useMemoryStore.getState().search('alpha')

    const s = useMemoryStore.getState()
    expect(s.error).toContain('index not ready')
    expect(s.hits).toEqual([])
    expect(s.isSearching).toBe(false)
    expect(invoke).toHaveBeenCalledTimes(1) // terminal — no silent retry
  })
})
EOF

cat > src/features/startup/__tests__/startupStore.test.ts << 'EOF'
// TJ-ARCH-MOB-001 compliant
import { beforeEach, describe, expect, it, vi } from 'vitest'

const invoke = vi.fn()
vi.mock('@tauri-apps/api/core', () => ({
  invoke: (...args: unknown[]) => invoke(...args),
  isTauri: () => true,
}))

import { useStartupStore, PHASE_ORDER, phaseProgress } from '../stores/startupStore'

const initial = useStartupStore.getState()
beforeEach(() => {
  useStartupStore.setState(initial, true)
  invoke.mockReset()
})

describe('startupStore', () => {
  it('runs the boot sequence in order: migrations → seeds → shapes → ready', async () => {
    invoke.mockResolvedValue(undefined)

    await useStartupStore.getState().run()

    expect(useStartupStore.getState().phase).toBe('ready')
    // The boot-order invariant: shapes come AFTER migrations and seeds.
    expect(invoke.mock.calls.map((c) => c[0])).toEqual([
      'plugin:gen-ui|run_migrations',
      'plugin:gen-ui|load_seeds',
      'plugin:gen-ui|attach_sync_shapes',
    ])
  })

  it('halts on a failed migration without attaching shapes', async () => {
    invoke.mockRejectedValueOnce('migration 003 failed')

    await useStartupStore.getState().run()

    const s = useStartupStore.getState()
    expect(s.error).toContain('migration 003 failed')
    expect(s.phase).not.toBe('ready')
    // Shapes must never attach when migrations fail (they'd hit unknown columns).
    expect(invoke.mock.calls.map((c) => c[0])).not.toContain('plugin:gen-ui|attach_sync_shapes')
  })

  it('exposes monotonic progress across the phase order', () => {
    const progresses = PHASE_ORDER.map(phaseProgress)
    for (let i = 1; i < progresses.length; i++) {
      expect(progresses[i]).toBeGreaterThan(progresses[i - 1])
    }
    expect(phaseProgress('ready')).toBe(1)
  })
})
EOF
ok "Vitest + 5 boundary tests (memory fold · memory error · boot order · boot halt · progress)"

# ── src-tauri placeholder ──────────────────────────────────────────────────
step "Creating Tauri source skeleton"
mkdir -p src-tauri/src src-tauri/.cargo
cat > src-tauri/.cargo/config.toml << 'EOF'
# TJ-ARCH-MOB-001 compliant

[env]
# Native inference/audio dependencies use std::filesystem (macOS 10.15+).
# Cargo owns native dependency compilation; bundle metadata alone is too late.
MACOSX_DEPLOYMENT_TARGET = { value = "10.15", force = true }
EOF

cat > src-tauri/rust-toolchain.toml << 'EOF'
[toolchain]
channel = "1.96"
components = ["rustfmt", "clippy"]
EOF

cat > src-tauri/Cargo.toml << EOF
[package]
name = "${APP_NAME}"
version = "0.1.0"
edition = "2021"
rust-version = "1.96"

[lib]
name = "${APP_NAME//-/_}"
crate-type = ["staticlib", "cdylib", "rlib"]

[build-dependencies]
tauri-build = { version = "2", features = [] }

[dependencies]
tauri = { version = "2", features = ["devtools"] }
tauri-plugin-shell = "2"
tauri-plugin-store = "2"
tauri-plugin-os = "2"
serde = { version = "1", features = ["derive"] }
serde_json = "1"
# Add path to shared gen_ui_core:
# gen_ui_core = { path = "../../rust/gen_ui_core" }
EOF

cat > src-tauri/tauri.conf.json << EOF
{
  "productName": "${APP_NAME}",
  "version": "1.0.0",
  "identifier": "ai.prometheusags.${APP_NAME}",
  "build": {
    "frontendDist": "../dist",
    "devUrl": "http://localhost:1420",
    "beforeDevCommand": "pnpm dev",
    "beforeBuildCommand": "pnpm build"
  },
  "app": {
    "withGlobalTauri": true,
    "windows": [
      {
        "title": "${APP_NAME}",
        "width": 1280,
        "height": 820,
        "minWidth": 800,
        "minHeight": 600,
        "decorations": true,
        "transparent": false
      }
    ],
    "security": { "csp": null }
  },
  "bundle": {
    "active": true,
    "targets": "all",
    "macOS": { "minimumSystemVersion": "10.15" },
    "icon": ["icons/32x32.png", "icons/128x128.png", "icons/128x128@2x.png", "icons/icon.icns", "icons/icon.ico"]
  }
}
EOF

cat > src-tauri/build.rs << 'RSEOF'
fn main() {
    tauri_build::build()
}
RSEOF

cat > src-tauri/src/commands.rs << 'RSEOF'
// TJ-ARCH-MOB-001 compliant
// Tauri command surface. Stub bodies today — wire these into gen_ui_core once
// the shared Rust crate is linked as a dependency of this crate (uncomment the
// path dep in Cargo.toml). Signatures should match the frontend's invoke()
// contract (src/features/*/stores/*.ts) so wiring a real backend never changes
// the frontend call sites. Registering stubs now (rather than leaving the
// invoke_handler commented out) lets the app boot end-to-end before any
// backend logic lands — an unregistered command the frontend calls
// unconditionally at startup is a silent "Startup failed" trap otherwise.

#[tauri::command]
pub async fn run_migrations() -> Result<(), String> {
    Ok(())
}

#[tauri::command]
pub async fn load_seeds() -> Result<(), String> {
    Ok(())
}

#[tauri::command]
pub async fn attach_sync_shapes() -> Result<(), String> {
    Ok(())
}
RSEOF

cat > src-tauri/src/lib.rs << 'RSEOF'
// TJ-ARCH-MOB-001 compliant
// Tauri application entry point
// gen_ui_core commands are registered here

mod commands;

use tauri::menu::{AboutMetadata, Menu, MenuItem, PredefinedMenuItem, Submenu};
use tauri::Manager;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_store::Builder::new().build())
        .plugin(tauri_plugin_os::init())
        // .manage(AppState::new())          // Uncomment when gen_ui_core is wired
        .invoke_handler(tauri::generate_handler![
            commands::run_migrations,
            commands::load_seeds,
            commands::attach_sync_shapes,
            // Add entity/memory/chat commands here as gen_ui_core wires them —
            // see gen_ui_ffi's api/chat.rs + api/entity.rs for their signatures.
        ])
        .setup(|app| {
            let quit = MenuItem::with_id(app, "quit", "Quit", true, Some("CmdOrCtrl+Q"))?;
            let file_menu = Submenu::with_items(app, "File", true, &[&quit])?;

            // Native View menu with a Toggle Developer Tools item — the only
            // discoverable way to reach devtools (console/elements/network) on a
            // packaged build; right-click "Inspect Element" is undiscoverable and
            // absent entirely in release builds without this menu wiring.
            // Toggle Developer Tools is deliberately the LAST item in View.
            let toggle_devtools = MenuItem::with_id(
                app,
                "toggle_devtools",
                "Toggle Developer Tools",
                true,
                Some("CmdOrCtrl+Alt+I"),
            )?;
            let view_menu = Submenu::with_items(
                app,
                "View",
                true,
                &[
                    &PredefinedMenuItem::fullscreen(app, None)?,
                    &PredefinedMenuItem::separator(app)?,
                    &toggle_devtools,
                ],
            )?;

            let about = PredefinedMenuItem::about(app, None, Some(AboutMetadata::default()))?;
            let help_menu = Submenu::with_items(app, "Help", true, &[&about])?;

            let menu = Menu::with_items(app, &[&file_menu, &view_menu, &help_menu])?;
            app.set_menu(menu)?;

            app.on_menu_event(move |app_handle, event| match event.id().as_ref() {
                "toggle_devtools" => {
                    if let Some(window) = app_handle.get_webview_window("main") {
                        if window.is_devtools_open() {
                            window.close_devtools();
                        } else {
                            window.open_devtools();
                        }
                    }
                }
                "quit" => app_handle.exit(0),
                _ => {}
            });

            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
RSEOF

cat > src-tauri/src/main.rs << EOF
// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]
fn main() { ${APP_NAME//-/_}::run() }
EOF
ok "src-tauri/"

# ── App icons ────────────────────────────────────────────────────────────────
# tauri.conf.json's bundle.icon list requires src-tauri/icons/* to exist before the
# app can even `cargo check` (tauri::generate_context! reads them at compile time via
# a build-script-emitted OUT_DIR). Generate a placeholder square PNG with the stdlib
# zlib module (no ImageMagick/sips dependency) and run the Tauri CLI's own icon
# generator to produce the full macOS/Windows/iOS/Android set.
step "Generating placeholder app icons"
python3 - << 'PYEOF'
import struct, zlib
W = H = 1024
r, g, b, a = 0x4F, 0x46, 0xE5, 0xFF  # placeholder brand square (indigo)
def chunk(t, d):
    c = t + d
    return struct.pack('>I', len(d)) + c + struct.pack('>I', zlib.crc32(c))
row = bytes([r, g, b, a]) * W
raw = (b'\x00' + row) * H
png = b'\x89PNG\r\n\x1a\n'
png += chunk(b'IHDR', struct.pack('>IIBBBBB', W, H, 8, 6, 0, 0, 0))
png += chunk(b'IDAT', zlib.compress(raw, 9))
png += chunk(b'IEND', b'')
with open('app-icon.png', 'wb') as f:
    f.write(png)
PYEOF
npx tauri icon app-icon.png > /dev/null 2>&1
ok "src-tauri/icons/ (placeholder — replace app-icon.png + rerun \`tauri icon\` with real branding)"

# ── Capabilities (Tauri v2 ACL) ──────────────────────────────────────────────
# Tauri v2's permission system denies every IPC/event call by default; without an
# explicit capabilities file the frontend's own `event.listen()` throws at runtime
# ("event.listen not allowed"). The window has no explicit "label" in tauri.conf.json
# so it uses Tauri's default label "main".
mkdir -p src-tauri/capabilities
cat > src-tauri/capabilities/default.json << 'EOF'
{
  "$schema": "../gen/schemas/desktop-schema.json",
  "identifier": "default",
  "description": "Capability for the main window",
  "windows": ["main"],
  "permissions": [
    "core:default",
    "core:window:allow-close",
    "core:window:allow-minimize",
    "core:window:allow-toggle-maximize",
    "core:window:allow-start-dragging",
    "shell:default",
    "store:default",
    "os:default"
  ]
}
EOF
ok "src-tauri/capabilities/default.json"

step "Installing dependencies"
if [[ "${SKIP_INSTALL:-0}" == "1" ]]; then
  ok "dependency installation skipped (SKIP_INSTALL=1)"
elif command -v pnpm &>/dev/null; then
  # pnpm's newer default exits non-zero when it withholds a dependency's postinstall
  # script for supply-chain safety (ERR_PNPM_IGNORED_BUILDS) — install itself still
  # succeeds (node_modules is populated), so this is advisory, not fatal, for a
  # non-interactive scaffold. Don't let it kill the script under set -e.
  pnpm install --frozen-lockfile 2>/dev/null || pnpm install || true
  ok "pnpm install (review 'pnpm approve-builds' if native postinstall steps are needed)"
else
  npm install
  ok "npm install"
fi

step "Initializing shadcn/ui"
echo "Run after install: npx shadcn@latest init (select: Tailwind v4, CSS variables, dark)"
ok "shadcn/ui init instruction noted"

echo ""
echo -e "${GREEN}✅ Tauri app scaffolded in ${OUT}/${NC}"
echo ""
echo "  Next steps:"
echo "  1. cd $OUT && pnpm tauri dev"
echo "  2. Wire gen_ui_core: uncomment path dep in src-tauri/Cargo.toml"
echo "  3. npx shadcn@latest init"
echo "  4. Add auth: bash scripts/add-auth.sh supabase|kratos"
