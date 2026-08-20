# Phase: v0.2.0-hma-companion-skills

**Goal:** Implement the 6 new HMA v0.2.0 skills + the 4 supporting scripts that bridge the HMA to the prometheus-companion, so that the Companion can install and use them as a git-installable skill package.

**Why:** The Companion's Pillar 5 ("Connected Skill Packages") and Pillar 7 (the cross-cutting work) require the HMA to ship its end of the contract. Without these skills, the Companion has nothing to install from the HMA marketplace, the 4-condition install contract has no verifier, and the auto-skill-package-integration flow has nothing to watch.

**Done means:**
- [ ] All 6 new HMA skills exist at `skills/<name>/SKILL.md` and are mirrored to `.agents/`, `.claude/`, `.codex/`, `.kimi-code/`, `.opencode/`, and `templates/project-skills/`
- [ ] `plugin.json` `skills` array lists all 6 with the right version
- [ ] `scripts/verify-skill-manifest.sh` enforces the 4-condition install contract (valid marketplace.json, valid plugin.json, every SKILL.md exists + name matches folder, idempotent install)
- [ ] `scripts/install-hooks-reliability.sh` + `scripts/verify-hooks-reliability.sh` exist and pass when run against the current repo
- [ ] `scripts/render-supervisor-plist.sh` + the 9-fix plist + systemd template assets are in `assets/templates/launchagent-supervisor/`
- [ ] `scripts/scaffold-tauri-tray.sh` + the health-aggregator crate are runnable
- [ ] `scripts/refiner-loop.sh` (the 5-stage loop with a hard halt at Triage for human approval) is runnable
- [ ] `npm run validate:strict skills/...` passes for all 6 new skills
- [ ] The phase's `progress.json` is updated to `status: "complete"` with `changes_completed: 6`

**Non-goals (explicit):**
- The Companion itself — this phase ships the HMA end of the contract; the Companion consumes it in a separate phase in `prometheus-companion/`
- AetherLink-style Tauri mobile fallback — explicitly out of scope per the architecture review §14 (mobile is Flutter + Rust over FFI only)
- Plugin sandboxing — deferred to the Companion's Pillar 6 per the architecture review §14 #5
- The 5 deferred phases (`cross-platform-app-theming`, `phase-codegen-and-ci-verification`) — re-open them after this phase ships
