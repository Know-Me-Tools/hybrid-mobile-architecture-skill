---
type: Reference
id: worktree-consolidation-postmortem-runtime-verification-failures
title: Worktree consolidation postmortem and runtime verification failures
tags:
- worktree-consolidation
- postmortem
- runtime-verification
- skills
- knowme-poc
timestamp: 2026-07-17T00:00:00Z
created_at: 2026-07-17T00:00:00Z
updated_at: 2026-07-17T00:00:00Z
revision: 1
---

## Outcome

The KnowMe example accumulated many individually plausible changes while the shipping desktop and mobile applications remained unproven. This was a process and verification failure, not one isolated implementation defect. Worktree consolidation preserves the complete evidence trail so later skill improvements can be based on what actually happened.

## Failure map

### Abandoned concurrency

Parallel worktrees were opened without an owner responsible for closure, integration, or cleanup. Some branches reached `main`, while their dirty wiki and code changes remained stranded. Four graph test binaries were orphaned with parent PID 1 for more than eight hours. Future parallel work must name an integration owner and a termination condition before worktrees are created.

### Verification without launch

Compiler, linter, and unit-test success was repeatedly reported as proof that an application worked. The production Vite bundle and Tauri binary later exposed failures that adjacent checks could not see, and the window could open while backend initialization silently failed. “Working” now requires a real launch, persistent boot evidence, and a public-boundary workflow.

### Ignored clean-checkout packaging

Local ignored `dist` directories made workspace packages resolve on a developer machine while a clean checkout could not install or test them. Development exports must resolve from tracked sources, publish-time metadata must switch to `dist`, and verification must run from a clone with no ignored build artifacts.

### Generator and example-app drift

Repairs were sometimes applied only to `apps/knowme-poc`, leaving scaffolds to regenerate the same defect. Examples include the obsolete Safari target, Rust toolchain disagreement, package exports, and iOS linker configuration. Every example repair now has a responsible scaffold or template counterpart.

### Missing timeouts

CI and behavior tests could hang indefinitely, consuming runners and obscuring the first failing boundary. Jobs, launch probes, and subprocess tests need explicit time budgets and useful timeout diagnostics.

### Inaccurate skill guidance

Skills encouraged feature completion and static verification without an enforceable runtime gate. Session records also show “complete” entries with unknown changes and no evidence. Skill guidance must distinguish build proof from launch proof and require concrete artifact, process, persistence, and workflow evidence.

### Incomplete architecture layers

The Flutter Notes screen performed persistence work directly, fake desktop authentication layers existed without a real feature, and the entity feature lacked a mounted runtime boundary. These shortcuts violated the declared architecture even when the UI rendered. Architecture audits must be run against the generated application, and missing layers must be implemented or the unused feature removed.

## Recurrence controls

- Preserve one global Rust runtime and move blocking model construction to its blocking pool.
- Verify fresh application-data creation, migrations, seed loading, memory search, and streamed chat.
- Test production bundles and real desktop/mobile launches, not only development servers.
- Run clean-checkout and newly scaffolded-project verification before declaring generator work complete.
- Keep deferred design work behind the working-application gate.
- Close or explicitly defer every worktree and commit its Prometheus history before ending a phase.

## Consolidation evidence

The pre-consolidation manifest records every branch, dirty file, wiki file, event/log file, frontmatter identity, revision, timestamp, and SHA-256. The wiki-consolidation manifest maps every source page to a canonical destination or a provenance-preserved source variant and records each machine-path or credential redaction.
