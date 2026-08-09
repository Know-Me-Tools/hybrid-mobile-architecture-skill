---
title: karpathy-progress-memory
sidebar_label: karpathy-progress-memory
sidebar_position: 10
description: "Capture compact, evidence-backed Karpathy-style progress records and reusable lessons in both the committed project Prometheus wiki and a private per-project superset. Use at task and phase boundaries, after verification discoveries, when plans change, or before handoff, commit, and push."
---

# karpathy-progress-memory

**Category:** Workflow and retention

## What it is for

Capture compact, evidence-backed Karpathy-style progress records and reusable lessons in both the committed project Prometheus wiki and a private per-project superset. Use at task and phase boundaries, after verification discoveries, when plans change, or before handoff, commit, and push.

## Why it is designed this way

Long-running work loses decisions and repeats failures when only transcripts retain context. Compact evidence records preserve intent, delta, proof, failure, and the next experiment without turning every tool call into permanent noise.

## Common use cases

- Record a task or phase boundary
- Prepare a cross-harness handoff
- Promote a verified reusable lesson after a failure or design decision

## How to invoke it

Use the explicit skill name when the gate is important or implicit activation
would be ambiguous:

```text
/karpathy-progress-memory <your task or question>
```

Claude Code, Codex, OpenCode, and Kimi discover the same canonical
`SKILL.md`. Their activation adapters may recommend the skill, but the
adapter is advisory: Prometheus remains the lifecycle and mutation authority.

## Scope boundary

Do not store secrets, raw transcripts, unsupported claims, or private memory in public repository documentation.

## Canonical operating contract

Keep a lossless path of decisions and failures without turning every tool call into noise.
Apply the consuming project's base rules; record observations as facts only when
evidence exists.

## Capture cadence

- At every task boundary, add a compact record: intent, delta, evidence, failure, next.
- At a verified phase gate, run the full Prometheus learn/compile/lint pipeline.
- Before handoff or commit, ensure the current decision path is represented in both
  stores and no credentials were captured.

## Workflow

1. Gather authoritative evidence: changed paths, commands, outputs, runtime proof, and
   unresolved gaps.
2. Separate observation, inference, decision, rejected alternative, and next experiment.
3. Redact secrets and replace machine-specific project roots with `$REPO_ROOT` in the
   committed record. The private superset may retain useful local/operator context but
   never secret values.
4. Run `scripts/record-progress.sh` with a phase, title, summary, evidence, and next step.
5. At a phase gate, run `prometheus learn --capture-session --compile --lint`, then
   `pk lint`. Fix malformed newly-authored entries; preserve imported historical variants.
6. Run `prometheus learning status --json` and record queue, retry, dead-letter, and
   memory-delivery state separately from successful trace capture.
7. Promote only reviewed, project-independent lessons into the shared private KB.

Read [record-schema.md](https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill/blob/main/skills/karpathy-progress-memory/references/record-schema.md) before changing the recorder or
manually creating a compatible entry.

## Prohibitions

- Do not record API keys, tokens, passwords, cookies, private key material, or raw secret
  environment values.
- Do not claim verification from compilation alone when the requirement is runtime
  behavior.
- Do not overwrite divergent historical pages. Add a new revision or provenance variant.
- Do not publish the private superset into the repository.

## Installation and verification

Install the complete bundle with `knowme-builder skills install --path <project>`
or the workstation installer described in [Installation](../installation).
Verify a project copy with:

```bash
knowme-builder skills check --path <project>
```

The canonical source is
`skills/karpathy-progress-memory/SKILL.md`; generated scaffold and harness copies
must never be edited independently.
