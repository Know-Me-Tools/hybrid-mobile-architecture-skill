# Tasks — c124-peer-profile-vault

- [ ] 1.1 gen_ui_types PrivacyClass + structural enqueue refusal of local-class rows in the write queue (fail closed) + tests
- [ ] 1.2 Desktop/web vault store: Loro doc (profile/preferences/agent_facts) persisted in PGlite _vault_state; VaultRepository facade
- [ ] 1.3 Peer sync protocol: version-vector exchange + export-updates-since deltas + 16KiB chunked frames over a duplex seam; WebRTC DataChannel adapter + dev signaler; in-memory duplex for tests
- [x] 1.4 Tests: two-peer convergence, chunk round-trip, persistence round-trip, Rust enqueue refusal
- [x] 1.5 Spec delta + validate (native webrtc-rs lane recorded as deferred follow-up)
