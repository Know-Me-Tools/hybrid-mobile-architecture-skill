EXECUTION: pem-sync-bridge-and-mobile-tier
Project: Hybrid Mobile Architecture Skill (TJ-ARCH-MOB-001 / KnowMe builder)
Date: 2026-07-18
Selected backend: openspec
Dispatched to: SELF (Claude Code, claude-sonnet-5)
Backend rationale: OpenSpec directory exists; five changes with round dependencies need spec-backed traceability. Same pattern as local-first-realtime-sync. Task execution routed through /kbd-apply — never bare /opsx:apply.
Backend entrypoint: /kbd-apply against openspec/changes/c12[6-9]-*, c130-*, one task at a time
OpenSpec available: YES
Source plan: .kbd-orchestrator/phases/pem-sync-bridge-and-mobile-tier/plan.md

EXECUTION SCOPE

- c126-pem-scope-bridge: app-side PEM scope bridge (Round 1)
- c127-mobile-local-store-and-frb: mobile SQLite lane + frb surface (Round 1)
- c128-sqlite-vec-vector-store: mobile vector tier (Round 2, depends c127)
- c129-rag-ipc-and-chat-wiring: RagEngine IPC + chat chips (Round 2)
- c130-vault-roster-auth: Ed25519 pairing hardening (Round 3)

DISPATCH CONTRACTS

- c126 → SELF. Entry: /kbd-apply c126-pem-scope-bridge. Model class: frontier. Concrete model: claude-sonnet-5 (session model). Rationale: new abstraction (live-extension bridge) across PEM's public surface.
- c127 → SELF. Entry: /kbd-apply c127-mobile-local-store-and-frb. Model class: frontier. Rationale: new SQLite seam implementation + FFI/Tauri parity surface, cross-language.
- c128 → SELF. Entry: /kbd-apply c128-sqlite-vec-vector-store. Model class: medium. Rationale: pattern-follows PgVectorStore behind the same trait.
- c129 → SELF. Entry: /kbd-apply c129-rag-ipc-and-chat-wiring. Model class: medium. Rationale: bounded IPC + minimal UI wiring.
- c130 → SELF. Entry: /kbd-apply c130-vault-roster-auth. Model class: frontier. Rationale: greenfield auth protocol addition to an existing greenfield transport.

APPROVAL GATES

- NONE within the phase.

FALLBACK CONDITIONS

- frb codegen unavailable in-session: land Rust/Tauri side complete; note the Dart regen as a follow-up task rather than skipping silently (plan.md trade-off).
- PGlite `live` extension misbehaves under the Tauri webview: fall back to plugin-event-driven invalidation at the same bridge seam (plan.md risk).

VERIFICATION REQUIREMENTS

- Rust: cargo clippy -- -D warnings (workspace, --exclude gen_ui_ffi absent codegen); cargo check --workspace; cargo check --target wasm32-unknown-unknown -p gen_ui_wasm
- Desktop TS: npx tsc --noEmit; npm test -- --run; npx eslint src/
- audit.sh tauri clean

PROGRESS LEDGER

- [DONE] c126-pem-scope-bridge — SELF (archived 2026-07-18)
- [DONE] c127-mobile-local-store-and-frb — SELF (archived 2026-07-18; design corrected mid-flight, see progress.json)
- [DONE] c128-sqlite-vec-vector-store — SELF (archived 2026-07-18; design corrected, see progress.json)
- [PENDING] c129-rag-ipc-and-chat-wiring — SELF
- [DONE] c130-vault-roster-auth — SELF (archived 2026-07-18)

OUTPUTS

- App-side sync bridge module (desktop); SqliteLocalStore + frb surface (mobile); SqliteVecStore; rag_retrieve IPC + chat recall UI; vault roster/challenge/revocation

BLOCKERS

- NONE at dispatch.

REFLECTION HANDOFF

- Per-change verification results; frb codegen status; PR #14 merge state after this phase's commits land.

EXECUTION READY
