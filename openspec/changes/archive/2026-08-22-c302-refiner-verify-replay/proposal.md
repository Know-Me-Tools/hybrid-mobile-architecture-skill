## Why

`skills/realtime-skill-refiner/SKILL.md:83-84` promises Verify re-runs the recorded
failing input and adds an eval case. `scripts/refiner-loop.sh:118-149` runs four repo
gates and a drift check, and does neither. The plumbing exists — `evidence` is persisted
at :211 and `ticket_field` extracts it — but Verify never reads it. However, `--evidence`
is free text with no schema, so 'replay' has no mechanical meaning yet; defining it is
the blocking first task and may legitimately turn this into a docs-only change.

## What Changes

- Define the replay contract (a command plus an expected-failure marker), or conclude
  replay is infeasible for this evidence class.
- If feasible: `--verify` re-executes the replay and fails when the failure reproduces;
  assert an eval case covering the evidence exists.
- If infeasible: amend the skill body so no promise outlives the script.

## Impact

- Depends on c300.
- Modifies a shipped skill body and its script; the two must agree at the end.
