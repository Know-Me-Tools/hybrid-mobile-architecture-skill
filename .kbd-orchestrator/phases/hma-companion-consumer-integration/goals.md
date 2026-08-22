# Goals

Phase: `hma-companion-consumer-integration`
Previous phase: `v0.2.0-hma-companion-skills` (6/6 changes merged, reflected `e76c29b`)
Created: 2026-08-22

## Framing

Two input streams feed this phase, and they are **not** equally live:

1. **`docs/assessment-2026-07-16.md`** (July 2026 independent deep assessment,
   8 prioritized recommendations). Several of its recommendations appear to have
   been acted on since — `versions.toml` exists, `CLAUDE.md` now routes mobile to
   SQLite + sqlite-vec (rec #1), and `audit.sh` has a `doc-consistency` mode
   (rec #2). **Do not treat this document as an open work list.** Its
   recommendations must be re-verified against the current tree during
   `/kbd-assess`; only the genuinely-still-open ones become goals here.

2. **`docs/0[1-8]-*.md`** (2026-08-20 companion specs). These were the *input* to
   the prior phase, and their HMA-side deliverables are **already shipped**. What
   remains from them is the residual the prior phase's `reflection.md` names
   explicitly: consumer-side proof, an unpublished tag, uncompiled `tray.rs`,
   an undecided W6.7, and a Verify stage that does not do what its skill body says.

The phase's own reflection recommends `hma-companion-consumer-integration`, and
that is the name adopted here. The producer side is done and **unproven against a
real consumer**.

## Goals (candidate — subject to `/kbd-assess` adversarial review)

1. **Prove the install contract from the consumer side.** Have
   `prometheus-companion` install this package end to end: clone,
   `verify-skill-manifest.sh`, harness registration, "Connected Skill Packages"
   page. The prior phase's smoke test proved this repo's scripts run *from a
   clone*, not that a consumer can consume them.

2. **Close the pin-a-tag contradiction.** `connected-skill-packages` instructs
   consumers to pin tags because branch HEAD is unstable; this repo publishes no
   tags. Cut `v2.0.0-alpha.3` (the version already in `builder.manifest.json`) or
   amend the guidance.

3. **Resolve `tray.rs`.** It is never compiled — a template no build touches will
   rot silently. Either compile-check it locally or delete it in favor of the
   skill body. `toggle_pause` is an empty stub.

4. **Decide W6.7 (`prom-hook-dispatch`).** Build it or drop it from spec 03's
   Definition of Done. It currently ships as permanent advisory text.

5. **Make `refiner-loop.sh`'s Verify honest.** It runs repo gates and checks for
   drift but never replays the ticket's `evidence`, which the skill body says it
   does. Give it a real replay step or amend the body.

6. **Re-verify the 2026-07-16 assessment against HEAD** and convert only the
   still-open recommendations into scoped work. Explicitly record which are
   already closed, with the evidence, rather than silently dropping them.

## Non-goals (pending assessment)

- Re-litigating the six binding architectural commitments from
  `docs/05.1-phase-v0.2.0-launch-prompt.md` (Tauri = desktop only; no Capacitor;
  in-house skill router; sandbox deferred to Pillar 6; git-installable HMA;
  substrate as in-process library + `--detach`).
- Companion-side items owned by `prometheus-companion` or
  `prometheus-skill-system` repos, except where this repo must publish a
  contract for them.

## Method (binding for this phase)

- `/kbd-assess` runs **with adversarial review** (`adversarial-review` skill) and
  the **sycophancy-correction** skill applied to every evaluative claim.
- Verify each assessment recommendation against the artifact it names before
  encoding it as work — the prior phase's own lesson: *"a spec that documents a
  contract can still be wrong about it."*
- Local-only validation. No GitHub Actions.
- `AGENT_BASE_RULES.md` (all 40 rules) applies.
