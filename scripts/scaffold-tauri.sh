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
    "format":      "prettier --write src"
  },
  "dependencies": {
    "react":                  "^19.0.0",
    "react-dom":              "^19.0.0",
    "@tauri-apps/api":        "^2.0.0",
    "@tauri-apps/plugin-shell": "^2.0.0",
    "@tauri-apps/plugin-store": "^2.0.0",
    "zustand":                "^5.0.0",
    "immer":                  "^10.0.0",
    "@tanstack/react-query":  "^5.0.0",
    "@tanstack/react-router": "^1.0.0",
    "@tanstack/react-table":  "^8.0.0",
    "@tanstack/react-virtual": "^3.0.0",
    "@electric-sql/pglite":   "0.5.4",
    "@electric-sql/pglite-sync": "^0.4.0",
    "@prometheus-ags/prometheus-entity-management": "git+https://github.com/Prometheus-AGS/prometheus-entity-management.git#74d72c7a3394a09c246d08aba833b903666a37d1&path:packages/entity-graph-react",
    "@prometheus-ags/gen-ui-react": "file:../packages/gen-ui-react",
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
    "typescript":             "^5.9.0",
    "@types/react":           "^19.0.0",
    "@types/react-dom":       "^19.0.0",
    "@typescript-eslint/eslint-plugin": "^8.0.0",
    "@typescript-eslint/parser": "^8.0.0",
    "eslint":                 "^9.0.0",
    "eslint-plugin-react-hooks": "^5.0.0",
    "prettier":               "^3.0.0"
  }
}
PKGEOF
ok "package.json"

cat > index.html << EOF
<!doctype html>
<html lang="en">
  <head><meta charset="UTF-8" /><meta name="viewport" content="width=device-width, initial-scale=1.0" /><title>${APP_NAME}</title></head>
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
    "baseUrl": ".",
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
  build: { target: process.env.TAURI_ENV_PLATFORM === 'windows' ? 'chrome105' : 'safari13', minify: !process.env.TAURI_ENV_DEBUG ? 'esbuild' : false, sourcemap: !!process.env.TAURI_ENV_DEBUG },
})
EOF
ok "vite.config.ts"

# ── Feature-based src structure ────────────────────────────────────────────
step "Creating feature-based clean architecture"
mkdir -p src/{app,core/{types,errors,utils,theme},shared/{components/ui,hooks,stores},bridge/{a2ui,agui},features/{chat/{api,stores,queries,hooks,components},auth/{api,stores,queries,hooks,components},entities/{api,stores,queries,hooks,components},memory/{api,stores,queries,hooks,components},settings/{stores,components}}}
ok "src/ directory structure"

# ── App providers ──────────────────────────────────────────────────────────
cat > src/app/providers.tsx << 'EOF'
// TJ-ARCH-MOB-001 compliant
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { RouterProvider } from '@tanstack/react-router'
import { router } from './router'
import { useAuthStore } from '@/features/auth/stores/authStore'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: { staleTime: 30_000, retry: 1 },
    mutations: { retry: 0 },
  },
})

export function AppProviders() {
  const auth = useAuthStore()
  return (
    <QueryClientProvider client={queryClient}>
      <RouterProvider router={router} context={{ auth, queryClient }} />
    </QueryClientProvider>
  )
}
EOF
ok "src/app/providers.tsx"

# ── Router stub ────────────────────────────────────────────────────────────
cat > src/app/router.tsx << 'EOF'
// TJ-ARCH-MOB-001 compliant
import { createRouter, createRoute, createRootRouteWithContext, redirect } from '@tanstack/react-router'
import type { QueryClient } from '@tanstack/react-query'
import type { AuthState } from '@/features/auth/stores/authStore'

interface RouterContext { auth: AuthState; queryClient: QueryClient }

const rootRoute = createRootRouteWithContext<RouterContext>()({
  component: () => <div className="h-screen bg-background">outlet placeholder</div>,
})

const protectedRoute = createRoute({
  getParentRoute: () => rootRoute,
  id: 'protected',
  beforeLoad: ({ context }) => {
    if (!context.auth.isAuthenticated) throw redirect({ to: '/login' })
  },
})

export const router = createRouter({
  routeTree: rootRoute.addChildren([protectedRoute]),
  context: { auth: undefined!, queryClient: undefined! },
})

declare module '@tanstack/react-router' {
  interface Register { router: typeof router }
}
EOF
ok "src/app/router.tsx"

# ── Auth store stub ────────────────────────────────────────────────────────
cat > src/features/auth/stores/authStore.ts << 'EOF'
// TJ-ARCH-MOB-001 compliant — store layer (called only by hooks, never by components)
import { create } from 'zustand'
import { subscribeWithSelector, persist } from 'zustand/middleware'

export interface AuthState {
  user: { id: string; email: string } | null
  session: unknown | null
  isAuthenticated: boolean
}

