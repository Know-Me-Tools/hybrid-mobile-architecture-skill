# REFLECTION: v0.2.0-hma-companion-skills

Project: Hybrid Mobile Architecture Skill (TJ-ARCH-MOB-001 / KnowMe builder)
Date: 2026-08-20
Changes delivered: 6/6 implemented, verified locally, merged to `main`
Commits: e57d706 (c200) · 1191fde (c201) · c6e8ab2 (c202) · 1860b6d (c203) · 64a1317 (c204) · 4b18fdb (c205) · 81a2570 (phase close) · 3481d14 + 89e0a38 (spec corrections)

## Goal achievement

1. **Ship the 6 HMA-side skills**: **MET** — `connected-skill-packages`, `claude-hooks-reliability`, `launchagent-supervisor`, `tauri-tray-app`, `realtime-skill-refiner`, and `auto-skill-package-integration` exist at `skills/<name>/SKILL.md`, are declared in `builder.manifest.json` `skills[]` and `templates/activation-manifest.json`, and are mirrored to all six harness directories plus `templates/project-skills/` (6 skills × 7 targets verified). `check-skill-contracts.mjs` validates 36 skills and 108 eval cases.

2. **The 4-condition install contract verifier**: **MET** — `scripts/verify-skill-manifest.sh` checks the marketplace manifest, `plugin.json`, registry resolution (including rejecting undeclared skill directories), and condition 4's structural precondition. Validated against 13 negative fixtures, one per failure mode, not just the happy path.

3. **Hook-reliability install + verify**: **MET, with a caveat worth stating plainly** — the verifier checks 5 of the 9 fixes from config, and 3 more only when a hook runner exists; the installer auto-applies 3 (W6.9, W6.8, W6.3) and *reports* the other 6 rather than rewriting them, because each changes runtime behavior. Calling this "the 9 fixes applied" would overstate it. The honest framing: mechanically-applicable fixes are applied, the rest are surfaced as human-decision items. W6.7 (the `prom-hook-dispatch` binary) ships as guidance only.

4. **Supervisor templates + renderer**: **MET** — `render-supervisor-plist.sh` emits launchd plists (`plutil -lint` clean, verified by `plistlib` assertions on every fix key) and systemd `--user` units. `--throttle` below a 10s floor is refused rather than rendered, since that misconfiguration is the exact bug the template exists to prevent.

5. **Tauri tray scaffold + health-aggregator crate**: **MET** — the scaffolded crate compiles, passes 6/6 behavior tests and `clippy --all-targets -D warnings`. This is the only deliverable in the phase whose correctness was proven by execution rather than by inspection.

6. **The 5-stage refiner loop with a hard halt**: **MET** — `refiner-loop.sh` enforces the halt rather than documenting it: `--verify` and `--ship` both refuse an unapproved ticket, `--ship` refuses one that has not passed Verify, and approve-after-reject is refused. Verified the Verify gate actually fails on a deliberately broken frontmatter, so it is not a rubber stamp.

7. **Consumer smoke test**: **MET** — a fresh shallow clone runs `verify-skill-manifest.sh` to exit 0, exposes all 6 skills in the registry and mirrors, and runs every new script from the clone.

**Not delivered, by design**: the Companion-side items in specs 04/06/08 (Tauri commands, `bugTicket`/`skillSource` PEM entities, UI panels), spec 07's migration of the 7 existing PMP LaunchAgents (they live in `prometheus-skill-system`), and spec 03's `prom-hook-dispatch` binary. The first two match the phase's stated non-goals; the third is a scope judgment recorded in `progress.json → out_of_scope`.

## Artifact Quality Summary

| Metric | Value |
| --- | --- |
| Changes with QA | 6/6 (compensating verification; no artifact-refiner logs) |
| artifact-refiner runs | 0 — `.refiner/artifacts/` holds only `knowme-reference-ui` from a prior phase |
| First-pass pass rate | 2/6 — four of six deliverables failed their first real execution |
| Compensating verification | `check-skill-contracts.mjs`, `check-builder-authority.mjs --release`, `check-runtime-security.mjs`, `check-prometheus-boundary.mjs`, `sync-skill-resources.mjs --check`, `sync-harness-skills.sh --check`, `audit.sh doc-consistency` + `generator-purity`, `bash -n` + `shellcheck --severity=warning` across `scripts/`, `cargo test` + `cargo clippy -D warnings` on the scaffolded crate |
| Negative-path tests written | 13 (install contract) + 8 (refiner gates) + 4 (renderer guardrails) |
| Real defects caught before merge | 5 (see below) |

### Defects caught by verification, not review

- `verify-skill-manifest.sh` read the wrong marketplace file and failed on its own repo.
- `verify-hooks-reliability.sh` false-positived on `a11y-reminder.py` for printing its decision JSON to stdout — W6.5 forbids *diagnostics* on stdout, not the payload.
- `render-supervisor-plist.sh` rendered nothing on macOS: BSD `awk` rejects newlines in `-v` values, so multi-line blocks silently vanished.
- `install-hooks-reliability.sh` had an f-string backslash `SyntaxError` inside the heredoc.
- `refiner-loop.sh` exported `REFINER_ROOT` *after* the call that read it.

