# Goals

Seeded from local-first-realtime-sync/reflection.md → Recommended Next Phase.

- PEM sync bridge: implement `prometheusSyncTransport` bridging scope streams (local-store row changes) into PEM entity reactivity; honor the PEM ListQuery (filters/sorts/limit/cursor) in transports (retiring the pre-C-104 fetch-everything note); unify optimism on the one write queue (PEM pending actions read `_operation_queue` state — no parallel JS queue).
- Mobile tier for real: SQLite `LocalStore` implementation behind the existing seam; sqlite-vec `VectorStore` behind the same `VectorStore` trait (384-dim parity); frb surface for `attachSyncScopes` / `runOneTimeLoads` wired to gen_ui_core (un-stub the Dart bridge).
- Expose `RagEngine` to the UIs: FFI + Tauri commands with typed request/response, and wire chat-feature retrieval (desktop first) through the layer contract (component → hook → store → invoke).
- Vault pairing hardening: Ed25519 device roster stored in the doc, challenge over the DataChannel before deltas flow, revocation propagation (design already in references/sync/peer-crdt.md).
- Carry-forward (tracked, upstream-dependent — do not build here): PES gateway on FRF, FRF SyncService auth, SignalService production signaling swap.
