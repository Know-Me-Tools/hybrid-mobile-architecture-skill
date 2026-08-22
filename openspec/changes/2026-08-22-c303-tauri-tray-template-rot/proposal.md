## Why

There is no `tray.rs` and no `crates/` in this repo. The artifacts are
`assets/templates/tauri-tray/tray.rs.template` and
`assets/templates/tauri-tray/health-aggregator/` — both TEMPLATES. The prior phase's
'health-aggregator compiles, 6/6 tests, clippy clean' describes a one-time render during
that phase; nothing re-renders it now. This is one debt, not two: no gate re-renders
these templates, so both rot silently.

## What Changes

- DECIDE (blocks the rest): (A) add a render-and-build gate, or (B) delete the templates
  and keep the pattern as reference code in the skill body.
- (A) `scripts/verify-tray-templates.sh` renders both into a scratch project and runs
  `cargo clippy -D warnings`; wire into `audit.sh` as a named mode, not `all`.
- (A) Implement `toggle_pause` (`tray.rs.template:82-84` is an empty body) or document
  why the stub is correct scaffold output.
- (B) Delete `assets/templates/tauri-tray/`; remove ALL THREE render steps in
  `scaffold-tauri-tray.sh` (lines 87, 88, 91 — omitting 87 leaves a half-crate).

## Impact

- Depends on c300.
- Modifies `scripts/` and `assets/templates/` — downstream consumers (constraints.md).
- (B) removes a scaffold feature; that is a legitimate outcome, not a cop-out.