interface AuthActions {
  signIn: (email: string, password: string) => Promise<void>
  signOut: () => Promise<void>
}

export const useAuthStore = create<AuthState & AuthActions>()(
  subscribeWithSelector(
    persist(
      (set) => ({
        user: null,
        session: null,
        isAuthenticated: false,
        signIn: async (email, _password) => {
          // TODO: implement via Supabase or Kratos
          // Store calls invoke() or supabase SDK here — never a component
          set({ user: { id: '1', email }, isAuthenticated: true })
        },
        signOut: async () => {
          set({ user: null, session: null, isAuthenticated: false })
        },
      }),
      { name: 'auth-state' }
    )
  )
)
EOF
ok "src/features/auth/stores/authStore.ts"

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
  type LocalFirstGraphRuntime,
} from '@prometheus-ags/prometheus-entity-management'
import schemaSql from '../schema.sql?raw'

export interface EntityRow { id: string; tenant_id: string; [key: string]: unknown }
let runtime: LocalFirstGraphRuntime | null = null

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

export async function startEntityRuntime(tenantId: string): Promise<() => void> {
  const [projectsDdl, notesDdl] = schemaSql.split(';').filter((sql) => sql.includes('CREATE TABLE'))
  if (!projectsDdl || !notesDdl) throw new Error('shared entity DDL is incomplete')
  registerEntityFromSql({ entityType: 'Project', createTableSql: projectsDdl })
  registerEntityFromSql({ entityType: 'Note', createTableSql: notesDdl })

  if (isTauri()) {
    registerEntityTransport('Project', tauriTransport('projects'))
    registerEntityTransport('Note', tauriTransport('notes'))
    await invoke<void>('entity_runtime_start', { tenantId })
    return () => { void invoke<void>('entity_runtime_stop') }
  }

  const db = await PGlite.create('idb://gen-ui', { relaxedDurability: true })
  await db.exec(schemaSql)
  registerEntityTransport('Project', pgliteTransport(db, 'projects', tenantId))
  registerEntityTransport('Note', pgliteTransport(db, 'notes', tenantId))
  runtime = startLocalFirstGraph({
    storage: await createPGlitePersistenceAdapter(db),
    key: `tenant:${tenantId}`,
    replayPendingActions: true,
  })
  return () => { runtime?.dispose(); runtime = null; void db.close() }
}
EOF

cat > src/features/entities/hooks/useEntityRuntime.ts << 'EOF'
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
EOF

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
  const Component = resolveFlintComponent(spec.slug)
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

# ── main.tsx ───────────────────────────────────────────────────────────────
cat > src/main.tsx << 'EOF'
// TJ-ARCH-MOB-001 compliant
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { AppProviders } from './app/providers'
import { useChatStore } from './features/chat/stores/chatStore'
import './index.css'

// Initialize Rust event listeners (store-level, not component-level)
const cleanup = useChatStore.getState().initListeners()
window.addEventListener('beforeunload', cleanup)

createRoot(document.getElementById('root')!).render(
  <StrictMode><AppProviders /></StrictMode>
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

# ── src-tauri placeholder ──────────────────────────────────────────────────
step "Creating Tauri source skeleton"
mkdir -p src-tauri/src
cat > src-tauri/Cargo.toml << EOF
[package]
name = "${APP_NAME}"
version = "0.1.0"
edition = "2021"

[lib]
name = "${APP_NAME//-/_}"
crate-type = ["staticlib", "cdylib"]

[dependencies]
tauri = { version = "2", features = [] }
tauri-plugin-shell = "2"
tauri-plugin-store = "2"
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
    "icon": ["icons/32x32.png", "icons/128x128.png", "icons/128x128@2x.png", "icons/icon.icns", "icons/icon.ico"]
  }
}
EOF

cat > src-tauri/src/lib.rs << 'RSEOF'
// TJ-ARCH-MOB-001 compliant
// Tauri application entry point
// gen_ui_core commands are registered here

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_store::Builder::new().build())
        // .manage(AppState::new())          // Uncomment when gen_ui_core is wired
        // .invoke_handler(tauri::generate_handler![  // Register commands
        //     commands::stream_agent_a2ui,
        //     commands::memory_write,
        //     commands::memory_read,
        //     commands::mcp_call_tool,
        // ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
RSEOF

cat > src-tauri/src/main.rs << 'EOF'
// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]
fn main() { app_lib::run() }
EOF
ok "src-tauri/"

step "Installing dependencies"
if [[ "${SKIP_INSTALL:-0}" == "1" ]]; then
  ok "dependency installation skipped (SKIP_INSTALL=1)"
elif command -v pnpm &>/dev/null; then
  pnpm install --frozen-lockfile 2>/dev/null || pnpm install
  ok "pnpm install"
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
