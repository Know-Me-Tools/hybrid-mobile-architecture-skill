---
sidebar_position: 3
title: Harnesses and model routing
slug: /harnesses
---

# Harnesses and model routing

Use each harness on its own terms. The same Prometheus process should feel
native in each tool instead of assuming that one agent harness has the same
instruction discovery, skill loading, permissions, MCP behavior, or handoff
surface as another.

## Harness Summary

| Harness ID | Durable instructions | Skill surface | Operating rule |
|---|---|---|---|
| `harness-codex` | `AGENTS.md` | `.agents/skills/` | Use plan/goals deliberately, keep authority explicit, and preserve tool evidence. |
| `harness-claude-code` | `CLAUDE.md` | `.claude/skills/` | Use hooks, subagents, and headless loops only with budgets and stop conditions. |
| `harness-opencode` | `AGENTS.md`, `opencode.json` | `.opencode/skills/` | Use project skills, named agents, permissions, commands, and MCP from project config. |
| `harness-kimi-code-cli` | `.kimi-code/` config plus project instructions | `.kimi-code/skills/` | Use plan mode for learning and decision work; use auto mode only after authority is explicit. |
| `harness-antigravity` | tracked project rules | installed skills, MCP, hooks, SDK | Check the installed SDK capability surface before relying on a feature. |
| `harness-zed` | project rules plus Zed agent context | native agent, ACP agent, or terminal thread | Choose deliberately between native Zed agents, ACP external agents, and CLI terminal threads. |

## Autonomy Contract

Every autonomous loop declares:

- time and token budget;
- retry limit;
- authority boundary;
- observable stop condition;
- human checkpoint for consequential external actions;
- public-boundary evidence required for completion.

The producer does not certify itself. A critic grades the original requirements,
public evidence, security defaults, omitted surfaces, and clean-checkout
reproducibility.

## Model Routing

Mutable model recommendations are generated from
[`model-registry.yaml`](./model-registry.yaml) into
[`model-routing.generated.md`](./model-routing.generated.md). Do not copy model
IDs, context windows, availability, or pricing into hand-authored prompts.
Stable guidance belongs in prose; current model facts belong in the registry.
