---
type: Reference
id: karpathy-progress-20260718T044503Z-global-harness-installation
title: "Global multi-harness skill and MCP installation"
tags:
- karpathy-progress
- global-harness-installation
- in-progress
sources:
- conversation:operator-agent
timestamp: 2026-07-18T04:45:03Z
created_at: 2026-07-18T04:45:03Z
updated_at: 2026-07-18T04:45:03Z
revision: 1
---

## Intent

Package and globally configure the hybrid architecture skill, its 13 companion skills, and the Dart/shadcn MCP utilities for Claude Code, OpenCode, Codex, Kimi Code CLI, and Zed without replacing unrelated configuration.

## Observed state and verification

Claude plugin manifest validation passed; the idempotent installer completed twice; OpenCode resolved all 14 skills and both MCP entries; Claude user-scope and Codex MCP entries resolve; Kimi config validation and MCP schema checks passed; Zed contains both context-server entries. A local marketplace snapshot copied ignored build artifacts and was stopped, so clean GitHub marketplace installation remains the next boundary.

## Decision and lesson

Status: in-progress. Preserve evidence, distinguish compile proof from runtime proof, and do not narrow the active goal.

## Next experiment

Commit and push the tracked package, replace the temporary local Claude/Codex marketplace declarations with the clean GitHub source, install both plugins, and verify their catalogs.
