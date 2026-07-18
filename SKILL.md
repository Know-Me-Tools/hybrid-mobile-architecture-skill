---
name: hybrid-mobile-architecture
description: >
  Build, scaffold, audit, and transform application codebases implementing the
  Prometheus AGS hybrid mobile architecture — Flutter + Rust FFI for iOS/Android,
  Tauri + React 19 for macOS/Windows/Linux, sharing a single gen_ui_core Rust crate.
  Use this skill whenever: (1) creating a new Flutter, Tauri, or hybrid mobile/desktop
  app; (2) adding AI agent features to an existing codebase; (3) wiring Rust inference,
  MCP, SurrealDB, or A2UI/AG-UI protocols into any UI layer; (4) setting up feature-based
  clean architecture with Riverpod (Flutter) or Zustand + Prometheus Entity Management 3.x (React); (5) integrating
  Ory Kratos or Supabase authentication; (6) scaffolding the shared Rust core (gen_ui_core)
  with networking, LLM interaction, local inference, and UAR support. Always trigger for
  any mention of gen_ui, hybrid app, flutter rust, tauri react, riverpod, zustand, prometheus entity management,
  universal agent runtime, A2UI, AG-UI, MCP mobile, or on-device inference.
version: 1.0.0
author: Travis James <travis@prometheusags.ai>
organization: Prometheus AGS / KnowMe, LLC
compatibility:
  required_tools:
    - bash
    - git
  optional_tools:
    - flutter
    - cargo
    - node
    - rustup
---

# Hybrid Mobile Architecture Skill

Scaffold, extend, and maintain applications built on the Prometheus AGS hybrid
mobile architecture: Flutter for mobile, Tauri for desktop, gen_ui_core Rust
for all infrastructure. This skill covers the complete lifecycle.

## Quick orientation

Read the architectural standard document before any substantial work:
`references/arch-standard.md` — this is the decision-making authority.

For platform-specific deep dives:
- Flutter patterns → `references/flutter/patterns.md`
- Tauri/React patterns → `references/tauri/patterns.md`
- Rust core patterns → `references/rust/patterns.md`
- Auth patterns → `references/auth/patterns.md`

---

## Step 1 — Environment check and tool installation

Before any scaffolding or transformation, verify the environment. Run
`scripts/check-env.sh` which will detect missing tools and prompt to install them.

### Required tool matrix

| Tool | Minimum Version | Install command |
|------|----------------|-----------------|
| Rust + Cargo | 1.96+ | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` |
| Flutter SDK | beta channel, latest | See `scripts/install-flutter.sh` |
| Node.js | 24+ (Active LTS — pin, not `--lts`) | `curl -fsSL https://fnm.vercel.app/install \| bash && fnm install 24` |
| Tauri CLI | 2.10+ | `cargo install tauri-cli --version "^2"` |
| flutter_rust_bridge_codegen | 2.12+ | `cargo install flutter_rust_bridge_codegen` |
| cargo-ndk | latest | `cargo install cargo-ndk` (Android only) |
| create-tauri-app | latest | `npm create tauri-app@latest` |

Run the environment check before proceeding:
```bash
bash scripts/check-env.sh
```

---

## Step 2 — Determine the operation

Ask the user which of these they need. Read the relevant reference file afterward.

### 2a. New project scaffold
- **Flutter mobile app** — `scripts/scaffold-flutter.sh <project-name>`
- **Tauri desktop app** — `scripts/scaffold-tauri.sh <project-name>`
- **Hybrid (both surfaces + shared Rust)** — `scripts/scaffold-hybrid.sh <project-name>`
- **Rust core only** — `scripts/scaffold-rust-core.sh <project-name>`

### 2b. Existing codebase transformation
- Add gen_ui_core Rust to existing Flutter app
- Add A2UI/AG-UI streaming to existing React/Tauri app
- Add feature-based clean architecture to existing project
- Add Ory Kratos or Supabase authentication

