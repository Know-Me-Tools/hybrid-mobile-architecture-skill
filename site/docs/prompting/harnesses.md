---
sidebar_position: 2
title: Harnesses and model routing
---

# Use each harness on its own terms

Codex uses AGENTS.md, project skills, plans/goals, and bounded parallel tasks. Claude
Code uses CLAUDE.md, hooks, headless streaming, and subagents. OpenCode uses project
skills, named agents, permissions, commands, and MCP. Kimi Code separates plan and
auto modes and can run through ACP. Zed distinguishes native agents, ACP external
agents, and terminal threads. Antigravity capabilities must be checked against the
installed SDK rather than assumed.

An autonomous loop always has a time/token budget, retry limit, authority boundary,
observable stop condition, and human checkpoint for consequential external actions.
The producer does not certify itself; a critic grades the original requirements.
