---
sidebar_position: 2
title: Agent and content contracts
---

# Inspectable agent behavior

Universal Agent Runtime owns the run. The protocols below expose typed,
inspectable projections without transferring runtime authority to a client.

| Contract | Responsibility | Required safety property |
|---|---|---|
| **AG-UI** | Ordered streaming run events between UAR/Axum and clients | Stable IDs, sequence, resume, idempotent projection, explicit failure/cancellation |
| **A2UI** | Declarative governed UI and action continuation | Registered component types, validated props, actions routed back through UAR |
| **ContentBlock** | Cross-platform rich output | Exhaustive discriminated union and generated Dart/TypeScript mirrors |
| **MCP** | Tool/resource transport internal to governed execution | Metadata is untrusted; schema, effect, policy, approval, bounds, and audit are mandatory |
| **A2A** | Typed communication between independently hosted agents | Explicit trust, identity, capability, timeout, and failure boundaries |

Persist the event stream and its projection separately. That lets a conversation
rebuild its UI, show citations and thinking on demand, and migrate renderers without
discarding the original agent evidence.

Unknown versions, event types, and ContentBlock variants remain inspectable.
They are never silently dropped or interpreted as completion.

Use [AG-UI event contract](./skills/agui-event-contract),
[A2UI surface contract](./skills/a2ui-surface-contract),
[ContentBlock UI](./skills/content-block-ui), and
[Agent runtime security](./skills/agent-runtime-security) for the complete
implementation and test rules.
