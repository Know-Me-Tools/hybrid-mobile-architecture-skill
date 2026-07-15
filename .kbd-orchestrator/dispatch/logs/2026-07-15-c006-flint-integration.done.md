# C-006 flint-integration — DONE (claude-code / sonnet-5, in-session)

**Change:** `2026-07-15-c006-flint-integration` (Lane C). Replaces the two C-001
`gen_ui_client` / `gen_ui_mcp` L2 seam stubs with the real Flint platform integration
layer, emitted by `scripts/scaffold-rust-core.sh` (same heredoc-template pattern C-001
established). All emitted files begin with `// TJ-ARCH-MOB-001 compliant`.

## Files modified
- `scripts/scaffold-rust-core.sh` (only tracked change): added workspace FRF git-dep
  block (commented — see deviation 1) + `jsonwebtoken`; new emitter functions
  `emit_flint_mcp`, `emit_flint_client`, `emit_flint_token/_gate/_forge/_frf/_mod/_tests`;
  replaced the `emit_l2_stub gen_ui_client|gen_ui_mcp` calls; updated header/banner.

## Files the scaffold now emits (11, all marker-carrying)
- `gen_ui_mcp/`: `lib.rs`, `jsonrpc.rs` (JSON-RPC 2.0 envelopes), `registry.rs`
  (`McpRegistry` + `McpTransport` trait + `McpServerHandle` w/ tool cache),
  `sse_transport.rs` (HTTP+SSE `SseTransport`, native-only).
- `gen_ui_client/src/lib.rs` + `flint/`: `token.rs` (Role ladder, `Claims` mirroring
  `forge-identity::Claims`, `AuthState` lifecycle machine), `gate.rs` (anon-key boot,
  Kratos `/sessions/whoami` exchange, Cedar approval polling), `forge.rs` (Quarry
  `EntityTransport` over PostgREST `/<schema>/<table>`, `/mcp/v1/a2ui` MCP registration,
  AG-UI→A2UI/ContentBlock mapping), `frf.rs` (Spine façade + peer-crdt re-exports,
  feature-gated), `mod.rs` (`FlintClient` façade + shared auth), `tests/it.rs`.

## Design driven by VERIFIED contracts (Kimi-sublane role: digested the 3 real repos)
Read flint-gate/forge/FRF sources directly. Contracts saved to memory
`flint-platform-api-contracts.md`. Corrections vs the proposal's assumptions:
- **No anon-token HTTP endpoint** — `FLINT_ANON_KEY` is a static pre-shared Bearer JWT
  → `boot_anon()` just parses/holds it.
- **No JWT mint/refresh endpoint** — gate mints per-request; refresh = re-auth. Kratos
  handoff = gate proxies `GET /sessions/whoami` with the `ory_kratos_session` cookie.
- **`act`/`agent_id`/`workflow_id`/`principal_type` are NOT typed** in the platform —
  only `sub`/`role`/`tenant_id` are first-class; the rest ride an untyped `extra` map,
  so `Claims` mirrors that exactly (typing them would be a fiction that drifts).
- **No `isApprovalRequired` field** — HITL surfaces via gate admin `/approvals/:id`
  `decision` (null=pending) → modeled as a poll (`ApprovalStatus::is_pending`).
- **Quarry paths** = `/<schema>/<table>` (PostgREST), forge on `:8080`, RLS via Bearer
  JWT only (no `X-Tenant`).
- **FRF** = tonic gRPC (native-only); `frf-sdk-rust::FrfClient`, `frf-crdt`,
  `frf-store-redb` are private path-dep crates — API verified by compiling the `frf`/
  `peer-crdt` feature against the local checkout at the pinned HEAD.

## Verification (all green)
- `cargo metadata` OK (12 crates).
- `cargo clippy -p gen_ui_mcp -p gen_ui_client --all-targets -- -D warnings` clean
  (default features).
- `cargo check --target wasm32-unknown-unknown` clean for both crates — token/registry
  are cross-target; reqwest/tonic IO planes are `cfg(not(wasm32))`-gated (wasm reqwest
  `Response` is `!Send`, incompatible with the frozen `EntityTransport: Send` seam; the
  browser reaches these planes from JS per the layer contract / analysis §1.7).
- `cargo clippy -p gen_ui_client --features peer-crdt -- -D warnings` clean **against the
  real FRF crates** (local checkout, pinned HEAD `9ba04ae`).
- 5 boundary tests pass (`tests/it.rs`, no network/mocks): JWT role/tenant/extra decode,
  anon coercion, `AuthState` bearer+refresh transitions, AG-UI text→ContentBlock::Text,
  AG-UI run/toolcall→A2UI + keepalive/unknown-frame tolerance.

## Deviations / blockers
1. **FRF git deps left COMMENTED in the template** (like C-001's `tauri`): the FRF
   crates are private + unpublished (`prometheusags/flint-realtime-fabric`, all path
   deps), so a fresh scaffold on a machine without repo access must still resolve the
   default. The `frf`/`peer-crdt` feature FLAGS are declared (so `cfg(feature="frf")`
   is a known cfg and the offline build is clippy-clean) but activate no deps until a
   downstream project uncomments the workspace deps + optional-dep block and points them
   at its vendored checkout. Pinned SHAs recorded inline + in memory. Flag to Flint
   owners: publishing cadence (analysis Open Question 5).
2. **`gen_ui_types` seams untouched** (frozen after C-001). `forge.rs` implements the
   existing `EntityTransport`; `frf.rs` reports the existing `SyncStatus`. No seam edits.
3. AG-UI mapping covers the streaming-ContentBlock subset (text/toolcall/run lifecycle);
   state-delta/custom-surface events are left for the A2UI surface layer (C-011) — noted
   in-code, not silently dropped.
