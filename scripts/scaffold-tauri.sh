#!/usr/bin/env bash
# scripts/scaffold-tauri.sh
# Scaffold a Tauri 2.x + React 19 + Zustand 5 + TanStack desktop app
# Usage: bash scripts/scaffold-tauri.sh <output-dir> <app-name>

set -euo pipefail

OUT="${1:-desktop}"
APP_NAME="${2:-my-desktop-app}"

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
    "tailwindcss":            "^4.0.0",
    "@tailwindcss/vite":      "^4.0.0",
    "lucide-react":           "^0.400.0",
    "class-variance-authority": "^0.7.0",
    "clsx":                   "^2.1.0",
    "tailwind-merge":         "^2.0.0",
    "react-markdown":         "^9.0.0",
    "@codemirror/view":       "^6.0.0",
    "@codemirror/lang-javascript": "^6.0.0",
    "@sandpack/react":        "^2.0.0",
    "framer-motion":          "^11.0.0",
    "@assistant-ui/react":    "^0.8.0",
    "@supabase/supabase-js":  "^2.46.0"
  },
  "devDependencies": {
    "@tauri-apps/cli":        "^2.10.3",
    "vite":                   "^7.0.0",
    "@vitejs/plugin-react":   "^4.0.0",
    "typescript":             "^5.4.0",
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
mkdir -p src/{app,core/{types,errors,utils,theme},shared/{components/ui,hooks,stores},bridge/{a2ui,agui},features/{chat/{api,stores,queries,hooks,components},auth/{api,stores,queries,hooks,components},memory/{api,stores,queries,hooks,components},settings/{stores,components}}}
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
import { v4 as uuid } from 'uuid'

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
        const userMsg: Message = { id: uuid(), role: 'user', content: [{ type: 'text', text, isStreaming: false }], timestamp: new Date().toISOString() }
        const assistantId = uuid()
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
          const { applyA2uiEvent } = require('@/bridge/a2ui/driver')
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
export type MemoryType = 'episodic' | 'semantic' | 'working' | 'procedural'
export type ToolStatus = 'pending' | 'running' | 'success' | 'error' | 'cancelled'
export type SkillStatus = 'activating' | 'active' | 'complete' | 'failed'
export type ArtifactType = 'code' | 'ui' | 'data' | 'document' | 'image' | 'custom'

export type ContentBlock =
  | { type: 'text';       text: string; isStreaming: boolean }
  | { type: 'thinking';   thinking: string; isStreaming: boolean; defaultExpanded?: boolean }
  | { type: 'code';       code: string; language: string; filename?: string }
  | { type: 'citation';   text: string; sources: CitationSource[] }
  | { type: 'memory';     content: string; memoryType: MemoryType; key: string; isNew: boolean; namespace?: string }
  | { type: 'toolUse';    toolUseId: string; toolName: string; input: Record<string, unknown>; status: ToolStatus; serverName?: string }
  | { type: 'toolResult'; toolUseId: string; toolName: string; content: unknown; isError: boolean; executionTime?: number }
  | { type: 'skill';      skillId: string; skillName: string; parameters: Record<string, unknown>; status: SkillStatus; outputSummary?: string; toolCallIds?: string[] }
  | { type: 'artifact';   artifactId: string; artifactType: ArtifactType; title: string; contentJson: string; language?: string }
  | { type: 'image';      source: string; altText?: string }
  | { type: 'divider' }

export interface CitationSource { id: string; title: string; url?: string; excerpt?: string; score?: number }
export interface MessageUsage { inputTokens?: number; outputTokens?: number; cacheReadTokens?: number; thinkingTokens?: number }
export interface Message { id: string; role: 'user' | 'assistant' | 'system'; content: ContentBlock[]; timestamp: string; isStreaming?: boolean; usage?: MessageUsage }
EOF
ok "src/bridge/a2ui/types.ts"

# ── main.tsx ───────────────────────────────────────────────────────────────
cat > src/main.tsx << 'EOF'
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
if command -v pnpm &>/dev/null; then
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
