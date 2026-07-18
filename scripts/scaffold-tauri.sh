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
    "loro-crdt":              "^1.13.6",
    "@tanstack/react-router": "^1.0.0",
    "@tanstack/react-table":  "^8.0.0",
    "@tanstack/react-virtual": "^3.0.0",
    "@electric-sql/pglite":   "0.5.4",
    "@electric-sql/pglite-pgvector": "0.0.5",
    "@prometheus-ags/prometheus-entity-management": "3.0.0-alpha.0",
    "@prometheus-ags/gen-ui-react": "file:../packages/gen-ui-react",
    "@prometheus-ags/tauri-plugin-gen-ui": "file:../rust/crates/tauri-plugin-gen-ui/guest-js",
    "tailwindcss":            "^4.0.0",
    "tw-animate-css":         "^1.4.0",
    "@tailwindcss/vite":      "^4.0.0",
    "lucide-react":           "^0.400.0",
    "class-variance-authority": "^0.7.0",
    "clsx":                   "^2.1.0",
    "tailwind-merge":         "^2.0.0",
    "react-markdown":         "^9.0.0",
    "@assistant-ui/react-markdown": "^0.14.6",
    "@codemirror/view":       "^6.0.0",
    "@codemirror/lang-javascript": "^6.0.0",
    "@codesandbox/sandpack-react": "^2.20.0",
    "framer-motion":          "^11.0.0",
    "@assistant-ui/react":    "^0.14.27",
    "@base-ui/react":         "^1.6.0",
    "@mlc-ai/web-llm":        "0.2.84",
    "remark-gfm":             "^4.0.1",
    "mermaid":                "^11.16.0",
    "dompurify":              "^3.4.0",
    "shadcn":                 "^4.13.0"
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

# pnpm 11 blocks dependency lifecycle scripts unless the project explicitly
# approves them. Vite requires esbuild's platform binary; es5-ext is also a
# current transitive installer. Keep the allowlist narrow and tracked so a
# fresh scaffold installs non-interactively without suppressing failures.
cat > pnpm-workspace.yaml << 'EOF'
allowBuilds:
  es5-ext: true
  esbuild: true
EOF
ok "pnpm-workspace.yaml (approved build scripts)"

cat > components.json << 'EOF'
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "base-nova",
  "rsc": false,
  "tsx": true,
  "tailwind": { "config": "", "css": "src/index.css", "baseColor": "neutral", "cssVariables": true, "prefix": "" },
  "iconLibrary": "lucide",
  "aliases": { "components": "@/components", "utils": "@/lib/utils", "ui": "@/components/ui", "lib": "@/lib", "hooks": "@/hooks" },
  "registries": { "@assistant-ui": "https://r.assistant-ui.com/{name}.json" }
}
EOF
ok "components.json (Shadcn + Assistant UI registries)"

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
mkdir -p src/{app,core/{types,errors,utils,theme},shared/{components/ui,hooks,stores},bridge/{a2ui,agui},features/{chat/{api,stores,entities,hooks,components},entities/{api,stores,entities,hooks,components},memory/{api,stores,entities,hooks,components},settings/{stores,components}}}
ok "src/ directory structure"

mkdir -p src/lib
cat > src/lib/utils.ts << 'EOF'
// TJ-ARCH-MOB-001 compliant
import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
EOF
ok "src/lib/utils.ts (Shadcn class composition)"

# ── App providers ──────────────────────────────────────────────────────────
cat > src/app/providers.tsx << 'EOF'
// TJ-ARCH-MOB-001 compliant
import { RouterProvider } from '@tanstack/react-router'
import { router } from './router'

export function AppProviders() {
  return <RouterProvider router={router} />
}
EOF
ok "src/app/providers.tsx"

# ── Router stub ────────────────────────────────────────────────────────────
cat > src/app/router.tsx << 'EOF'
// TJ-ARCH-MOB-001 compliant
import { createRouter, createRootRoute } from '@tanstack/react-router'
import { ChatScreen } from '@/features/chat/components/ChatScreen'

