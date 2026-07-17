---
type: Reference
id: flint-forge-p15-production-readiness-pgrx-test-fixes
title: Flint Forge p15 production readiness pgrx test fixes
tags:
- flint-forge
- production-readiness
- pgrx
- postgres-18
- rust-tests
- migration-integrity
sources:
- stdin
- manual:Flint Forge/p15-v1.0-production-readiness
timestamp: 2026-07-16T23:09:05.271070+00:00
created_at: 2026-07-16T23:09:05.271070+00:00
updated_at: 2026-07-16T23:09:05.271070+00:00
revision: 0
---

## Context

- **Project:** Flint Forge
- **Phase:** `p15-v1.0-production-readiness`
- **KBD root:** `$HOME/Projects/prometheus/flint-forge/.claude/worktrees/hungry-poitras-a3e04c`
- **Captured:** `2026-07-16T23:07:03Z`
- **Phase source:** `manual:Flint Forge/p15-v1.0-production-readiness`

## Phase intent

Close the gap between a workspace that compiles and passes unit tests and a production-ready Flint Forge v1.0. Scope is limited to build integrity, operator tooling, end-to-end validation, documentation accuracy, and production packaging; no new features.

Seeded from user directive plus `p14-v1.1.0/reflection.md`.

## Planned P0 production blockers

### `p15-c001` — Anvil Extension Stabilization

Make all five `ext-flint-*` / `flint_*` pgrx extensions compile and pass `cargo pgrx test` on one supported toolchain.

Required work:

- Unify pgrx version and Postgres target.
- Fix `DatumWithOid` compile error in `ext-flint-meta`.
- Resolve workspace-inheritance misconfiguration for excluded crates.
- Add pgrx CI job in a Linux container.
- Gate: `cargo pgrx test` passes for all extensions in CI.

### `p15-c002` — Migration Integrity

Restore strict linear migration ordering and verify migrations in CI.

Required work:

- Renumber colliding `migrations/0005_*` and `migrations/0006_*` files.
- Add CI step that runs `sqlx migrate run` against an empty Postgres 18 DB.

## Completed commits

1. `fa84853`
   - Commits `.cargo/config.toml` with a default `CARGO_PGRX_TEST_PGDATA` value.
   - Ensures git-worktree checkouts get a short `/tmp` Postgres socket path by default.
   - Removes need for manual local setup of `CARGO_PGRX_TEST_PGDATA`.
   - Adjusts ignore handling so `.cargo/config.toml` is tracked.

2. `b19defc`
   - Fixes `crates/ext-flint-vault/src/lib.rs:544`.
   - Updates the negative-path pgrx test for `vault.resolve_api_key`.
   - The test now catches the function's `RAISE EXCEPTION` inside a PL/pgSQL `EXCEPTION` block.
   - Previous behavior incorrectly expected the exception to surface as a Rust `Err`, which aborted the entire `#[pg_test]` transaction.

## Verification

Executed successfully:

```bash
cd crates/ext-flint-vault
unset CARGO_PGRX_TEST_PGDATA
cargo pgrx test pg18
```

Passing tests:

- `pg_secret_roundtrip_general`
- `pg_api_key_roundtrip_by_provider`

The successful run relied only on the committed `.cargo/config.toml` default for `CARGO_PGRX_TEST_PGDATA`, validating that a fresh worktree has the required short `/tmp` socket path without manual environment setup.

## Deliberately left unchanged

- Existing `cargo fmt` drift on unrelated lines in `crates/ext-flint-vault/src/lib.rs`; confirmed present on the base commit.
- Modified/untracked `.prometheus/` state files in `git status`; unrelated to the pgrx test/tooling fix.

## Status

- Both fixes are committed and verified.
- No remaining follow-up for this reported environment/tooling gap.

# Citations

1. stdin
2. manual:Flint Forge/p15-v1.0-production-readiness
