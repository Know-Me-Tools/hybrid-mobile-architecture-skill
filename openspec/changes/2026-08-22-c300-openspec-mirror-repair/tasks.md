## 1. Implementation

- [x] 1.1 Bump `versions.toml:43` to 1.10.0 with rationale comment
- [x] 1.2 DECIDE `.codex`: manage via `openspec init --tools codex`, or drop from the harness list
- [x] 1.3 Apply the 1.2 decision
- [x] 1.4 `git rm` the 10 `.kimi/skills/openspec-*` dirs; remove `.kimi` from `check-skill-contracts.mjs:93`
- [x] 1.5 Re-apply `internal: true` across every still-managed harness
- [x] 1.6 Add `scripts/normalize-vendored-skills.sh` (idempotent; tool set from OpenSpec config)
- [x] 1.7 Replace the union count with a per-harness assertion (.agents = 10+10; others = 10+0)
- [x] 1.8 Make `audit.sh` reject unknown modes
- [x] 1.9 Fix `check-git-url-discovery.sh` stale count (B-2)
- [x] 1.10 Document `openspec update` → normalize in CLAUDE.md

## 2. Verification

- [x] 2.1 `check-skill-contracts.mjs` exits 0 on the working tree
- [x] 2.2 `check-git-url-discovery.sh` exits 0
- [x] 2.3 `audit.sh zzznonsense` exits NON-ZERO
- [x] 2.4 NEGATIVE FIXTURE: delete a managed harness's openspec dirs → gate fails naming it
- [x] 2.5 NEGATIVE FIXTURE: strip `internal: true` from one mirror → gate fails naming the file
- [x] 2.6 IDEMPOTENCE: `openspec update --force && normalize-vendored-skills.sh` green; second run `git diff --exit-code` clean
- [x] 2.7 `.kimi` openspec dirs = 0, `.kimi-code` = 10
- [x] 2.8 `audit.sh doc-consistency` still passes with the bumped pin
