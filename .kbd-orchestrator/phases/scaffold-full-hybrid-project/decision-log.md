### 2026-07-15 — kbd-analyze verdicts
- ADOPT: PGlite 0.5.4 (web), pglite-oxide 0.5.1 (desktop ONLY — doc correction filed as C-9),
  SQLite+sqlite-vec (mobile), SurrealDB 3.2 embedded (graph RAG, all platforms),
  Electric shapes (read path), PEM 3.0.0-alpha.0 (React), Riverpod 3.3.2, fastembed-rs,
  flint-gate/forge/FRF via git deps consumed inside gen_ui_core.
- BUILD: prometheus_entity_management (Dart/Riverpod port, Rust-backed).
- CONTESTED (flagged, not silently picked): write-path sync — DIY-via-forge (80, recommended)
  vs PowerSync (72) vs PES-wave-1-now (55). Score gap < 15% between top two → user decision
  requested in analysis.md Open Questions #1. Provenance: research (4 parallel agents).
- CORRECTION: docs/pglite-oxide-tauri-hybrid.md claims (native binary; iOS/Android support)
  verified FALSE against crates.io/docs.rs → new change C-9.

### 2026-07-15 — Repo pulls (user-directed)
- flint-gate, flint-forge, prometheus-entity-management: pulled on main (all already current;
  flint-forge is 14 commits ahead of origin — local work, nothing to pull).
- flint-realtime-fabric: on feature branch sovereign-sfu-decode-proof with uncommitted work;
  local main fast-forwarded via fetch origin main:main WITHOUT merging the feature branch
  (mid-flight work — merge deferred to repo owner).

### 2026-07-15 — Contested stack choice RESOLVED
Options: DIY-write-queue-via-forge (80) vs PowerSync (72) | Score gap: ~10%
Decision: DIY via forge, with PES-compatible trait seams | Provenance: user (AskUserQuestion)
Also resolved: example scope = vertical slice (Chat + entity CRUD + memory/graph RAG + sync status), per user.