### 2c. Code generation
- New feature module (Flutter or Tauri)
- New ContentBlock variant (full stack: Rust enum → Dart/TS sealed union → widget/component)
- New MCP server integration
- New SurrealDB query/store

### 2d. Audit
- Check architecture compliance against TJ-ARCH-MOB-001
- Verify state management patterns (Riverpod / Zustand + Prometheus Entity Management 3.x)
- Verify clean architecture boundaries (no direct store→API calls in components)

---

## Step 3 — Architecture rules (always enforce)

These are invariants. Violating them makes code non-compliant with the standard.

### Rust core (gen_ui_core)

1. **All networking, LLM interaction, inference, MCP, and agent logic lives in Rust.** Never re-implement these in Dart or TypeScript.
2. The crate exposes exactly one FFI surface: `api.rs` (Flutter) or Tauri commands/events (desktop).
3. One global Tokio runtime per process. Never create additional runtimes.
4. All CPU-bound work (inference forward passes, GGUF loading) uses `spawn_blocking`.
5. ContentBlock model + A2UI/AG-UI protocol pipeline is the canonical event contract between Rust and UI.

### Flutter state management (Riverpod 3.3)

Read `references/flutter/patterns.md` for the full Riverpod architecture.

**Key invariants:**
- Use `@riverpod` codegen annotations, never manual `Provider` declarations
- `AsyncNotifier` for async state; `Notifier` for sync state
- `autoDispose` on all streaming providers to prevent memory leaks
- Never access `ref.watch` outside build / provider bodies
- ContentBlock mutations happen only via `ChatNotifier.streamBlock()` — never direct state assignment
- Feature modules own their providers; cross-feature deps go through the domain layer

### Tauri + React 19 state management (Zustand 5 + Prometheus Entity Management 3.x)

Read `references/tauri/patterns.md` for the full React architecture.

**Strict layer boundary:**
```
Component → Hook → Store → [Rust IPC / API]
           ↑               ↑
      (hook only)    (store only, never component)
```

**Zustand (client-side state):**
- All client-side state lives in Zustand 5 stores
- Use `@tauri-apps/plugin-store` for Zustand persistence when state must survive restarts
- Rust-side state extension via the Tauri Zustand plugin for shared state crossing the IPC boundary

**Prometheus Entity Management 3.x (server/async/entity state):**
- Always use `@prometheus-ags/prometheus-entity-management` 3.x instead of TanStack Query
- Register each entity transport once, then read through `useEntities`, `useEntityQuery`, or `useEntity`
- Perform graph-aware writes with `useEntityMutation`; normalized entities update every subscribed view
- Never call `fetch`/`invoke` directly from a component

**TanStack Router:**
- File-based routing via `@tanstack/react-router`
- Route-level code splitting is required for routes with >3 components
- Auth guards implemented as `beforeLoad` route functions

**Visual components:**
- Components talk ONLY to hooks (`useFeatureName` pattern)
- No direct store imports in components
- No `invoke()` calls in components

**shadcn-equivalent (React):** Prefer `shadcn/ui` components over raw HTML controls with Tailwind 4. Run `npx shadcn@latest init` during scaffold.

**React chat:** Use Assistant UI for thread, composer, thread-list, streaming, attachment, and message-action behavior. Persist normalized conversation entities with Prometheus Entity Management 3.x: PGlite on web and pglite-oxide through Rust on Tauri. Zustand is transient UI state only. Apply the Flat 2.0 contract—no visible borders, divider lines, or layout shadows.

**shadcn-equivalent (Flutter):** Use `shadcn_flutter` package — see `references/flutter/patterns.md`.

### Feature-based clean architecture

Both Flutter and React follow the same feature module structure:

```
features/
  <feature-name>/
    data/          ← repositories, data sources, DTOs
    domain/        ← entities, use cases, repository interfaces
    presentation/  ← UI components/widgets, providers/hooks
```

**Dependency direction:** presentation → domain ← data

