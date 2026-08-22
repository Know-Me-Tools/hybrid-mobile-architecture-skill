## 1. Implementation

- [x] 1.1 Add `scripts/test-consumer-install.sh` (path-isolated from the source tree)
- [x] 1.2 Assert all 6 skills resolve via the registry, not by file existence
- [x] 1.3 Assert the 4 install-contract conditions
- [x] 1.4 Negative fixture: undeclared skill directory
- [x] 1.5 Negative fixture: missing `plugin.json`
- [x] 1.6 Negative fixture: manifest names a skill that does not resolve

## 2. Verification

- [x] 2.1 Exits 0 against a fresh clone of HEAD
- [x] 2.2 Each negative fixture exits non-zero AND its message names its own cause
- [x] 2.3 The script never reads the source working tree (path isolation asserted)
