---
sidebar_position: 2
title: Agent and content contracts
---

# Inspectable agent behavior

- **AG-UI** carries streaming run events between an Axum host and clients.
- **ContentBlock** renders completed and partial text, reasoning disclosures,
  citations, memory matches, tool calls, artifacts, and media.
- **MCP** connects tools and contextual resources.
- **A2A** connects independently hosted agents when a typed service boundary is
  more appropriate than an in-process skill.

Persist the event stream and its projection separately. That lets a conversation
rebuild its UI, show citations and thinking on demand, and migrate renderers without
discarding the original agent evidence.
