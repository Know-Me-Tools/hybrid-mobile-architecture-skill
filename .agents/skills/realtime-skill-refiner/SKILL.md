---
name: realtime-skill-refiner
description: Reactively detect, triage, refine, verify, and ship a fix for a bug in an installed skill package, driven by a real observed failure rather than a proactive review. Use when a skill produces wrong answers, fires on the wrong prompts, fails to fire at all, or is flagged by a log monitor or sycophancy check. Triggers on skill bug, skill failing, fix skill, patch skill, refine skill, realtime correction, skill regression, wrong skill fired, skill did not fire, sycophancy, bug ticket.
---
<!-- TJ-ARCH-MOB-001 compliant -->

# Realtime Skill Refiner

Proactive refinement happens when an author reviews a skill they just wrote.
This is the reactive counterpart: the same refinement algorithm, triggered by a
failure that already happened in production.

Run with `scripts/refiner-loop.sh --skill <name>`.

## The loop

```
Detect  →  Triage  →  Refine  →  Verify  →  Ship
            HALT
```

**Triage halts for human approval.** The loop stops there and will not continue
without an explicit decision. A producer does not grade its own work: the same
agent that will write the fix must not also be the one that decides the bug is
real and the diagnosis correct. Resume with `--approve <ticket>`, or close it
with `--reject <ticket>`.

## Stage 1 — Detect

Three signal sources, each recording where the evidence came from:

| Source | Signal |
|---|---|
| Log monitor | A service log line matches a known failure pattern |
| Sycophancy check | A skill's output is flagged as agreeable rather than correct |
| Operator | A bug is reported by hand against a named skill |

Detection records a ticket: which package, which skill, the source, the verbatim
evidence, and the timestamp. It does not diagnose. A ticket with a paraphrased
symptom and no raw evidence cannot be triaged later.

## Stage 2 — Triage (halts)

Gather evidence and decide scope. Produce, for human review:

- The exact failing prompt or input, verbatim.
- Which skill fired, and which should have.
- Whether the fault is the description (activation), the body (guidance), or the
  frontmatter contract (validation).
- The blast radius: which other skills share the trigger terms being changed.

Then stop. The output of triage is a proposal, not a change.

Widening one skill's description to catch a missed prompt routinely steals
prompts from a neighbor. Naming the neighbors here is what prevents fixing one
activation bug by creating another.

## Stage 3 — Refine

Only after approval. Apply the smallest change that addresses the approved
diagnosis:

- **Activation fault** → adjust the description's trigger terms. Keep the
  description within its length cap.
- **Guidance fault** → correct the body. Do not expand scope while in there.
- **Contract fault** → fix the frontmatter so it satisfies the validator.

One ticket, one skill, one focused diff. A refinement touching several skills
means triage under-scoped the problem; go back rather than proceeding.

## Stage 4 — Verify

A fix is unverified until the original failure is replayed:

```bash
node scripts/check-skill-contracts.mjs        # contract still holds
node scripts/generate-skill-metadata.mjs      # regenerate derived artifacts
node scripts/generate-skill-evals.mjs
git diff --exit-code                          # no drift left behind
```

Then re-run the recorded failing input and confirm the outcome changed. Add an
eval case covering it, so the regression cannot return silently.

If the same fix fails verification twice, stop and report the discrepancy
rather than trying a third variation.

## Stage 5 — Ship

Commit the skill change together with its regenerated artifacts and its new eval
case. Mark the ticket shipped, keeping the evidence attached. Re-register the
package so the harness picks up the change.

## Anti-patterns

- Skipping the Triage halt because the bug "is obvious".
- Editing a generated mirror instead of the canonical skill.
- Broadening a description without checking which neighbors lose prompts.
- Shipping without an eval case for the reproduced failure.
- Closing a ticket with no record of the evidence that opened it.
