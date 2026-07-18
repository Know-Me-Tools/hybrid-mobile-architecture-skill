# Tasks — c125-scaffold-audit-propagation

- [ ] 1.1 Propagate vault feature (5 TS files) + pgvector wiring + pglite-pgvector dep into scaffold-tauri.sh
- [x] 1.2 versions.toml [sync] pin block (loro-crdt, pglite, pglite-pgvector, pglite-sync fallback, sqlite-vec, flutter_webrtc)
- [x] 1.3 audit.sh gates: vault never a PEM entity/scope, declared-but-unused sync deps WARNING, vector surface present when chat feature present
- [x] 1.4 scaffold-flutter.sh mobile parity stubs (sqlite-vec + LocalStore notes on the bridge surface)
- [x] 1.5 Spec delta + validate; bash -n all touched scripts
