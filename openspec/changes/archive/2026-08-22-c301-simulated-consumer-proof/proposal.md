## Why

The prior phase's smoke test proved this repo's scripts run from a clone — not that a
third party can register the package. The stated goal (have `prometheus-companion`
install it end to end) is NOT EXECUTABLE: the Companion is a 2-commit scaffold with 148
files, 3 Rust files, and zero references to this package. This change ships the
executable half; the cross-repo proof moves to the Companion's roadmap.

## What Changes

- Add `scripts/test-consumer-install.sh`: clone to a scratch dir, run
  `verify-skill-manifest.sh`, assert all 6 v0.2.0 skills resolve through the harness
  registry path a third party would use.
- Assert the 4 install-contract conditions from the clone's perspective.
- Add >=3 negative fixtures, each failing for its own stated reason.

## Impact

- Depends on c300 (green baseline).
- Does NOT demonstrate the Companion can consume the package — only that a generic
  consumer following the documented contract can. Reflection must keep that distinction.
