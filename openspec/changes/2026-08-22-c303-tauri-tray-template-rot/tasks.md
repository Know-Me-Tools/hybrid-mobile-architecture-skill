## 1. Implementation

- [ ] 1.1 DECIDE A or B; record the rationale in this change
- [ ] 1.2A Add `scripts/verify-tray-templates.sh` (render → clippy → teardown)
- [ ] 1.3A Wire into `audit.sh` as a named mode
- [ ] 1.4A Implement `toggle_pause` or document the stub
- [ ] 1.2B Delete `assets/templates/tauri-tray/`; remove render lines 87, 88, 91
- [ ] 1.3B Move the pattern into `skills/tauri-tray-app/SKILL.md`, marked illustrative
- [ ] 1.4B Update `docs/06-tauri-tray-app-spec.md` DoD

## 2. Verification

- [ ] 2.1 The 1.1 decision and rationale are recorded
- [ ] 2.2A NEGATIVE FIXTURE: the gate FAILS on a deliberately broken template
- [ ] 2.3B No file references the deleted templates; `generator-purity` passes
- [ ] 2.4 Either way: no artifact remains that claims to compile but is never compiled
