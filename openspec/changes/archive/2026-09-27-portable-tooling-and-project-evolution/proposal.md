# Portable tooling and continuous project evolution

## Why

The skill package executes first-party Bash and Python in consumer hooks, installers and generated build helpers. Windows compatibility is therefore incomplete. Several `runnable` profiles contain manifests rather than complete applications, and current adoption/upgrades do not implement continuous migration of evolving outputs.

## What Changes

- TypeScript 7-authored Node `.mjs` hooks and portable orchestration, with native Rust tools preferred for native generation, diagnostics and migrations.
- Explicit Windows x64/ARM64 Rust and native dependency support, without confusing target installation with runtime certification.
- OpenSpec all-tool initialization, Compass graph/MCP and a durable four-role project maintenance team.
- First-class greenfield, brownfield and versioned upgrade workflows that preserve user work and reject unsupported inputs before writes.
- Baseline web, desktop, Flutter/FFI and hybrid build/run contracts, followed by full/mini distribution proof.

## Impact

Live shell/Python entrypoints migrate to `.mjs` or native Rust commands; this is an intentional command-surface migration. Vendor build internals and immutable historic evidence are exempt from first-party conversion. Existing application data and user-owned files must not be replaced. Publication and unrelated product changes are outside this change.
