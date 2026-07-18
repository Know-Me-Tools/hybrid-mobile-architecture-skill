# Changelog

All notable changes to the hybrid-mobile-architecture skill.

## [1.0.0] — 2026-03-25

### Added
- `SKILL.md` — Primary skill instructions with 5-step workflow
- `plugin.json` — Claude Code plugin manifest with 8 commands
- `marketplace.json` — agentskills.io marketplace listing
- `references/arch-standard.md` — TJ-ARCH-MOB-001 decision table (condensed)
- `references/flutter/patterns.md` — Riverpod 2.6+, clean arch, shadcn_flutter, GoRouter, gen_ui_core FFI wiring
- `references/tauri/patterns.md` — Zustand 5, Prometheus Entity Management 3.x, TanStack Router/Table, IPC patterns, strict layer contract (the original Query recommendation was superseded in July 2026)
- `references/rust/patterns.md` — gen_ui_core module structure, UAR modes, FFI surface rules, model catalog
- `references/rust/new-block-type.md` — 7-step guide for adding ContentBlock variants (full stack)
- `references/auth/patterns.md` — Ory Kratos and Supabase integration for Flutter and React
- `scripts/check-env.sh` — Tool detection and installation (Rust, Flutter, Node, Tauri, cargo tools)
- `scripts/install-flutter.sh` — Flutter SDK installer (git clone or FVM)
- `scripts/scaffold-hybrid.sh` — Full hybrid project scaffold (Flutter + Tauri + Rust)
- `scripts/scaffold-flutter.sh` — Flutter app with Riverpod, clean arch, shadcn_flutter, build scripts
- `scripts/scaffold-tauri.sh` — Tauri + React 19 + Zustand + Prometheus Entity Management 3.x + TanStack Router/Table + shadcn/ui + feature architecture
- `scripts/scaffold-rust-core.sh` — gen_ui_core Rust crate with all module stubs
- `scripts/new-feature.sh` — Feature module scaffold (Flutter or Tauri/React)
- `scripts/add-auth.sh` — Supabase and/or Ory Kratos authentication integration
- `scripts/audit.sh` — TJ-ARCH-MOB-001 compliance checker (Flutter, Tauri, Rust)
- `docs/tj-arch-mob-001.html` — Full XHTML architectural standard document
- `assets/templates/` — Code templates for features, Rust core, ContentBlock variants

### Standards enforced
- Riverpod 2.6+ with `@riverpod` codegen (no manual providers)
- Zustand 5 + Prometheus Entity Management 3.x + TanStack Router/Table strict layer contract
- Feature-based clean architecture (data/domain/presentation)
- shadcn_flutter (Flutter) and shadcn/ui (React) component systems
- Ory Kratos + Supabase authentication patterns
- gen_ui_core Rust as invariant infrastructure substrate
- A2UI/AG-UI protocol pipeline with ContentBlock sealed union
- UAR embedded or external configuration
