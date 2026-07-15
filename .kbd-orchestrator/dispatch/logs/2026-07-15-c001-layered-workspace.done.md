# C-001 layered-workspace — DONE (claude/opus-4.8, in-session)

Files modified: scripts/scaffold-rust-core.sh (full rewrite), scripts/scaffold-hybrid.sh
(consume layered scaffold instead of inline single-crate manifest).

Emits a 12-crate layered workspace:
- L0 gen_ui_types (FROZEN seams: ContentBlock 11-variant, StreamEvent/A2uiEvent/AguiEvent,
  ViewDescriptor/FilterSpec/SortSpec, EntityTransport, SyncTransport, UarMode, CoreError)
- L1 gen_ui_runtime (native Tokio / wasm spawn_local), gen_ui_protocol (A2UI/AG-UI adapters)
- L2 gen_ui_client, gen_ui_mcp, gen_ui_db, gen_ui_inference (seam stubs for Wave-1 lanes)
- L3 gen_ui_agent
- LEAF gen_ui_ffi (frb), tauri-plugin-gen-ui, gen_ui_wasm
- workspace-hack (hakari pin)

Config: dev/release(panic=unwind — frb fix)/wasm-release(abort) profiles, dep opt-2,
build-override opt-3, line-tables-only + unpacked debuginfo; .cargo/config.toml (linker
notes), bacon.toml (clippy driver + cross-target check jobs), rust-toolchain.toml.

VERIFIED (gate):
- cargo metadata OK (12 crates)
- native clippy -D warnings CLEAN on gen_ui_types + gen_ui_runtime + gen_ui_protocol
- wasm32-unknown-unknown check PASSES for gen_ui_types + gen_ui_protocol (L0/L1
  wasm-safety proven, not just asserted)

DEVIATIONS from plan (findings surfaced by the check-first gate, all fixed):
1. MSRV bumped 1.80 -> 1.93: transitive deps (chacha20 >=0.10) now require the
   edition2024 Cargo feature, unparseable before Cargo 1.85. Updated rust-version +
   rust-toolchain.toml. **Follow-up: CLAUDE.md/AGENTS.md "Required tool versions" table
   still says Rust 1.80+ — C-008 should bump it to 1.93+.**
2. uuid v4 on wasm32 needs features=["js"] + getrandom "js" (E0433 otherwise) — added
   wasm-gated deps in gen_ui_types.
3. clippy derivable_impls: UarMode uses #[derive(Default)] + #[default] not manual impl.
