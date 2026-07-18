# Tasks — c127-mobile-local-store-and-frb

- [x] 1.1 SqliteLocalStore implementing the frozen LocalStore seam (apply_batch/truncate_shape) over sqlx-sqlite, table allow-list, one txn per batch
- [ ] 1.2 gen_ui_ffi::api: attach_sync_scopes + run_one_time_loads (frb surface)
- [ ] 1.3 Tauri parity commands: attach_sync_scopes, run_one_time_loads (mirrors gen_ui_ffi signatures)
- [ ] 1.4 Behavior tests: SqliteLocalStore apply_batch/truncate_shape round-trip + table allow-list refusal
- [x] 1.5 cargo check/clippy clean; spec delta; openspec validate