The first three would have shipped as working-looking code that fails on first real use. First-pass pass rate of 2/6 is the number worth carrying forward, not the final all-green state.

### Live defect found in this repo

`verify-hooks-reliability.sh` found a genuine W6.9 violation in `.claude/settings.json`: the `UserPromptSubmit` entry had no `matcher` — an unconditional hook that silently double-fires the moment a sibling is added. Fixed by the installer it was written to test.

## Technical debt introduced

- **6 of the 9 hook fixes are advisory**, not applied. W6.2/W6.4/W6.6 are checked only when a runner exists; nothing in this repo exercises that path, so those three checks are effectively untested.
- **`tray.rs` is never compiled.** The health-aggregator crate is tested; the tray template is inspection-only. It references `tauri` APIs verified against current docs, but a template that no build touches will rot silently — the exact failure class `sync-harness-skills.sh --check` exists to prevent for skills.
- **`toggle_pause` is an empty stub** in the tray template, with a comment where the aggregator wiring belongs.
- **No release tag.** `connected-skill-packages` tells consumers to pin tags because branch HEAD is unstable, and this repo publishes no tags. The guidance and the practice disagree.
- **`refiner-loop.sh`'s Verify does not replay the failing input** — it runs the repo's gates and checks for drift, but the ticket's `evidence` is never re-executed. The skill body says to replay it; the script cannot.
- **Blast-radius detection is lexical**, a bag-of-words overlap on descriptions with a hard-coded stopword list and a `>= 3` threshold. It surfaced a plausible neighbour on one probe; it has no evaluation behind it.
- **`assets/templates/tauri-tray/` is outside the purity allowlist review** — it passed `generator-purity` today, but nothing pins the tray templates into any future scan the way `sync-harness-skills.sh --check` pins skills.

## Lessons captured

- **The plan is a hypothesis; the repo is the spec.** Five of the plan's assumptions were false against this repo — `plugin.json` having a `skills` array, `npm run validate:strict` existing, `0.2.0` being a legal version, spec-authored frontmatter validating, and "5 mirrors" being 5. All five were discoverable in under ten minutes by reading `check-skill-contracts.mjs`, `check-builder-authority.mjs`, and `builder.manifest.json`. **Read the validators before writing anything they will judge.** This repeats the prior phase's lesson almost verbatim, which means the lesson did not stick the first time.

- **A spec that documents a contract can still be wrong about it.** Spec 01 §4 described the install contract in terms of a root `marketplace.json` with `plugins[]`. That file is a registry descriptor with a different shape; the harness manifest is `.claude-plugin/marketplace.json`. Writing the verifier *from the spec* produced a script that failed on its own repo. The spec's own §4 was the source of the bug it was meant to prevent — **when implementing a contract, verify each condition against the artifact it names before encoding it.**

- **BSD and GNU `awk` differ on newlines in `-v`.** Passing a multi-line block through `awk -v` silently produces `awk: newline in string` and no output on macOS. For multi-line template substitution, pass blocks through the environment to a `python3` filter instead. This is a portability class, not a one-off: the same shape appears anywhere a shell script templates a file.

- **A checker that only passes is not a checker.** `verify-skill-manifest.sh` passed its happy path while reading the wrong file; only the negative fixtures exposed it. Every gate this phase got a negative suite, and every negative suite found something. **Write the failing fixture before trusting the passing run.**

- **Distinguish a decision payload from diagnostics when checking stdout.** The W6.5 false positive came from treating any `print()` as a violation. A hook writing JSON to stdout is correct; a hook writing `WARN:` there is the bug. A grep-based checker needs that distinction encoded or it will train people to ignore it.

- **Generated trees make "did I ship it" answerable.** `builder.manifest.json` → generators → `git diff --exit-code` meant a skill that existed but was undeclared could not silently ship to nobody — the failure mode the mirror script's own comment records from an earlier phase. The tray template has no such backstop, which is why it is listed as debt above.

## Recommended Next Phase

**hma-companion-consumer-integration**: the producer side is done and unproven against a real consumer. (a) Have `prometheus-companion` actually install this package end to end — clone, `verify-skill-manifest.sh`, harness registration, "Connected Skill Packages" page — since the smoke test proved the repo's own scripts run from a clone, not that a consumer can use them. (b) Cut a `v2.0.0-alpha.3` tag, closing the gap between telling consumers to pin tags and publishing none. (c) Compile-check `tray.rs` in some CI-visible way, or delete it in favor of the skill body. (d) Decide W6.7 (`prom-hook-dispatch`): build it or drop it from the spec's DoD, rather than leaving it as permanent advisory text. (e) Give `refiner-loop.sh`'s Verify a real replay step, or amend the skill body to match what the script does.

## Sycophancy check

Self-check S-02/S-03/S-06 applied: goal 3 is explicitly qualified rather than claimed as "9 fixes applied", and the overstatement is named. The Artifact Quality table leads with a 2/6 first-pass rate and lists all five defects I introduced, rather than reporting only the final green state. Seven debt items are named, including two (`tray.rs` uncompiled, lexical blast radius) that weaken deliverables scored MET. The headline lesson records that this phase repeated the prior phase's lesson, rather than presenting it as a new insight. Out-of-scope items are listed as decisions with reasons, not omitted.
