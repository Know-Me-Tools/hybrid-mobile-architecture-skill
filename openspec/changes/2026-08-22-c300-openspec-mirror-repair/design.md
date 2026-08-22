# Design decisions — c300

## D-1 · Adopt OpenSpec 1.10.0 rather than re-pin to 1.6.0

**Decided by:** user, 2026-08-22 (phase-level fork)

Four options were on the table: re-pin to 1.6.0, adopt 1.10.0, exclude vendored
trees from the contract check, or make mirror generation repo-owned.

**Adopt 1.10.0**, corroborated by evidence found during planning: the installed
CLI is *already* 1.10.0. The `versions.toml` pin of 1.6.0 was stale relative to
the tool in daily use, so adopting reconciles the pin with reality rather than
forcing the tool backwards. Re-pinning would additionally require regenerating
`.kimi/` from directories that no longer exist.

Adoption alone does not stop recurrence — see D-3.

## D-2 · `.codex` becomes a managed OpenSpec target, and therefore stops holding its own mirrors

**Decided by:** user, 2026-08-22 (task 1.2)

`.codex/` was the only harness `openspec update` never touched, leaving it
stranded at 1.6.0 while the others moved to 1.10.0. Two options:

| Option | Outcome |
|---|---|
| **Manage it** (chosen) | `openspec init --tools codex` adds it to the managed set |
| Drop from the gate | Cheaper, but leaves a live harness unvalidated and permanently version-split |

Evidence that `.codex` is live, not abandoned: 45 skills present; declared in
`project.json` `agents_config.codex`; listed in `sync-harness-skills.sh:32`
`HARNESS_DIRS`; and `codex` is a supported OpenSpec tool.

### What managing it actually produced — and why `.codex` is *not* in the gate's table

This is the part the first draft of this document got wrong, and an adversarial
review caught it. "Manage it" and "`.codex` appears in `INTERNAL_SKILL_HARNESSES`"
are **not** the same thing, and assuming they were made the decision record
contradict the shipped code.

Running `openspec init --tools codex` wrote `codex` into
`.agents/skills/.openspec-target` (now tracked), and `openspec update` then
reports `Updating Codex`. Codex **is** managed. But the CLI's own output
explains what managing Codex means:

```
✔ Updated Codex
Left 10 files in .codex/ that differ from the copy in .agents/. Nothing was
overwritten — compare the two and delete the .codex/ copy once you have kept
anything you customized.
```

Codex reads shared skills from `.agents/` — exactly as `project.json` already
declared (`agents_config.codex.skill_dir: .agents/skills`). The 10
`.codex/skills/openspec-*` directories were **stale 1.6.0 duplicates** of files
whose canonical home is `.agents/`, and the tool explicitly asks for them to be
deleted rather than overwriting them.

So the shipped state is:

- `codex` **is** in the managed tool set (`.openspec-target`)
- `.codex/skills/openspec-*` is **removed** — the duplicates the CLI asked us to delete
- `.codex/skills` retains its **35 pack-owned skills** from `sync-harness-skills.sh`
- `.codex` is **absent** from `INTERNAL_SKILL_HARNESSES`, because that table lists
  trees that *hold vendored mirrors*, and `.codex` no longer holds any

The cost named in the rejected option — "stops validating a live harness" — does
**not** apply: `.codex`'s openspec skills are validated at their canonical
location in `.agents/`, which the table does list. Nothing went unvalidated; the
duplicate copy went away.

## D-3 · `internal: true` is a repo-local invariant; the CLI will always strip it

`openspec/config.yaml` has no notion of `internal`, and the label appears
nowhere in the CLI's vocabulary. It is a requirement `check-skill-contracts.mjs`
imposes on files an external tool writes.

Therefore **`openspec update` strips it on every run, on any version, for every
managed tool.** Adopting 1.10.0 (D-1) fixes today's red gate; only a repo-owned
normalization step stops the recurrence. Hence
`scripts/normalize-vendored-skills.sh` (task 1.6), which derives its tool set
from the OpenSpec config rather than a hardcoded list — so a future tool
addition or harness migration does not silently fall outside it.

## D-4 · Accept the `.kimi` → `.kimi-code` migration

The assessment recorded `.kimi/`'s 10 openspec directories as *deleted*. They
were **migrated**: the CLI prints `Migrated 10 skills: .kimi → .kimi-code`, and
`.kimi-code/` gains exactly what `.kimi/` loses.

Restoring `.kimi/` would recreate an artifact the tool removes on every run and
make the idempotence criterion (task 2.6) permanently unsatisfiable. c300
accepts the rename and drops `.kimi` from the contract check's harness list.

## D-5 · Fix two measuring instruments inside this change

c300's purpose is a trustworthy baseline, so two gate defects are repaired here
rather than deferred:

- **`audit.sh` fails open** — `bash scripts/audit.sh zzznonsense` prints
  "✓ No violations" and exits 0. Every acceptance criterion in this phase that
  invokes `audit.sh <mode>` could otherwise pass by typo (task 1.8).
- **`check-git-url-discovery.sh` is red on clean HEAD** —
  `expected 30 public skills, found 36`, a hardcoded literal the pack outgrew
  (task 1.9). The assessment's baseline table missed this gate entirely.
