---
title: anonymized-replica
sidebar_label: anonymized-replica
sidebar_position: 27
description: "Build or audit an anonymized, reproducible data replica for development, proof-of-concept, or certification. Use for POC datasets, production-shape fixtures, de-identification, referential integrity, synthetic data, or privacy-preserving test environments."
---

# anonymized-replica

**Category:** Data and privacy

## What it is for

Build or audit an anonymized, reproducible data replica for development, proof-of-concept, or certification. Use for POC datasets, production-shape fixtures, de-identification, referential integrity, synthetic data, or privacy-preserving test environments.

## Why it is designed this way

Removing names is not anonymization. The skill preserves scenario behavior and referential shape while explicitly controlling direct identifiers, quasi-identifiers, secrets, free text, provenance, and reproducibility.

## Common use cases

- Create a production-shaped POC dataset
- Build deterministic certification fixtures
- Review de-identification and re-identification risk

## How to invoke it

Use the explicit skill name when the gate is important or implicit activation
would be ambiguous:

```text
/anonymized-replica <your task or question>
```

Claude Code, Codex, OpenCode, and Kimi discover the same canonical
`SKILL.md`. Their activation adapters may recommend the skill, but the
adapter is advisory: Prometheus remains the lifecycle and mutation authority.

## Scope boundary

Do not use it as permission to copy production transcripts, credentials, documents, or raw client notes.

## Canonical operating contract

An anonymized replica preserves behavior and relationships, not identity.

## Contract

- Start from an explicit field-classification manifest.
- Drop fields that are unnecessary for the scenario.
- Replace direct identifiers with deterministic, scoped surrogates.
- Generalize or synthesize quasi-identifiers with re-identification risk.
- Preserve referential integrity and important statistical edge cases.
- Exclude credentials, tokens, raw documents, free-form notes, and transcripts
  unless a reviewed transformation exists.
- Record source schema digest, transformation version, and output digest.
- Make generation deterministic from a protected seed, never a production key.

Run privacy review, uniqueness checks, secret scanning, referential-integrity
tests, and scenario coverage before distribution. Never call a replica
anonymous solely because names and email addresses were removed.

## Installation and verification

Install the complete bundle with `knowme-builder skills install --path <project>`
or the workstation installer described in [Installation](../installation).
Verify a project copy with:

```bash
knowme-builder skills check --path <project>
```

The canonical source is
`skills/anonymized-replica/SKILL.md`; generated scaffold and harness copies
must never be edited independently.
