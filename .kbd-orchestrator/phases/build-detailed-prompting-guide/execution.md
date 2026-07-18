# EXECUTION: build-detailed-prompting-guide

Project: Hybrid Mobile Architecture Skill
Started: 2026-07-18T09:13:18Z
Backend: OpenSpec through KBD apply driver
Active change: prompting-guide-foundation

## Dispatch Contract

KBD remains the source of truth for this phase. `/kbd-execute` selected the
existing OpenSpec changes as the execution backend and dispatches task work
through the KBD-owned apply driver:

```text
/kbd-apply prompting-guide-foundation
/kbd-apply prompting-guide-harness-loops
/kbd-apply prompting-guide-scenario-recipes
/kbd-apply prompting-guide-agent-orchestration
/kbd-apply prompting-guide-publication-gates
```

The KBD apply driver must advance one unchecked task at a time, fire
`task:before` and `task:after` hooks, synchronize `progress.json`, and refresh
the current waypoint. Bare OpenSpec apply commands are not used for this phase.

## Ordered Changes

1. `prompting-guide-foundation`
2. `prompting-guide-harness-loops`
3. `prompting-guide-scenario-recipes`
4. `prompting-guide-agent-orchestration`
5. `prompting-guide-publication-gates`

## First Pending Work

Start with `prompting-guide-foundation` task 1.1: inventory the current root and
site prompting files, then add stable identifiers for content, recipes,
harnesses, roles, evidence, authority, artifacts, recovery, and routes without
deleting either source tree.

## Verification Boundary

Each OpenSpec change is complete only when its task list is checked, strict
OpenSpec validation passes, relevant site/content validation passes, and the
project Karpathy memory contains start and verified-end evidence. Documentation
only changes may skip artifact-refiner QA under the KBD skill contract, but they
still require OpenSpec and content verification.