const rootRoute = createRootRoute({
  component: ChatScreen,
})

export const router = createRouter({
  routeTree: rootRoute,
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
import { chatSend, onChatEvent } from '@prometheus-ags/tauri-plugin-gen-ui'
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
    immer((set) => ({
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
        // Typed guest binding owns invoke(); components and hooks never do.
        await chatSend('default', text).catch(console.error)
      },

      initListeners: () => {
        // Wire A2UI events from Rust to store
        const unlistenPromise = onChatEvent((payload: unknown) => {
          const store = useChatStore.getState()
          applyA2uiEvent(payload as never, store.streamBlock, store.finalizeMessage)
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
CREATE TABLE IF NOT EXISTS chat_conversations (
  id uuid PRIMARY KEY,
  tenant_id text NOT NULL,
  title text NOT NULL,
  messages jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- C-123 client-RAG vector surface (384-dim standard, references/sync/client-rag.md).
-- Messages live as JSONB inside chat_conversations until the C-104+ entity-view
-- normalization; message_embeddings carries the per-message vector surface until
-- then. agent_memory mirrors the Rust-side DDL exactly.
CREATE TABLE IF NOT EXISTS message_embeddings (
  id text PRIMARY KEY,
  conversation_id uuid NOT NULL,
  tenant_id text NOT NULL,
  content text NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  embedding vector(384),
  embedded_at timestamptz
);
CREATE INDEX IF NOT EXISTS message_embeddings_hnsw
  ON message_embeddings USING hnsw (embedding vector_cosine_ops);
CREATE TABLE IF NOT EXISTS agent_memory (
  id text PRIMARY KEY,
  content text NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  embedding vector(384),
  embedded_at timestamptz
);
CREATE INDEX IF NOT EXISTS agent_memory_embedding_hnsw
  ON agent_memory USING hnsw (embedding vector_cosine_ops);
EOF

cat > src/features/entities/stores/entityRuntime.ts << 'EOF'
// TJ-ARCH-MOB-001 compliant — all Tauri IPC lives in this store module.
import { invoke, isTauri } from '@tauri-apps/api/core'
import { PGlite } from '@electric-sql/pglite'
import { vector } from '@electric-sql/pglite-pgvector'
import {
  createPGlitePersistenceAdapter,
  registerEntityFromSql,
  registerEntityTransport,
  startLocalFirstGraph,
  useGraphStore,
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
let browserDb: PGlite | null = null

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
  const [projectsDdl, notesDdl, conversationsDdl] = schemaSql.split(';').filter((sql) => sql.includes('CREATE TABLE'))
  if (!projectsDdl || !notesDdl || !conversationsDdl) throw new Error('shared entity DDL is incomplete')
  registerEntityFromSql({ entityType: 'Project', createTableSql: projectsDdl })
  registerEntityFromSql({ entityType: 'Note', createTableSql: notesDdl })
  registerEntityFromSql({ entityType: 'Conversation', createTableSql: conversationsDdl })

  if (isTauri()) {
    registerEntityTransport('Project', tauriTransport('projects'))
    registerEntityTransport('Note', tauriTransport('notes'))
    registerEntityTransport('Conversation', tauriTransport('conversations'))
    await invoke<void>('entity_runtime_start', { tenantId })
    return { tenantId, dispose: () => { void invoke<void>('entity_runtime_stop') } }
  }

  const db = await PGlite.create('idb://gen-ui', {
    relaxedDurability: true,
    // C-123: pgvector powers the client-RAG vector surface (384-dim standard).
    extensions: { vector },
  })
  browserDb = db
  await db.exec('CREATE EXTENSION IF NOT EXISTS vector')
  await db.exec(schemaSql)
  registerEntityTransport('Project', pgliteTransport(db, 'projects', tenantId))
  registerEntityTransport('Note', pgliteTransport(db, 'notes', tenantId))
  registerEntityTransport('Conversation', pgliteTransport(db, 'chat_conversations', tenantId))
  const graph = startLocalFirstGraph({
    storage: await createPGlitePersistenceAdapter(db),
    key: `tenant:${tenantId}`,
    replayPendingActions: true,
  })
  return {
    tenantId,
    dispose: () => {
      graph.dispose()
      browserDb = null
      void db.close()
    },
  }
}

export interface ConversationRecord extends Record<string, unknown> {
  id: string
  tenant_id: string
  title: string
  messages: unknown[]
  created_at: string
  updated_at: string
}

const CONVERSATION_TYPE = 'Conversation'

function normalizeConversation(row: ConversationRecord): void {
  useGraphStore.getState().upsertEntity(CONVERSATION_TYPE, row.id, row)
}

export async function listConversationRecords(tenantId: string): Promise<ConversationRecord[]> {
  const rows = isTauri()
    ? await invoke<ConversationRecord[]>('entity_list', { view: { entityType: 'conversations', filters: [], sorts: [] } })
    : (await browserDb!.query<ConversationRecord>(
        'SELECT * FROM chat_conversations WHERE tenant_id = $1 ORDER BY updated_at DESC', [tenantId],
      )).rows
  rows.forEach(normalizeConversation)
  return rows
}

export async function saveConversationRecord(row: ConversationRecord): Promise<void> {
  normalizeConversation(row)
  if (isTauri()) {
    await invoke('entity_upsert', { record: { id: row.id, entityType: 'conversations', dataJson: JSON.stringify(row) } })
    return
  }
  if (!browserDb) throw new Error('PGlite conversation store is not ready')
  await browserDb.query(
    `INSERT INTO chat_conversations (id, tenant_id, title, messages, created_at, updated_at)
     VALUES ($1, $2, $3, $4::jsonb, $5, $6)
     ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title, messages = EXCLUDED.messages, updated_at = EXCLUDED.updated_at`,
    [row.id, row.tenant_id, row.title, JSON.stringify(row.messages), row.created_at, row.updated_at],
  )
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
# features/vault — local-class Loro CRDT vault + device-to-device peer sync.
# NEVER server-synced; snapshots persist in _vault_state (PGlite). Sync runs
# over any VaultDuplex byte pipe (WebRTC production lane, in-memory tests).
# ═══════════════════════════════════════════════════════════════════════════
mkdir -p src/features/vault/{stores,sync}
cat > src/features/vault/stores/vaultStore.ts << 'EOF'
// TJ-ARCH-MOB-001 compliant — the vault is `local`-class: NEVER server-synced.
// One Loro doc per vault (references/sync/peer-crdt.md): maps profile /
// preferences / agent_facts. Persisted as encoded snapshots in _vault_state;
// the doc is the truth, the row is a cache. Feature code and agents use the
// typed facade — nobody touches Loro APIs outside this module and sync/.
import { LoroDoc } from 'loro-crdt'
import type { PGlite } from '@electric-sql/pglite'

export const VAULT_DOC_ID = 'user-vault'
/** Debounce for snapshot persistence after a mutation burst. */
const SNAPSHOT_DEBOUNCE_MS = 250

export interface VaultFact {
  key: string
  value: string
  learnedAt: string
}

/** Typed facade over the vault doc. Plain values in/out; CRDT stays inside. */
export class VaultRepository {
  private saveTimer: ReturnType<typeof setTimeout> | null = null

  constructor(
    readonly doc: LoroDoc,
    private readonly persist: (snapshot: Uint8Array, versionVector: Uint8Array) => Promise<void>,
  ) {
    // Any committed local change schedules a snapshot save (debounced).
    this.doc.subscribe(() => this.scheduleSave())
  }

  getProfileField(field: string): string | undefined {
    const value = this.doc.getMap('profile').get(field)
    return typeof value === 'string' ? value : undefined
  }

  setProfileField(field: string, value: string): void {
    this.doc.getMap('profile').set(field, value)
    this.doc.commit()
  }

  getPreference(key: string): string | undefined {
    const value = this.doc.getMap('preferences').get(key)
    return typeof value === 'string' ? value : undefined
  }

  setPreference(key: string, value: string): void {
    this.doc.getMap('preferences').set(key, value)
    this.doc.commit()
  }

  /** Agent-learned facts about the user (client-side agent data). */
  addAgentFact(fact: VaultFact): void {
    this.doc.getMap('agent_facts').set(fact.key, JSON.stringify(fact))
    this.doc.commit()
  }

  agentFacts(): VaultFact[] {
    const map = this.doc.getMap('agent_facts')
    const facts: VaultFact[] = []
    for (const key of map.keys()) {
      const raw = map.get(key)
      if (typeof raw === 'string') facts.push(JSON.parse(raw) as VaultFact)
    }
    return facts
  }

  async flush(): Promise<void> {
    if (this.saveTimer) {
      clearTimeout(this.saveTimer)
      this.saveTimer = null
    }
    await this.persist(
      this.doc.export({ mode: 'snapshot' }),
      this.doc.version().encode(),
    )
  }

  private scheduleSave(): void {
    if (this.saveTimer) clearTimeout(this.saveTimer)
    this.saveTimer = setTimeout(() => {
      void this.flush()
    }, SNAPSHOT_DEBOUNCE_MS)
  }
}

/** Additive DDL for the local vault row. NOT a PEM entity, NOT in any SyncScope. */
export const VAULT_STATE_DDL = `
CREATE TABLE IF NOT EXISTS _vault_state (
  doc_id text PRIMARY KEY,
  crdt_state bytea NOT NULL,
  version_vector bytea NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);`

/** Open (or create) the vault against a PGlite store. */
export async function openVault(db: PGlite): Promise<VaultRepository> {
  await db.exec(VAULT_STATE_DDL)
  const doc = new LoroDoc()
  const existing = await db.query<{ crdt_state: Uint8Array }>(
    'SELECT crdt_state FROM _vault_state WHERE doc_id = $1',
    [VAULT_DOC_ID],
  )
  const row = existing.rows[0]
  if (row) doc.import(new Uint8Array(row.crdt_state))
  return new VaultRepository(doc, async (snapshot, versionVector) => {
    await db.query(
      `INSERT INTO _vault_state (doc_id, crdt_state, version_vector, updated_at)
       VALUES ($1, $2, $3, now())
       ON CONFLICT (doc_id) DO UPDATE
         SET crdt_state = $2, version_vector = $3, updated_at = now()`,
      [VAULT_DOC_ID, snapshot, versionVector],
    )
  })
}
EOF
ok "src/features/vault/stores/vaultStore.ts"

cat > src/features/vault/sync/duplex.ts << 'EOF'
// TJ-ARCH-MOB-001 compliant — transport seam + framing for vault peer sync.
// Any byte pipe between two of the user's devices can carry the protocol:
// WebRTC DataChannels (production/browser lane), an in-memory pair (tests).
// Frames are 16 KiB; logical messages reassemble up to 256 KiB.

/** A bidirectional byte pipe to ONE paired peer. Dumb by design. */
export interface VaultDuplex {
  send(frame: Uint8Array): void
  onFrame(handler: (frame: Uint8Array) => void): void
  close(): void
}

export const FRAME_PAYLOAD_BYTES = 16 * 1024 - 9 // 16 KiB frame incl. 9-byte header
export const MAX_MESSAGE_BYTES = 256 * 1024

export type VaultMessage =
  | { kind: 'hello'; versionVector: Uint8Array }
  | { kind: 'delta'; update: Uint8Array }

const KIND_HELLO = 1
const KIND_DELTA = 2

/** Encode one logical message into 16 KiB frames: [msgId u32][seq u16][total u16][kind u8][chunk]. */
export function encodeFrames(message: VaultMessage, msgId: number): Uint8Array[] {
  const payload = message.kind === 'hello' ? message.versionVector : message.update
  if (payload.length > MAX_MESSAGE_BYTES) {
    throw new Error(`vault message exceeds ${MAX_MESSAGE_BYTES} bytes — blobs do not go in the doc`)
  }
  const kind = message.kind === 'hello' ? KIND_HELLO : KIND_DELTA
  const total = Math.max(1, Math.ceil(payload.length / FRAME_PAYLOAD_BYTES))
  const frames: Uint8Array[] = []
  for (let seq = 0; seq < total; seq++) {
    const chunk = payload.subarray(seq * FRAME_PAYLOAD_BYTES, (seq + 1) * FRAME_PAYLOAD_BYTES)
    const frame = new Uint8Array(9 + chunk.length)
    const view = new DataView(frame.buffer)
    view.setUint32(0, msgId)
    view.setUint16(4, seq)
    view.setUint16(6, total)
    view.setUint8(8, kind)
    frame.set(chunk, 9)
    frames.push(frame)
  }
  return frames
}

/** Reassembles frames into logical messages (per-peer instance). */
export class FrameAssembler {
  private readonly partial = new Map<number, { kind: number; total: number; chunks: Map<number, Uint8Array> }>()

  push(frame: Uint8Array): VaultMessage | null {
    const view = new DataView(frame.buffer, frame.byteOffset)
    const msgId = view.getUint32(0)
    const seq = view.getUint16(4)
    const total = view.getUint16(6)
    const kind = view.getUint8(8)
    const chunk = frame.subarray(9)

    let entry = this.partial.get(msgId)
    if (!entry) {
      entry = { kind, total, chunks: new Map() }
      this.partial.set(msgId, entry)
    }
    entry.chunks.set(seq, chunk)
    if (entry.chunks.size < entry.total) return null

    this.partial.delete(msgId)
    const size = [...entry.chunks.values()].reduce((n, c) => n + c.length, 0)
    const payload = new Uint8Array(size)
    let offset = 0
    for (let i = 0; i < entry.total; i++) {
      const part = entry.chunks.get(i)
      if (!part) return null // missing sequence — drop (peer will resend on next delta)
      payload.set(part, offset)
      offset += part.length
    }
    return entry.kind === KIND_HELLO
      ? { kind: 'hello', versionVector: payload }
      : { kind: 'delta', update: payload }
  }
}
EOF
ok "src/features/vault/sync/duplex.ts"

cat > src/features/vault/sync/peerSync.ts << 'EOF'
// TJ-ARCH-MOB-001 compliant — the vault peer-sync protocol
// (references/sync/peer-crdt.md): exchange version vectors, send
// export_updates_since deltas both ways, converge commutatively, repeat on
// mutation (debounced, delta-only). Transport-agnostic over VaultDuplex.
import { VersionVector } from 'loro-crdt'
import type { VaultRepository } from '../stores/vaultStore'
import { encodeFrames, FrameAssembler, type VaultDuplex } from './duplex'

const BROADCAST_DEBOUNCE_MS = 100

/** One live pairing session between this device's vault and one peer. */
export class VaultPeerSession {
  private readonly assembler = new FrameAssembler()
  private peerVersion: VersionVector | null = null
  private nextMsgId = 1
  private broadcastTimer: ReturnType<typeof setTimeout> | null = null
  private readonly unsubscribe: () => void

  constructor(
    private readonly vault: VaultRepository,
    private readonly duplex: VaultDuplex,
  ) {
    duplex.onFrame((frame) => this.onFrame(frame))
    // Local commits propagate as deltas (debounced to batch mutation bursts).
    this.unsubscribe = this.vault.doc.subscribe((event) => {
      if (event.by === 'local') this.scheduleBroadcast()
    })
    this.sendHello()
  }

  close(): void {
    if (this.broadcastTimer) clearTimeout(this.broadcastTimer)
    this.unsubscribe()
    this.duplex.close()
  }

  private send(message: Parameters<typeof encodeFrames>[0]): void {
    for (const frame of encodeFrames(message, this.nextMsgId++)) {
      this.duplex.send(frame)
    }
  }

  private sendHello(): void {
    this.send({ kind: 'hello', versionVector: this.vault.doc.version().encode() })
  }

  private sendDeltaSince(peerVersion: VersionVector | null): void {
    const update = peerVersion
      ? this.vault.doc.export({ mode: 'update', from: peerVersion })
      : this.vault.doc.export({ mode: 'update' })
    if (update.length > 0) this.send({ kind: 'delta', update })
    this.peerVersion = this.vault.doc.version()
  }

  private scheduleBroadcast(): void {
    if (this.broadcastTimer) clearTimeout(this.broadcastTimer)
    this.broadcastTimer = setTimeout(() => this.sendDeltaSince(this.peerVersion), BROADCAST_DEBOUNCE_MS)
  }

  private onFrame(frame: Uint8Array): void {
    const message = this.assembler.push(frame)
    if (!message) return
    if (message.kind === 'hello') {
      const theirs = VersionVector.decode(message.versionVector)
      this.sendDeltaSince(theirs)
      return
    }
    // Delta: commutative import; convergence needs no ordering.
    this.vault.doc.import(message.update)
    this.peerVersion = this.vault.doc.version()
  }
}
EOF
ok "src/features/vault/sync/peerSync.ts"

cat > src/features/vault/sync/memoryDuplex.ts << 'EOF'
// TJ-ARCH-MOB-001 compliant — in-memory duplex pair implementing the same
// chunked-frame contract as the WebRTC lane. The legitimate test double at
// this IO boundary (no mocks of protocol internals).
import type { VaultDuplex } from './duplex'

class MemoryEnd implements VaultDuplex {
  private handler: ((frame: Uint8Array) => void) | null = null
  private peer: MemoryEnd | null = null
  private closed = false

  connect(peer: MemoryEnd): void {
    this.peer = peer
  }

  send(frame: Uint8Array): void {
    if (this.closed || !this.peer) return
    const target = this.peer
    // Async delivery mirrors a real channel (no re-entrant handler stacks).
    queueMicrotask(() => {
      if (!target.closed) target.handler?.(frame)
    })
  }

  onFrame(handler: (frame: Uint8Array) => void): void {
    this.handler = handler
  }

  close(): void {
    this.closed = true
  }
}

export function memoryDuplexPair(): [VaultDuplex, VaultDuplex] {
  const a = new MemoryEnd()
  const b = new MemoryEnd()
  a.connect(b)
  b.connect(a)
  return [a, b]
}
EOF
ok "src/features/vault/sync/memoryDuplex.ts"

cat > src/features/vault/sync/webrtcDuplex.ts << 'EOF'
// TJ-ARCH-MOB-001 compliant — WebRTC DataChannel adapter for vault peer sync.
// The browser-capable device-to-device lane (references/sync/peer-crdt.md).
// This shim is DUMB: it moves frames and surfaces events; every protocol
// decision lives in VaultPeerSession. Signaling here is the dev lane (manual
// offer/answer copy — QR/paste); production signaling is FRF SignalService,
// swapped as configuration, not redesign. The signaler is untrusted by design:
// it sees only SDP blobs, never vault bytes (DTLS underneath).
import type { VaultDuplex } from './duplex'

const CHANNEL_LABEL = 'vault-sync-v1'

class DataChannelDuplex implements VaultDuplex {
  private handler: ((frame: Uint8Array) => void) | null = null

  constructor(
    private readonly connection: RTCPeerConnection,
    private readonly channel: RTCDataChannel,
  ) {
    channel.binaryType = 'arraybuffer'
    channel.onmessage = (event: MessageEvent<ArrayBuffer>) => {
      this.handler?.(new Uint8Array(event.data))
    }
  }

  send(frame: Uint8Array): void {
    if (this.channel.readyState !== 'open') return
    // Copy into a plain ArrayBuffer — RTCDataChannel.send's typing rejects
    // views over ArrayBufferLike (SharedArrayBuffer).
    const buffer = new ArrayBuffer(frame.byteLength)
    new Uint8Array(buffer).set(frame)
    this.channel.send(buffer)
  }

  onFrame(handler: (frame: Uint8Array) => void): void {
    this.handler = handler
  }

  close(): void {
    this.channel.close()
    this.connection.close()
  }
}

function waitForOpen(channel: RTCDataChannel): Promise<void> {
  if (channel.readyState === 'open') return Promise.resolve()
  return new Promise((resolve, reject) => {
    channel.onopen = () => resolve()
    channel.onerror = () => reject(new Error('vault DataChannel failed to open'))
  })
}

/** Gathered-ICE local description as a pastable/QR-able dev-signaling blob. */
async function localDescriptionBlob(connection: RTCPeerConnection): Promise<string> {
  await new Promise<void>((resolve) => {
    if (connection.iceGatheringState === 'complete') return resolve()
    connection.onicegatheringstatechange = () => {
      if (connection.iceGatheringState === 'complete') resolve()
    }
  })
  return JSON.stringify(connection.localDescription)
}

export interface OfferSession {
  /** Give this blob to the other device (paste/QR — the dev signaler). */
  offer: string
  /** Complete the pairing with the answering device's blob. */
  accept(answer: string): Promise<VaultDuplex>
}

/** Initiator side of a pairing. */
export async function createOfferSession(config?: RTCConfiguration): Promise<OfferSession> {
  const connection = new RTCPeerConnection(config)
  const channel = connection.createDataChannel(CHANNEL_LABEL)
  await connection.setLocalDescription(await connection.createOffer())
  const offer = await localDescriptionBlob(connection)
  return {
    offer,
    async accept(answer: string): Promise<VaultDuplex> {
      await connection.setRemoteDescription(JSON.parse(answer) as RTCSessionDescriptionInit)
      await waitForOpen(channel)
      return new DataChannelDuplex(connection, channel)
    },
  }
}

/** Responder side: consume the offer blob, produce the answer blob. */
export async function acceptOfferSession(
  offer: string,
  config?: RTCConfiguration,
): Promise<{ answer: string; duplex: Promise<VaultDuplex> }> {
  const connection = new RTCPeerConnection(config)
  const channelReady = new Promise<RTCDataChannel>((resolve) => {
    connection.ondatachannel = (event) => resolve(event.channel)
  })
  await connection.setRemoteDescription(JSON.parse(offer) as RTCSessionDescriptionInit)
  await connection.setLocalDescription(await connection.createAnswer())
  const answer = await localDescriptionBlob(connection)
  const duplex = channelReady.then(async (channel) => {
    await waitForOpen(channel)
    return new DataChannelDuplex(connection, channel)
  })
  return { answer, duplex }
}
EOF
ok "src/features/vault/sync/webrtcDuplex.ts"

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

cat > src/features/chat/hooks/useAssistantChatRuntime.ts << 'EOF'
// TJ-ARCH-MOB-001 compliant — Assistant UI adapter; no IPC in hooks.
import { useExternalStoreRuntime, type ThreadMessageLike } from '@assistant-ui/react'
import type { ContentBlock, Message } from '@/bridge/a2ui/types'
import { useChat } from './useChat'

type AssistantPart = Exclude<ThreadMessageLike['content'], string>[number]

function toPart(block: ContentBlock): AssistantPart {
  switch (block.type) {
    case 'text': return { type: 'text', text: block.text }
    case 'thinking': return { type: 'reasoning', text: block.text }
    case 'code': return { type: 'text', text: `\`\`\`${block.language}\n${block.code}\n\`\`\`` }
    case 'citation': return { type: 'data', name: 'citation', data: block }
    case 'memory': return { type: 'data', name: 'memory', data: block }
    case 'toolUse': return { type: 'tool-call', toolCallId: block.id, toolName: block.name, argsText: block.inputJson }
    case 'toolResult': return { type: 'tool-call', toolCallId: block.toolUseId, toolName: 'tool result', args: {}, result: block.outputJson, isError: block.isError }
    case 'skill': return { type: 'data', name: 'skill', data: block }
    case 'artifact': return { type: 'data', name: 'artifact', data: block }
    case 'image': return { type: 'image', image: block.url ?? `data:${block.mime};base64,${block.dataBase64 ?? ''}` }
    case 'divider': return { type: 'text', text: '\n\n' }
  }
}

function convertMessage(message: Message): ThreadMessageLike {
  return {
    id: message.id,
    role: message.role,
    createdAt: new Date(message.timestamp),
    content: message.content.map(toPart),
    ...(message.role === 'assistant' ? { status: message.isStreaming
      ? { type: 'running' as const }
      : { type: 'complete' as const, reason: 'stop' as const } } : {}),
  }
}

export function useAssistantChatRuntime() {
  const { messages, isStreaming, sendMessage } = useChat()
  return useExternalStoreRuntime({
    messages,
    isRunning: isStreaming,
    convertMessage,
    suggestions: [{ prompt: 'Help me connect the important details.' }],
    onNew: async (message) => {
      const text = message.content.filter((part) => part.type === 'text').map((part) => part.text).join('\n').trim()
      if (text) await sendMessage(text)
    },
  })
}
EOF

cat > src/features/chat/components/ChatScreen.tsx << 'EOF'
// TJ-ARCH-MOB-001 compliant — Shadcn shell + Assistant UI chat primitives.
import { AssistantRuntimeProvider } from '@assistant-ui/react'
import { Thread } from '@/components/assistant-ui/thread'
import { ThreadList } from '@/components/assistant-ui/thread-list'
import { useAssistantChatRuntime } from '../hooks/useAssistantChatRuntime'

export function ChatScreen() {
  const runtime = useAssistantChatRuntime()
  return (
    <AssistantRuntimeProvider runtime={runtime}>
      <main className="flex h-dvh overflow-hidden bg-background">
        <aside className="hidden w-72 shrink-0 bg-secondary p-4 lg:block">
          <p className="mb-4 text-sm font-semibold">Conversations</p>
          <ThreadList />
        </aside>
        <section className="min-w-0 flex-1 bg-background"><Thread /></section>
      </main>
    </AssistantRuntimeProvider>
  )
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
@import "tw-animate-css";
@import "shadcn/tailwind.css";

@theme {
  --color-background: #0B0F14;
  --color-surface: #161D29;
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
* { border-color: transparent !important; box-shadow: none !important; }
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
# The local npm CLI is installed later. The environment gate already requires
# cargo-tauri, so use that deterministic bootstrap instead of an ambiguous
# `npx tauri` registry lookup.
cargo tauri icon app-icon.png > /dev/null
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
  # A newly generated project has no lockfile yet. Generate it once while
  # honoring the tracked lifecycle-script allowlist; all later verification
  # and CI installs use --frozen-lockfile.
  pnpm install --no-frozen-lockfile
  ok "pnpm lockfile + dependencies"
else
  npm install
  ok "npm install"
fi

step "Installing Shadcn UI and Assistant UI source components"
if [[ "${SKIP_INSTALL:-0}" == "1" ]]; then
  ok "registry component installation skipped with dependencies"
else
  pnpm exec shadcn add button sheet sidebar toggle-group switch card -y
  pnpm dlx assistant-ui@latest add thread thread-list markdown-text --use-pnpm -y
  ok "Shadcn primitives + Assistant UI thread/composer/thread-list"
fi

echo ""
echo -e "${GREEN}✅ Tauri app scaffolded in ${OUT}/${NC}"
echo ""
echo "  Next steps:"
echo "  1. cd $OUT && pnpm tauri dev"
echo "  2. Wire gen_ui_core: uncomment path dep in src-tauri/Cargo.toml"
echo "  3. Customize the generated Shadcn/Assistant UI sources with product tokens"
echo "  4. Add auth: bash scripts/add-auth.sh supabase|kratos"
