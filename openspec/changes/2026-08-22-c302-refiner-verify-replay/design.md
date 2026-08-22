# Design decisions — c302

## D-1 · What "replay" can mean here (task 1.0)

**Decided by:** user, 2026-08-22 · **Option chosen:** structured replay + honest body

`skills/realtime-skill-refiner/SKILL.md:83-84` makes two promises about Stage 4:

> "Then re-run the recorded failing input and confirm the outcome changed. Add an
> eval case covering it, so the regression cannot return silently."

`scripts/refiner-loop.sh:118-149` keeps neither. It runs four repo gates and a
drift check. Before deciding how to close that, the two promises were checked
against what the repo can actually support — they turn out to have different
answers.

### Promise 1 — "re-run the recorded failing input": **buildable, with a schema**

The blocker was never capability, it was the absence of a contract. `--evidence`
is documented as free text (`refiner-loop.sh:12`), enforced only as non-empty
(:189), and stored as an opaque string (:211). "Replay this string" has no
meaning.

The plumbing is otherwise present: evidence is persisted per ticket and
`ticket_field` already extracts it. Adding an **optional** structured field
turns replay into a real operation without forcing every ticket to have one.

### Promise 2 — "add an eval case covering it": **not buildable as written**

Three findings, each independently sufficient:

1. **Eval cases are generated, not authored.** `generate-skill-evals.mjs:27-40`
   templates exactly three cases per skill (`positive-explicit`,
   `positive-implicit`, `negative-near-miss`) from the skill's own description.
   The current file is 36 skills × 3 = 108 lines. There is no slot for
   "a case covering this specific bug", and a hand-added line would be erased
   by the next regeneration.
2. **The eval shape cannot express a bug.** A case is `{id, kind, prompt,
   expectedSkills}` — a skill-*activation* assertion. Most refiner tickets are
   not activation bugs.
3. **No runner exists.** `check-skill-contracts.mjs:7-10` reads the file and
   counts lines. Nothing executes a case. Deciding which skill fired for a
   prompt requires driving a live agent session — a subsystem, not a task.

So promise 2 is removed from the skill body rather than faked. Building an eval
runner was offered and declined as out of scope; if it is ever built, this
promise can return with a mechanism behind it.

## D-2 · Optional, not mandatory — and silence must be visible

`--replay` is optional. Much evidence is a pasted transcript with no runnable
command, and demanding one would make the loop unusable for the cases it was
written for.

The failure mode that creates is a Verify that *looks* thorough while checking
only the gates. So when no replay command is recorded, Verify **says so on its
own line** and the ticket records `replayed: false`. A reader can tell "the
failure was re-executed and is gone" from "nobody re-executed anything" — which
is precisely the distinction the current script erases.

## D-3 · Semantics: the replay command asserts the failure is GONE

`--replay '<command>'` records a command that **reproduced the failure** when
the ticket was opened. Verify therefore expects it to **succeed (exit 0)** after
the fix.

- exit 0 → the failure no longer reproduces → Verify may pass
- non-zero → the failure still reproduces → Verify **fails**, and the ticket
  is pushed back to `approved`

This is the inverse of the naive reading ("re-run the failing thing, expect it
to still fail"), and the direction is chosen deliberately: the operator records
the command that *demonstrates correct behaviour*, so a green replay is
evidence of a fix rather than evidence the bug is still there.

## D-4 · The body is amended to match the script exactly

Stage 4 of the skill is rewritten to describe the four gates, the optional
replay, and the explicit "no replay recorded" state. No promise is left in the
body that the script does not keep — which is the actual defect c302 exists to
close, larger than the replay feature itself.
