<!-- TJ-ARCH-MOB-001 compliant -->
# C-002 spike artifacts

Throwaway probe crates from the wasm32 validation spike. **Not** part of the
scaffold output — they exist so C-004/C-007 can re-run the exact compile that
proved the target-safe shape. Findings are in
[`references/rust/wasm-targets.md`](../../../../references/rust/wasm-targets.md).

| File | Proves | Consumed by |
|---|---|---|
| `db_wasm_spike/` | SurrealDB 3.2 `kv-indxdb` + HNSW/FULLTEXT DDL + KNN query compile to wasm32; 3.x `.take()`/`Value` gotchas | **C-004** graph-RAG store |
| `gen_ui_wasm/spike_web.rs` | `fetch` + `EventSource` transport stubs compile on wasm32 (reqwest has no wasm backend) | **C-007** wasm leaf; **C-005** web sync path |
| `gen_ui_wasm/pglite_shim.js` | PGlite reachable only via wasm-bindgen `extern` over a JS shim | **C-007** wasm leaf |

## Reproduce

```bash
bash scripts/scaffold-rust-core.sh /tmp/spike-core
# copy db_wasm_spike/ into /tmp/spike-core/crates/ and add it to workspace members;
# copy spike_web.rs + js/pglite_shim.js into /tmp/spike-core/crates/gen_ui_wasm/
# (add web-sys/js-sys/wasm-bindgen-futures wasm-target deps + `mod spike_web;`)
rustup target add wasm32-unknown-unknown --toolchain 1.96
cargo +1.96 check --target wasm32-unknown-unknown -p db_wasm_spike -p gen_ui_wasm
```

**MSRV: ≥ 1.96** — SurrealDB 3.2 → `fastnum` requires rustc ≥ 1.94; the workspace
pin (1.93) fails to build it. See findings doc.
