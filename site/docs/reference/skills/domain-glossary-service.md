---
title: domain-glossary-service
sidebar_label: domain-glossary-service
sidebar_position: 29
description: "Implement or audit a versioned domain glossary used by applications and agents to normalize terms without leaking client-specific data into reusable packages. Use for canonical terms, synonyms, entity mappings, policy vocabulary, or terminology-driven retrieval."
---

# domain-glossary-service

**Category:** Domain modeling

## What it is for

Implement or audit a versioned domain glossary used by applications and agents to normalize terms without leaking client-specific data into reusable packages. Use for canonical terms, synonyms, entity mappings, policy vocabulary, or terminology-driven retrieval.

## Why it is designed this way

Prompts are a poor place to hide vocabulary rules. A versioned glossary gives humans, retrieval, policy, and agents a deterministic terminology contract while keeping customer-specific language in project overlays.

## Common use cases

- Normalize canonical terms and synonyms
- Map vocabulary to entities or policy actions
- Handle deprecation, locale fallback, ambiguity, and revision pinning

## How to invoke it

Use the explicit skill name when the gate is important or implicit activation
would be ambiguous:

```text
/domain-glossary-service <your task or question>
```

Claude Code, Codex, OpenCode, and Kimi discover the same canonical
`SKILL.md`. Their activation adapters may recommend the skill, but the
adapter is advisory: Prometheus remains the lifecycle and mutation authority.

## Scope boundary

Do not place customer names, URLs, roles, or private terminology in the reusable Builder package.

## Canonical operating contract

The glossary is a governed vocabulary contract, not a prompt fragment.

## Model

Each term has a stable ID, canonical label, definition, synonyms, domain,
locale, status, version, provenance, and optional entity or policy mappings.
Changes are append-only revisions with explicit deprecation and replacement.

## Boundaries

- Keep reusable schema and behavior generic.
- Store customer names, URLs, roles, and policy vocabulary in project overlays.
- Validate aliases for ambiguity and cycles.
- Resolve terms deterministically and expose the glossary revision to UAR.
- Authorize project glossary access by verified tenant.
- Cache only revisioned, non-sensitive projections.

Test ambiguous terms, deprecated aliases, locale fallback, revision pinning,
cross-tenant denial, cache invalidation, and agent runs resumed against a newer
glossary.

## Installation and verification

Install the complete bundle with `knowme-builder skills install --path <project>`
or the workstation installer described in [Installation](../installation).
Verify a project copy with:

```bash
knowme-builder skills check --path <project>
```

The canonical source is
`templates/project-skills/domain-glossary-service/SKILL.md`; generated harness copies
must never be edited independently.
