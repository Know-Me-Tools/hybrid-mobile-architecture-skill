## 1. Implementation

- [ ] 1.1 Add `scripts/test-consumer-install.sh` (path-isolated from the source tree)
- [ ] 1.2 Assert all 6 skills resolve via the registry, not by file existence
- [ ] 1.3 Assert the 4 install-contract conditions
- [ ] 1.4 Negative fixture: undeclared skill directory
- [ ] 1.5 Negative fixture: missing `plugin.json`
- [ ] 1.6 Negative fixture: manifest names a skill that does not resolve

## 2. Verification

- [ ] 2.1 Exits 0 against a fresh clone of HEAD
- [ ] 2.2 Each negative fixture exits non-zero AND its message names its own cause
- [ ] 2.3 The script never reads the source working tree (path isolation asserted)
