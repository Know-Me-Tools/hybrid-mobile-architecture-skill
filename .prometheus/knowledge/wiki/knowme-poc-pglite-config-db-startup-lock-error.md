---
type: Reference
id: knowme-poc-pglite-config-db-startup-lock-error
title: KnowMe PoC PGlite config DB startup lock error
tags:
- knowme-poc
- tauri
- pglite
- startup-error
- config-db
- hybrid-mobile-architecture
links:
- knowme-poc-codegen-and-ci-verification-phase-goals
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T08:28:52.991256+00:00
created_at: 2026-07-16T08:28:52.991256+00:00
updated_at: 2026-07-16T08:28:52.991256+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-16T08:26:16Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `executing`

The session occurred during the PoC-first codegen/CI phase for the KnowMe app. The phase deliverable remains a working proof-of-concept app under `apps/<name>/`, with codegen and CI verification as supporting objectives; see [KnowMe PoC codegen and CI verification phase goals](/knowme-poc-codegen-and-ci-verification-phase-goals.md).

## Observed error

The KnowMe Tauri desktop app hit a startup error:

```text
embedded PGlite server failed: PGlite root is already in use:
~/Library/Application Support/ai.prometheusags.knowme-poc/config-db
```

This was treated as an explanation-only request; no code changes were made.

## Cause

`pglite-oxide`, the embedded PostgreSQL-compatible database used for the app's config DB, locks its data directory when it starts. The lock behavior is analogous to a normal PostgreSQL server taking a data-directory lock.

The error means another process or stale state already holds or appears to hold the lock for:

```text
~/Library/Application Support/ai.prometheusags.knowme-poc/config-db
```

Likely causes:

1. **Another app instance is still running**
   - A previous Tauri launch may still be alive in the background.
   - A zombie/background process from a crashed run may not have released the PGlite server lock.
2. **Unclean previous shutdown left a stale lock**
   - PGlite/Postgres-style engines create a `postmaster.pid`-equivalent lock marker in the data directory.
   - If the app was killed instead of shut down cleanly, the lock marker can remain even when no process is active.
3. **Multiple dev builds share the same config DB path**
   - A development build and a previously launched build may both point to the same on-disk `config-db` path.
   - This is plausible during active PoC development, especially when desktop source files are being changed and relaunched frequently.

## Severity and interpretation

The app classified the error as:

```text
transient (retryable)
```

That classification indicates the condition is expected to be contention/locking rather than database corruption or a fatal startup defect. It should clear after the conflicting process exits or the stale lock is removed.

## Operational response

Recommended manual checks before treating this as a code issue:

- Ensure no other KnowMe/Tauri app instance is running.
- Kill any stale/zombie desktop app process from previous launches.
- If no process is using the DB path, remove stale lock state from the `config-db` directory only after confirming no live process owns it.
- Relaunch the app.

Potential follow-up, if requested: inspect `apps/knowme-poc/desktop/src-tauri/src/lib.rs` to verify whether PGlite startup already implements retry/recovery behavior for lock contention.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
