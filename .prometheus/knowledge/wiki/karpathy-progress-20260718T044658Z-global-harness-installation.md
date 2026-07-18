---
type: Reference
id: karpathy-progress-20260718T044658Z-global-harness-installation
title: "Global harness marketplace and skill installation verified"
tags:
- karpathy-progress
- global-harness-installation
- complete
sources:
- conversation:operator-agent
timestamp: 2026-07-18T04:46:58Z
created_at: 2026-07-18T04:46:58Z
updated_at: 2026-07-18T04:46:58Z
revision: 1
---

## Intent

Complete global installation of the hybrid architecture skill package and its utilities across Claude Code, OpenCode, Codex, Kimi Code CLI, and Zed using each harness's current native discovery mechanism.

## Observed state and verification

Claude Code reports hybrid-mobile-architecture 1.1.0 with 14 skills from the GitHub-backed knowme-hybrid-architecture marketplace and both user-scope MCP servers connected. Codex reports the same plugin installed and enabled at 1.1.0. OpenCode resolves all 14 skills and both MCP configurations. Kimi config validation passes and its native skills/MCP paths contain all expected entries. Zed's shared Agent Skills path contains all 14 skills and its JSONC settings contain Dart and shadcn context servers. The installer completed idempotently after removing duplicate legacy copies.

## Decision and lesson

Status: complete. Preserve evidence, distinguish compile proof from runtime proof, and do not narrow the active goal.

## Next experiment

Restart already-running harness sessions so they rebuild their skill and plugin catalogs; use the checked-in installer and GitHub marketplace commands for future machines.
