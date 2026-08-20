# Plan: v0.2.0-hma-companion-skills

## The 6 skills to ship

| # | Skill | Spec | Skill dir |
|---|---|---|---|
| 1 | `connected-skill-packages` | `docs/01-connected-skill-packages.md` | `skills/connected-skill-packages/` |
| 2 | `tauri-tray-app` | `docs/06-tauri-tray-app-spec.md` | `skills/tauri-tray-app/` |
| 3 | `launchagent-supervisor` | `docs/07-launchagent-supervisor-spec.md` | `skills/launchagent-supervisor/` |
| 4 | `realtime-skill-refiner` | `docs/04-skill-refiner-loop.md` | `skills/realtime-skill-refiner/` |
| 5 | `claude-hooks-reliability` | `docs/03-hooks-reliability.md` | `skills/claude-hooks-reliability/` |
| 6 | `auto-skill-package-integration` | `docs/08-auto-skill-package-integration.md` | `skills/auto-skill-package-integration/` |

## The 4 supporting scripts

| Script | Lives in | Consumer |
|---|---|---|
| `scripts/verify-skill-manifest.sh` | repo root | Companion's `doctor` command (cross-repo enforcer) |
| `scripts/install-hooks-reliability.sh` | repo root | Operators / Companion's setup flow |
| `scripts/verify-hooks-reliability.sh` | repo root | Companion's `doctor` command |
| `scripts/render-supervisor-plist.sh` | `assets/templates/launchagent-supervisor/` | Companion's launchd install path |

## Execution waves

### Wave 0 — c200 (scaffold + mirror)
1. Create `skills/<name>/SKILL.md` for each of the 6 skills (per its spec, kebab-case, with a `## Goal` + `## When to use` + `## Inputs` + `## Outputs` + `## Steps` structure)
2. Mirror each skill to the 5 per-harness directories using `scripts/add-project-skills.sh`
3. Update `plugin.json` `skills` array with the 6 new entries
4. Bump `plugin.json` `version` to `0.2.0`
5. Run `npm run validate:strict skills/<name>` for each of the 6 skills — must exit 0
6. Commit: `feat(skills): ship 6 new HMA v0.2.0 skills (connected-skill-packages, tauri-tray-app, launchagent-supervisor, realtime-skill-refiner, claude-hooks-reliability, auto-skill-package-integration)`

### Wave 1 — c201 + c202 + c203 (the install contract + the 9 fixes)
1. `c201` Write `scripts/verify-skill-manifest.sh` (the 4-condition contract)
2. `c202` Write `scripts/install-hooks-reliability.sh` and `scripts/verify-hooks-reliability.sh` (apply + inverse check the 9 hook fixes from the architecture review §6)
3. `c203` Write `scripts/render-supervisor-plist.sh` and the 9-fix plist + systemd template assets
4. Each script must: `bash -n` clean, exit 0/1, idempotent, runnable from a clean clone
5. Commit per change

### Wave 2 — c204 + c205 (the two scaffold/loop skills)
1. `c204` Write `scripts/scaffold-tauri-tray.sh` + the health-aggregator crate (generalizes the Companion's tray + popover + health aggregator)
2. `c205` Write `scripts/refiner-loop.sh` (5-stage Detect → Triage → Refine → Verify → Ship; **MUST HALT at Triage** for human approval)
3. Commit per change

## Cross-repo contract (consumer: prometheus-companion)

After this phase, the Companion can:
- `git clone https://github.com/Prometheus-AGS/hybrid-mobile-architecture-src /tmp/hma` (or use a local path)
- Run `verify-skill-manifest.sh` → exit 0 (the 4 conditions hold)
- See the 6 new skills in the "Connected Skill Packages" page's source list
- Use the `auto-skill-package-integration` flow to watch the HMA repo and install new skills as they ship
- The Companion's `doctor` command runs `verify-hooks-reliability.sh` against the HMA-installed hooks

## Verification gates (per change)

Each change closes only after:
- [ ] Local `bash -n` on any new scripts
- [ ] `npm run validate:strict` on any new/modified skills
- [ ] The change's spec is satisfied (each spec has its own Definition of Done)
- [ ] No GitHub Actions run (per `prometheus-skill-pack/AGENTS.md` local-only validation rule)
- [ ] `git commit` to main with a clear message
- [ ] `progress.json` updated: change status flipped, `changes_completed` incremented, `implementation_completed` reflects new total

## What this phase is NOT

- Not the Companion. The Companion consumes these skills from a separate phase in `prometheus-companion/`.
- Not the 5 deferred HMA phases (`cross-platform-app-theming`, `phase-codegen-and-ci-verification`). Those resume after this phase ships.
- Not the Tauri mobile fallback. Mobile is Flutter + Rust over FFI only.
- Not the plugin sandbox. That's Pillar 6 in the Companion.
