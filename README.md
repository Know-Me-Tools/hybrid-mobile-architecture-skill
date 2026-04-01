# Hybrid Mobile Architecture Skill
**TJ-ARCH-MOB-001 · v1.0.0 · Prometheus AGS / KnowMe, LLC**

An [agentskills.io](https://agentskills.io) skill for building, scaffolding, and maintaining
applications on the Prometheus AGS hybrid mobile architecture.

---

## What this skill does

- **Scaffolds** complete hybrid projects: Flutter iOS/Android + Tauri macOS/Windows/Linux + shared Rust infrastructure
- **Installs** all required tools automatically (Flutter 3.29+, Rust 1.80+, Tauri 2.10.3, Node 22+, cargo tools)
- **Enforces** feature-based clean architecture, strict state management patterns, and component layer contracts
- **Generates** feature modules, ContentBlock variants, authentication flows, and MCP integrations
- **Audits** existing codebases for TJ-ARCH-MOB-001 compliance

---

## Architecture overview

```
iOS / Android                    macOS / Windows / Linux
Flutter + Riverpod               Tauri + React 19 + Zustand + TanStack
flutter_rust_bridge (FFI)        Tauri IPC (invoke/emit)
         ↓                                ↓
    ╔══════════════════════════════════════════╗
    ║        gen_ui_core (Rust)                ║
    ║  Tokio · Anthropic API · A2UI/AG-UI      ║
    ║  Local inference (candle GGUF)           ║
    ║  SurrealDB embedded (vector + graph)     ║
    ║  MCP client registry (JSON-RPC 2.0)      ║
    ║  Universal Agent Runtime (PMPO loop)     ║
    ╚══════════════════════════════════════════╝
```

---

## Quick start

### Scaffold a new hybrid project
```bash
bash scripts/scaffold-hybrid.sh my-app
```

### Scaffold only Flutter
```bash
bash scripts/scaffold-flutter.sh mobile my-app
```

### Scaffold only Tauri desktop
```bash
bash scripts/scaffold-tauri.sh desktop my-app
```

### Check and install tools
```bash
bash scripts/check-env.sh --install
```

### Add authentication
```bash
bash scripts/add-auth.sh supabase flutter ./mobile
bash scripts/add-auth.sh kratos tauri ./desktop
```

### Add a new feature module
```bash
bash scripts/new-feature.sh conversation flutter ./mobile
bash scripts/new-feature.sh conversation tauri ./desktop
```

### Audit compliance
```bash
bash scripts/audit.sh flutter ./mobile
bash scripts/audit.sh tauri ./desktop
bash scripts/audit.sh rust ./rust/gen_ui_core
```

---

## State management standards

### Flutter (Riverpod 2.6+)
- `@riverpod` codegen annotations — never manual providers
- `AsyncNotifier` for async state; `autoDispose` on streaming providers
- `ConsumerWidget` / `ConsumerStatefulWidget` — not `StatefulWidget` + `setState`

### Tauri/React (Zustand 5 + TanStack)
```
Component → Hook → Store → [Rust invoke() / external API]
```
- Zustand owns **client-side state** (UI, selection, filters, streaming)
- TanStack Query owns **server-side state** (queries, mutations, caching)
- Visual components import **only hooks** — never stores directly
- Hooks compose stores + TanStack Query — never call `invoke()` directly
- Stores call `invoke()` and manage all side effects

---

## Standards enforced

| Standard | Rule |
|---|---|
| State management | Riverpod (Flutter) · Zustand+TanStack (React) |
| Component layer | Components → Hooks → Stores → API/Rust |
| Architecture | Feature-based clean arch (data/domain/presentation) |
| UI components | shadcn_flutter (Flutter) · shadcn/ui (React) |
| Authentication | Ory Kratos (self-hosted) · Supabase (managed) |
| Business logic | Always in gen_ui_core Rust — never re-implemented in Dart/TS |
| Streaming | A2UI/AG-UI protocol pipeline — ContentBlock sealed union |

---

## Package contents

```
hybrid-mobile-architecture/
  SKILL.md                          # Skill instructions + triggering
  plugin.json                       # Claude Code plugin manifest
  marketplace.json                  # agentskills.io marketplace listing
  README.md                         # This file
  CHANGELOG.md                      # Version history
  LICENSE.txt                       # MIT License
  docs/
    tj-arch-mob-001.html            # Full architectural standard (XHTML)
  references/
    arch-standard.md                # Platform selection decision table
    flutter/patterns.md             # Riverpod, clean arch, shadcn_flutter, FFI
    tauri/patterns.md               # Zustand, TanStack, IPC, shadcn/ui
    rust/patterns.md                # gen_ui_core, UAR, model catalog
    rust/new-block-type.md          # 7-step guide: new ContentBlock variant
    auth/patterns.md                # Kratos + Supabase implementation
  scripts/
    check-env.sh                    # Tool detection + installation
    install-flutter.sh              # Flutter SDK installer
    scaffold-hybrid.sh              # Full hybrid project
    scaffold-flutter.sh             # Flutter app
    scaffold-tauri.sh               # Tauri desktop app
    scaffold-rust-core.sh           # gen_ui_core Rust crate
    new-feature.sh                  # Feature module (Flutter or Tauri)
    add-auth.sh                     # Authentication integration
    audit.sh                        # Compliance checker
  assets/templates/
    flutter-feature/                # Flutter feature module template
    tauri-feature/                  # Tauri/React feature module template
    rust-core/                      # gen_ui_core skeleton template
    content-block/                  # New ContentBlock variant template
```

---

## Products

Built for and maintained by [Prometheus Agentic Growth Solutions](https://prometheusags.ai)
and [KnowMe, LLC](https://know-me.tools).

- **KnowMe** — Flutter mobile (iOS/Android) + Tauri desktop
- **Prometheus AGS** — Tauri desktop primary + Flutter field mobile
- **TribeHealth.ai** — Flutter mobile (healthcare, non-negotiable)

---

*travisjames.ai · TJ-ARCH-MOB-001 · v1.0.0 · March 2026*
