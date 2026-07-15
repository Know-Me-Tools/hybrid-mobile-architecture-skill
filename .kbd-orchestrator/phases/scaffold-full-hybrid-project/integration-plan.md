# gen_ui workspace integration plan (Wave-1 code lanes)

All 5 code lanes patched scripts/scaffold-rust-core.sh from base 88d2eb4. They collide at
ONE anchor region (~line 617-632: the `emit_l2_stub gen_ui_db|gen_ui_client|gen_ui_mcp`
calls) plus additive workspace-dependency blocks (~line 78-88, disjoint, no conflict).

## What each lane replaces (compatible once separated):
- C-003: replaces `emit_l2_stub gen_ui_db` → gen_ui_db/src/relational/* + migrations + tests
- C-005: replaces `emit_l2_stub gen_ui_db` → wraps in emit_gen_ui_db() with sync/ module
         ⚠ C-003 & C-005 BOTH rewrite gen_ui_db → MERGE their lib.rs (pub mod relational; +
         pub mod sync;) and Cargo.toml (union of deps) by hand.
- C-004: adds a SEPARATE crate gen_ui_db_graph (new workspace member) + updates the
         gen_ui_db stub comment. No conflict with C-003/C-005's gen_ui_db.
- C-006: replaces `emit_l2_stub gen_ui_client` AND `emit_l2_stub gen_ui_mcp` → flint client
         + MCP registry. Disjoint from the gen_ui_db lanes.
- C-007: workspace deps (tauri, wasm-bindgen) + gen_ui_ffi/tauri-plugin/gen_ui_wasm leaf
         bodies. (Re-dispatched on claude; awaiting.)

## Integration order (on branch integrate/wave-1):
1. Apply C-006 (client+mcp) — cleanest, disjoint anchor. git apply --3way.
2. Apply C-004 (adds gen_ui_db_graph member + emitter). Mostly additive.
3. Hand-merge C-003 + C-005 into ONE gen_ui_db emitter: relational/ + sync/ modules,
   unioned lib.rs mod decls + Cargo.toml deps + migrations + combined tests/it.rs.
4. Apply C-007 leaves once it lands.
5. Run scaffold into scratch; `cargo +1.93 check` whole workspace; clippy -D warnings on
   changed crates; re-verify C-004 graph tests (were UNCONFIRMED). Fix MSRV to ≥1.94 if
   C-004's surrealdb 3.2 needs it (C-004 flagged this).
6. Commit to main as one "feat: gen_ui workspace crates (C-003..C-007)" or per-lane commits.

## Deviation carried: SurrealDB 3.2 may push MSRV 1.93→1.94 (C-004 finding) — verify in step 5.
