---
sidebar_position: 2
title: Harness source map
slug: /harness-source-map
---

# Harness source map

**Verified at:** 2026-07-18
**Freshness policy:** refresh version-sensitive claims after 45 days or before
publishing production operator guidance.

Harness playbooks use the portable Agent Skills `SKILL.md` package format as the
shared baseline, but installation, discovery, permissions, plugins, MCP, session
state, and handoff behavior remain harness-specific contracts.

| Harness | Metadata | Official anchors |
|---|---|---|
| Codex | `data/harnesses/codex.json` | OpenAI Codex skills documentation; local Codex environment evidence for AGENTS, goals, plugins, and git directives. |
| Claude Code | `data/harnesses/claude-code.json` | Claude Code settings and SDK documentation. |
| OpenCode | `data/harnesses/opencode.json` | OpenCode skills, agents, and MCP server documentation. |
| Kimi Code CLI | `data/harnesses/kimi-code-cli.json` | Kimi command and slash-command documentation. |
| Google Antigravity | `data/harnesses/antigravity.json` | Antigravity docs home, CLI features, artifacts, and MCP documentation. |
| Zed | `data/harnesses/zed.json` | Zed AI overview, external agents, MCP, and ACP documentation. |

## Required Sections

Every harness page must cover:

- installation and version checks;
- instruction discovery;
- skills and plugin behavior;
- MCP configuration;
- permissions;
- plan, build, and critic invocation;
- autonomous budgets;
- evidence capture;
- interruption and resume;
- handoff examples.

The prompting validator checks each metadata file against this section set before
the Docusaurus build.
