## Why

`connected-skill-packages` tells consumers to pin tags because branch HEAD is unstable,
and this repo publishes zero tags (`git tag -l | wc -l` → 0). B-1 and B-2 are live proof
that HEAD is exactly as unstable as the guidance claims, so the first tag must point at a
tree whose gates are green. `builder.manifest.json` already carries 2.0.0-alpha.3.

## What Changes

- Add `scripts/run-all-gates.sh` enumerating all ELEVEN local gates (the assessment's
  table listed 10 and omitted `check-git-url-discovery.sh`, which was red).
- Validate all SIX published manifests against the tagged version.
- Test a clean marketplace install from the tag, for both Claude and Codex.
- Tag `v2.0.0-alpha.3` and push.
- Record for reflect whether the phase should be renamed `hma-producer-stabilisation`.

## Impact

- Depends on c300, c301, c302, c303, c304 — LAST change in the phase.
- Changes published marketplace metadata (constraints.md WARNING).
- The only outward-facing act in the phase.
