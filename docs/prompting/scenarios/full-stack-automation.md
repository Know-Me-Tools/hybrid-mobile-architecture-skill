---
sidebar_position: 4
title: Full-stack automation product
description: Staged prompts for a Hands-style automation product with workflow state, approvals, resumability, replay, AG-UI events, artifacts, and destructive checkpoints.
---

# Full-stack automation product

Use this recipe to build an agentic automation product where operators can see,
pause, resume, audit, and replay work. The output is not “an agent did a thing”;
the output is a trustworthy workflow system.

## Prerequisites

```text
Verify a typed workflow domain, explicit tool authority model, durable event
store, operator UI, artifact storage path, and at least one real safe workflow
target.
```

## Discovery and Feynman prompts

```text
Read architecture, agent runtime docs, ContentBlock/AG-UI contracts, tool
permission rules, deployment constraints, and workflow/event storage.
```

```text
Explain the workflow state machine, approval boundary, replay model, and how
AG-UI events represent progress, citations, thinking, artifacts, tool calls,
approvals, and errors.
```

## KBD prompts

```text
/kbd-assess full-stack-automation
Assess workflow personas, safe/destructive actions, resumability, replay,
artifact evidence, operator controls, permissions, and failure handling.
```

```text
/kbd-analyze full-stack-automation
Analyze agent runtime, event model, persistence layer, UI event rendering,
scheduler, approval storage, and deployment profile.
```

```text
/kbd-spec full-stack-automation
Specify workflow states, event types, approval gates, destructive checkpoints,
artifact references, replay API, operator UI, and public workflow proof.
```

```text
/kbd-plan full-stack-automation
Plan domain state first, then event persistence/projection, approval policy, UI
event timeline, artifact handling, replay, runtime verification, critic, and
retention.
```

## Implementation and verification

```text
Implement one bounded workflow slice. Make destructive actions impossible
without explicit approval. Persist every decision and event needed to replay the
workflow.
```

```text
Run one real workflow that pauses for approval, denies or confirms a destructive
action, resumes, emits visible events, produces an artifact, and reconstructs
from replay.
```

## Critic and stop evidence

```text
Verify the event log is complete, approvals are enforceable, destructive actions
cannot bypass checkpoints, artifacts are durable, and replay matches the
original run.
```

Stop for missing authority model, unbounded tool access, unreplayable events,
destructive action ambiguity, artifact loss, or simulated-only workflow proof.
