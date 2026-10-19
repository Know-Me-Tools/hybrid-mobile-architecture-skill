# Tasks — 2026-07-15-c110-ci

- [x] T1 — `.github/workflows/knowme-poc-ci.yml`: Rust clippy + test job.
- [x] T2 — `audit.sh all` job (TJ-ARCH-MOB-001 compliance gate).
- [x] T3 — Desktop Vitest + `tsc --noEmit` job.
- [x] T4 — Mobile `dart analyze` job (post-codegen).
- [x] T5 — Combined build job: `tauri build --no-bundle` +
      `flutter build ios --simulator --no-codesign`.
- [x] T6 — `versions.toml` single-source-of-truth for tool/stack version pins.
- [x] T7 — Verified: YAML parses clean; `cargo clippy --workspace --all-targets`
      and `bash scripts/audit.sh all ./apps/knowme-poc` both pass with zero
      violations/warnings against the current tree.
