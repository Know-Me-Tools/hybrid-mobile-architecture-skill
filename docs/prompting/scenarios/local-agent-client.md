---
sidebar_position: 6
title: Local desktop agent client
description: Staged prompts for a Claude Desktop-style local agent client with MCP, skills, files, model routing, approvals, events, and audit replay.
---

# Local desktop agent client

Use this recipe to build a local agent client that can safely use MCP servers,
skills, files, model routing, and persistent conversation/event history.

## Prerequisites

```text
Verify desktop shell, local persistence, MCP host strategy, file-grant model,
skill directory, model registry, and at least one safe MCP server for proof.
```

## Discovery and Feynman prompts

```text
Read agent protocol docs, MCP trust model, local skill loading rules, model
registry, Tauri/Rust patterns, UI standard, and conversation/event store docs.
```

```text
Explain how MCP server trust, file grants, model routing, skills, approvals,
conversations, and audit replay fit together without granting broad filesystem
authority.
```

## KBD prompts

```text
/kbd-assess local-agent-client
Assess trusted/untrusted tools, file grants, approval UX, denial behavior, model
routing, conversation history, event replay, and offline/local behavior.
```

```text
/kbd-analyze local-agent-client
Analyze MCP host, permission store, skill loader, conversation/event schema,
model registry, UI timeline, and Tauri command boundaries.
```

```text
/kbd-spec local-agent-client
Specify MCP server registry, per-tool permissions, file grants, approval/denial
events, conversation store, model route selection, audit replay, and UI proof.
```

```text
/kbd-plan local-agent-client
Plan permission/domain types first, then MCP host, skill loader,
conversation/event persistence, chat UI, denial flow, replay, verification,
critic, and retention.
```

## Implementation and verification

```text
Implement one safe public workflow. Require explicit file grants, persist
approvals and denials, route models from the dated registry, and render the full
event chain.
```

```text
Run a tool through the UI with a granted permission, deny another request, show
enforcement, persist the conversation/events, and replay the audit trail after
restart.
```

## Stop evidence

Stop for broad file grants, untrusted MCP execution, missing denial proof,
non-replayable conversations, stale model claims, or simulated workflow evidence.
