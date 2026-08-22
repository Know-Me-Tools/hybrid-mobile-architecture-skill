## Why

Two repo gates are red and no change in this phase can be verified against a failing
baseline. `check-skill-contracts.mjs` fails with 40 errors because an `openspec update`
to 1.10.0 stripped `metadata.internal: true` from the vendored mirrors — a repo-local
requirement the CLI has no notion of, so it will be stripped on every future run.
Separately, `check-git-url-discovery.sh` fails on clean HEAD with `expected 30 public
skills, found 36`. The user's decision (2026-08-22) is to adopt 1.10.0 rather than
re-pin, which is corroborated by the installed CLI already being 1.10.0.

## What Changes

- Bump `versions.toml:43` `openspec` 1.6.0 → 1.10.0.
- Decide `.codex`'s status: managed OpenSpec target, or dropped from the contract check.
  It is in no tool set today, so no command brings it to 1.10.0.
- Accept the `.kimi` → `.kimi-code` migration (the CLI prints `Migrated 10 skills`);
  do not restore `.kimi`.
- Add `scripts/normalize-vendored-skills.sh`, deriving the managed tool set from the
  OpenSpec config, to re-apply repo invariants after any `openspec update`.
- Replace `check-skill-contracts.mjs`'s union count check with a per-harness assertion
  encoding the non-uniform expected shape.
- Make `audit.sh` exit non-zero on an unrecognised mode.
- Fix `check-git-url-discovery.sh`'s stale hardcoded skill count.

## Impact

- BLOCKS: c301, c302, c303, c304, c305.
- Modifies `scripts/` — downstream projects consume these (constraints.md WARNING).
- Changes a pinned dependency version.
