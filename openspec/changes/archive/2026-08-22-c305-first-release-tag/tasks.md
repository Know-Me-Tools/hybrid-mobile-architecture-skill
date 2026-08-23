## 1. Implementation

- [x] 1.1 Add `scripts/run-all-gates.sh` enumerating all 11 gates; run it
- [x] 1.2 Validate all 6 manifests: `marketplace.json`, `plugin.json`, `.claude-plugin/marketplace.json`, `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`, `.agents/plugins/marketplace.json`
- [x] 1.3 Test a clean marketplace install from the tag (Claude and Codex)
- [x] 1.4 Tag `v2.0.0-alpha.3`; push the tag
- [x] 1.5 Clone at the tag and run `test-consumer-install.sh` from c301
- [x] 1.6 Record the phase-rename question for reflect

## 2. Verification

- [x] 2.1 `run-all-gates.sh` exits 0 at the tagged commit
- [x] 2.2 NEGATIVE FIXTURE: make one gate fail → `run-all-gates.sh` exits non-zero
- [x] 2.3 All 6 manifests carry 2.0.0-alpha.3 and validate
- [x] 2.4 Clean marketplace install from the tag succeeds for both harnesses
- [x] 2.5 `git tag -l` → `v2.0.0-alpha.3`, pushed
- [x] 2.6 A clone AT THE TAG passes `test-consumer-install.sh`
- [x] 2.7 No `.prometheus/` session-log changes left uncommitted
