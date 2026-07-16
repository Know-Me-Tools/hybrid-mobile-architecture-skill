# C-101 bootstrap-pillars — DONE (claude/sonnet-5, in-session)

Rewrote scripts/check-env.sh into the four-pillar model (Rust+wasm+Prometheus-Skill-System,
OpenSpec, Flutter-beta+Dart-MCP, Node24+bun+pnpm+TypeScript-latest) with --install/--full
tiers. Fixed scripts/install-flutter.sh (was cloning --depth 1 -b stable, which cannot
switch channels; now clones -b beta non-shallow, unshallows existing shallow checkouts).
Updated CLAUDE.md/AGENTS.md "Required tool versions" tables to the pillar model.

## Live run on this box (the plan's "first test case")
- Before: frb-codegen 2.11.1, cargo-ndk missing, openspec 1.4.1, typescript 6.0.3
- `bash scripts/check-env.sh --install` remediated all four
- After: frb-codegen 2.12.0, cargo-ndk installed, openspec 1.6.0, typescript 7.0.2
- Final: exit 0, "All four pillars present and operational"

## Bug found and fixed during verification
`check_cargo_tool()`'s version probe ran `cargo-ndk --version` directly, but cargo-ndk
refuses direct invocation ("This binary may only be called via `cargo ndk`") and exits 1
— under `set -e` this silently killed the whole script mid-run. Guarded the command
substitution with `|| have=""`. Also hardened three other grep-based version extractions
(openspec/flutter-channel/typescript) against the same class of failure (grep no-match
exits 1). Also fixed the summary re-check: originally reported items as still-outstanding
even after --install fixed them (used the pre-install $MISSING snapshot) — added a
post-remediation re-check block.

## Verified
- `bash -n` clean on both scripts.
- Full `--install` run: exit 0, all 4 pillars green, targets (wasm32 + iOS + Android)
  present, Prometheus Skill System operational (pk doctor passes), docker present.
- Flutter is on beta (3.45.0-0.1.pre) — did not run --full (flutter upgrade) since this
  box's beta is functional and current-enough for the PoC; deferred to avoid the
  multi-GB/multi-minute operation mid-plan. dart mcp-server confirmed operational.
