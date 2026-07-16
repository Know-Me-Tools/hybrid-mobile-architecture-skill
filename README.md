# Hybrid Mobile Architecture Skill
**TJ-ARCH-MOB-001 · v1.0.0 · Prometheus AGS / KnowMe, LLC**

An [agentskills.io](https://agentskills.io) skill for building, scaffolding, and maintaining
applications on the Prometheus AGS hybrid mobile architecture: **one Rust core, every
platform** — Flutter iOS/Android, Tauri macOS/Windows/Linux, and web via WASM.

---

## What this skill does

- **Scaffolds** complete hybrid projects: Flutter mobile + Tauri desktop + web/WASM sharing a layered 13-crate Rust workspace
- **Bootstraps** the full toolchain (Rust 1.96+ w/ WASM target, Flutter/Dart beta channel + Dart MCP server, Node 24 LTS + bun + pnpm + TypeScript 7, OpenSpec, Prometheus Skill System)
- **Enforces** the 40 Prometheus Base Rules ([AGENT_BASE_RULES.md](AGENT_BASE_RULES.md)), feature-based clean architecture, strict layering, and component contracts — for humans, coding agents, and generated projects alike
- **Generates** feature modules, ContentBlock variants, authentication flows, MCP integrations, publishable packages (crates.io / pub.dev / npm), and project-local UI/UX skills with activation hooks
- **Audits** codebases for TJ-ARCH-MOB-001 compliance (`audit.sh all` — layer contracts, per-surface checks)

---

## Architecture overview

```
iOS / Android              macOS / Windows / Linux         Web
Flutter + Riverpod 3       Tauri 2 + React 19 + Zustand    WASM (wasm-bindgen)
flutter_rust_bridge 2.12   Tauri IPC (invoke/emit)         @prometheus-ags/gen-ui-wasm
        ↓                            ↓                          ↓
   ╔═══════════════════════════════════════════════════════════════╗
   ║              gen_ui layered Rust workspace (13 crates)         ║
   ║                                                                ║
   ║  gen_ui_types      frozen trait seams · ContentBlock contract  ║
   ║  gen_ui_runtime    one Tokio runtime (native) / wasm futures   ║
   ║  gen_ui_protocol   A2UI / AG-UI adapters                       ║
   ║  gen_ui_client     Anthropic + Flint (gate/forge/FRF)          ║
   ║  gen_ui_mcp        MCP registry (JSON-RPC 2.0 + SSE)           ║
   ║  gen_ui_db         relational (pg/sqlite) + sync + startup     ║
   ║  gen_ui_db_graph   SurrealDB 3.2 hybrid graph-RAG (HNSW+BM25)  ║
   ║  gen_ui_inference  InferenceProvider (mistral.rs / llama.cpp)  ║
   ║  gen_ui_agent      Universal Agent Runtime (PMPO loop)         ║
   ║  leaves: gen_ui_ffi · tauri-plugin-gen-ui · gen_ui_wasm        ║
   ╚═══════════════════════════════════════════════════════════════╝
```

Business logic, networking, inference, and persistence live **only** in Rust —
never re-implemented in Dart or TypeScript.

---

## Current status & roadmap

**Done (phase: scaffold-full-hybrid-project, 12/12 changes):** the layered workspace
scaffold with compile-speed profiles (clippy-first loop, panic=unwind FFI fix,
wasm-release profile), wasm32 compile-proven core, unified relational+sync+graph-RAG
data layer, Flint platform integration, FFI/Tauri/wasm leaves + publishing scaffolds,
Flutter surface (Riverpod 3.3, PEM Dart port), React surface (Vite 8 + PEM +
gen-ui-react), features-first testing philosophy, project-local UI/UX skills, and
project-level MCP config (Dart/Flutter + shadcn) for Claude Code / Codex / OpenCode /
Kimi.

**In progress (phase: codegen-and-ci-verification):**

1. **Bootstrap pillars** — extend `check-env.sh` into a four-pillar installer that
   verifies-or-installs on any box: Rust + WASM + a full
   [Prometheus Skill System](https://github.com/Prometheus-AGS/prometheus-skill-system)
   instance (self-improving loops included); OpenSpec (latest, `@fission-ai/openspec`);
   Flutter/Dart **beta channel** (ships the Dart MCP server); Node 24 LTS + bun + pnpm +
   TypeScript 7.
2. **Proof-of-concept app** — `apps/knowme-poc`, built from the KnowMe reference docs
   (`docs/reference-app/`), showcasing the broadest practical capability range as one
   continuous demo narrative: streamed ContentBlock chat → voice note → on-device
   whisper transcription → graph-RAG memory ingest → cited answers → offline edit →
   cross-device sync → local GGUF inference (Metal). First real end-to-end run of
   frb codegen, build_runner, and on-target builds.
3. **CI** — clippy + `audit.sh all` + boundary test suites on every push.

---

## Quick start

### Check and install the toolchain
```bash
bash scripts/check-env.sh --install
```

### Scaffold a new hybrid project
```bash
bash scripts/scaffold-hybrid.sh my-app
```
Generated projects receive `AGENT_BASE_RULES.md`, CLAUDE.md/AGENTS.md declaring it
binding, project-local UI/UX skills with an activation hook, and publishable package
skeletons (npm + pub.dev) alongside the three surfaces.

### Single surfaces / pieces
```bash
bash scripts/scaffold-flutter.sh mobile my-app     # Flutter app
bash scripts/scaffold-tauri.sh desktop my-app      # Tauri desktop/web app
bash scripts/scaffold-rust-core.sh rust            # layered Rust workspace
bash scripts/scaffold-packages.sh .                # publishable packages
bash scripts/add-project-skills.sh .               # project-local skills + hooks
```

### Add authentication / features · audit
```bash
bash scripts/add-auth.sh supabase flutter ./mobile
bash scripts/add-auth.sh kratos tauri ./desktop
bash scripts/new-feature.sh conversation flutter ./mobile
bash scripts/audit.sh all .                        # both surfaces + workspace detection
```

---

## Standards enforced

| Standard | Rule |
|---|---|
| Agent conduct | [AGENT_BASE_RULES.md](AGENT_BASE_RULES.md) — the 40 Prometheus Base Rules, binding for humans, agents, skills, and generated projects |
| State management | Riverpod 3.3 codegen (Flutter) · Zustand 5 + TanStack (React) |
| Component layer | Components → Hooks → Stores → API/Rust (stores are the only `invoke()` layer) |
| Architecture | Feature-based clean arch (`data/domain/presentation` · `api/stores/queries/hooks/components`) |
| UI components | shadcn_flutter (Flutter) · shadcn/ui (React) |
| Authentication | Ory Kratos (self-hosted) · Supabase (managed) · Flint gate (platform) |
| Business logic | Always in the Rust workspace — never re-implemented in Dart/TS |
| Streaming | A2UI/AG-UI protocol pipeline — 11-variant ContentBlock sealed union |
| Testing | Features first; boundary tests at public APIs; snapshot-preferred; no internal mocks |
| Compile speed | `bacon clippy` inner loop · dep-optimized dev profiles · cross-target `cargo check` gates |

---

## Package contents

```
hybrid-mobile-architecture/
  SKILL.md                          # Skill instructions + triggering
  AGENT_BASE_RULES.md               # The 40 Prometheus Base Rules (canonical)
  CLAUDE.md / AGENTS.md             # Repo rules for coding agents (all harnesses)
  plugin.json / marketplace.json    # Claude Code plugin + marketplace listing
  .mcp.json / opencode.json /       # Project-level MCP config (Dart/Flutter + shadcn)
  .codex/config.toml / .kimi-code/  #   for Claude Code, OpenCode, Codex, Kimi
  docs/
    tj-arch-mob-001.html            # Full architectural standard
    gen_ui_spec.html                # gen_ui technical specification
    reference-app/                  # KnowMe reference docs (PoC source material)
    pglite-oxide-tauri-hybrid.md    # Embedded Postgres options (desktop/web)
  references/                       # Patterns: flutter/ tauri/ rust/ auth/ + wasm-targets,
                                    #   compile-speed, ui-skills (features-first testing)
  scripts/
    check-env.sh                    # Toolchain check/install (pillar bootstrap in progress)
    scaffold-hybrid.sh              # Full hybrid project (rust + surfaces + packages + skills)
    scaffold-{flutter,tauri,rust-core,packages}.sh
    add-project-skills.sh           # Project-local UI/UX skills + activation hook
    new-feature.sh / add-auth.sh / audit.sh
  templates/project-skills/         # content-block-ui · hybrid-design-tokens ·
                                    #   tauri-ui-review · flutter-golden-ui · a11y-gate
  apps/                             # Proof-of-concept applications (knowme-poc upcoming)
  openspec/                         # OpenSpec change management (active + archive)
```

---

## Products

Built for and maintained by [Prometheus Agentic Growth Solutions](https://prometheusags.ai)
and [KnowMe, LLC](https://know-me.tools).

- **KnowMe** — Flutter mobile (iOS/Android) + Tauri desktop
- **Prometheus AGS** — Tauri desktop primary + Flutter field mobile
- **TribeHealth.ai** — Flutter mobile (healthcare, non-negotiable)

---

*travisjames.ai · TJ-ARCH-MOB-001 · v1.0.0 · July 2026*