Cross-feature navigation and shared state go through the application layer (`app/`), never feature-to-feature direct imports.

### Authentication (Ory Kratos + Supabase)

Read `references/auth/patterns.md` before implementing any auth.

**Ory Kratos:** Self-hosted identity. Handles login flows, registration, MFA, sessions.
**Supabase:** Managed Postgres + Auth. RLS policies enforce row-level security.

Both are supported. Many projects use Kratos for identity (SSO, enterprise) and Supabase for database/realtime. They are not mutually exclusive.

---

## Step 4 — UAR integration (Universal Agent Runtime)

The UAR can be integrated in two modes:

**External mode (URL-based):** UAR runs as a separate service. Connect via its HTTP/WebSocket API. Use when UAR is a shared enterprise infrastructure component.

**Embedded mode:** UAR is embedded directly in `gen_ui_core`. The agent loop, MCP registry, and protocol pipeline run in-process. This is the default for standalone consumer apps (KnowMe) and field tools (Prometheus AGS mobile).

For embedded mode, `gen_ui_core` already contains the full UAR implementation:
- `agent/mod.rs` — PMPO loop
- `mcp/` — MCP client + registry
- `protocol/` — A2UI + AG-UI pipeline
- `inference/` — local inference behind the `InferenceProvider` trait (pinned llama.cpp/Qwen on desktop + mobile, WebLLM on web; mistral.rs optional — see `versions.toml` `[inference]`)

For external mode, configure the URL in `gen_ui_core/src/config.rs` and the crate switches to HTTP client mode.

---

## Step 5 — Code generation patterns

When generating code, always:

1. Read the relevant reference file for the target platform first
2. Follow the feature-based directory structure
3. Include the correct imports (no wildcard imports)
4. Add the `// TJ-ARCH-MOB-001 compliant` marker at the top of generated files
5. For Rust: run `cargo fmt` and `cargo clippy` on generated code mentally before outputting
6. For Flutter: follow `flutter_lints` rules
7. For React: follow the ESLint config in `references/tauri/eslint-config.md`

When adding a new ContentBlock type, always do all 7 steps in `references/rust/new-block-type.md`.

---

## Reference index

| File | When to read |
|------|-------------|
| `references/arch-standard.md` | Architecture decisions, platform selection, decision matrix |
| `references/flutter/patterns.md` | Any Flutter work — Riverpod, clean arch, shadcn_flutter, FFI wiring |
| `references/flutter/auth.md` | Flutter Kratos/Supabase — full implementation including GoRouter guards |
| `references/flutter/testing.md` | Flutter testing — Riverpod test, widget tests, golden tests |
| `references/tauri/patterns.md` | Any Tauri/React work — Zustand, Prometheus Entity Management 3.x, TanStack Router/Table, IPC, layer contract |
| `references/tauri/auth.md` | React Kratos/Supabase — full store + Prometheus Entity Management + component |
| `references/tauri/eslint-config.md` | ESLint 9 flat config, tsconfig strict, Prettier, Vitest setup |
| `references/tauri/testing.md` | Vitest, React Testing Library, layer contract enforcement tests |
| `references/rust/patterns.md` | gen_ui_core module structure, FFI rules, Tauri commands, UAR modes |
| `references/rust/new-block-type.md` | 7-step full-stack guide for new ContentBlock variants |
| `references/rust/testing.md` | cargo test, tokio::test, wiremock, SurrealDB integration tests |
| `references/auth/patterns.md` | Auth strategy selection — when Kratos vs Supabase vs combined |
| `scripts/` | Runnable scripts — check-env, scaffold, new-feature, add-auth, audit |
| `assets/templates/` | Code templates — flutter-feature, tauri-feature, rust-core, content-block |
| `docs/tj-arch-mob-001.html` | Full XHTML architectural standard (TJ-ARCH-MOB-001) |
| `docs/gen_ui_spec.html` | Full gen_ui technical specification and SVG architecture diagrams |
