# Tasks — c122-partial-replication-slice

- [x] 1.1 Extend gen_ui_types::sync with SyncScope/ScopeKind descriptors (additive to the frozen seam)
- [ ] 1.2 Implement scope-aware dev loopback transport in gen_ui_db::sync (runs without the PES gateway)
- [x] 1.3 Lookup currency: _lookup_versions table + ETag/304 re-validation + version-bump handling
- [x] 1.4 Onboarding load stages: pre/post_onboarding_load typestate states + _load_ledger (idempotent)
- [x] 1.5 Propagate scope/lookup/ledger patterns into scripts/scaffold-rust-core.sh
- [x] 1.6 Behavior tests at seam boundaries + cargo clippy clean; spec delta; validate
