---
title: build-branded-docusaurus
sidebar_label: build-branded-docusaurus
sidebar_position: 2
description: "Scaffold, brand, sanitize, and verify a Docusaurus documentation portal for a Prometheus project. Use when creating project docs, a public documentation site, GitHub Pages, local search, Mermaid diagrams, or a docs container."
---

# build-branded-docusaurus

**Category:** Documentation and delivery

## What it is for

Scaffold, brand, sanitize, and verify a Docusaurus documentation portal for a Prometheus project. Use when creating project docs, a public documentation site, GitHub Pages, local search, Mermaid diagrams, or a docs container.

## Why it is designed this way

A documentation site is a publication boundary, not a folder copied to the web. The skill separates public sources from private evidence, preserves brand and accessibility contracts, and requires deterministic search, sanitization, links, builds, screenshots, and deployment checks.

## Common use cases

- Create or extend a Docusaurus product portal
- Publish architecture and API guidance to GitHub Pages
- Add Mermaid, local search, container delivery, or publication sanitization

## How to invoke it

Use the explicit skill name when the gate is important or implicit activation
would be ambiguous:

```text
/build-branded-docusaurus <your task or question>
```

Claude Code, Codex, OpenCode, and Kimi discover the same canonical
`SKILL.md`. Their activation adapters may recommend the skill, but the
adapter is advisory: Prometheus remains the lifecycle and mutation authority.

## Scope boundary

Do not publish raw wikis, session logs, credentials, personal information, or generated build output as source.

## Canonical operating contract

Read the project's brand and UI standard before choosing tokens. Inventory existing
documentation, then classify every source as public, public-normalize,
private-synthesis-only, or excluded. Raw wikis, session events, conversation logs,
credentials, personal data, and machine-local paths never enter public output.

## Procedure

1. Detect an existing site and brand assets; update the source rather than generated HTML.
2. Ask only unanswered questions about public audience, publication URL, search, and container delivery.
3. Pin Docusaurus and runtime dependencies. Use separate docs plugin instances when content ownership differs.
4. Apply the brand tokens in supported CSS variables and stable theme classes. Swizzle only when CSS cannot satisfy the structural contract.
5. Enforce Flat 2.0: no visible borders, separator lines, gradients, or decorative shadows. Regions differ by filled backgrounds and spacing. Preserve visible keyboard focus.
6. Add Mermaid with coordinated themes and deterministic local search by default.
7. Add `SITE_URL` and `BASE_URL`, GitHub Pages publishing, and a non-root immutable container.
8. Add a sanitizer that rejects private paths, secrets, and raw wiki content.
9. Run frozen install, production build, link checks, representative route checks, responsive light/dark screenshots, and accessibility checks.

Use `scripts/scaffold.sh <site-dir> <site-name> <site-url> <base-url>` for a new
site, then replace the starter copy with reviewed project documentation and brand
assets. Use `scripts/verify.sh <site-dir>` as the minimum repeatable gate. A site
is not complete merely because the development server opens.

## Installation and verification

Install the complete bundle with `knowme-builder skills install --path <project>`
or the workstation installer described in [Installation](../installation).
Verify a project copy with:

```bash
knowme-builder skills check --path <project>
```

The canonical source is
`skills/build-branded-docusaurus/SKILL.md`; generated scaffold and harness copies
must never be edited independently.
