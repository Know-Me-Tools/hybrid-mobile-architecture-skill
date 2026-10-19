## Why

Users need to know when a repeatable instruction should become a skill and when a
capability requires a typed, independently deployable agent. The existing OpenAI Proxy
summary and orchestration skill do not show that boundary or generate the documented
scenario/harness workflow.

> Scope: an evidence-qualified OpenAI Proxy case study, the skill-versus-native-agent
> decision model, and an upgraded portable orchestration skill.

## What Changes

- Publish an OpenAI Proxy case study based on current source and commit history,
  separating generator-provided, subsequently added, verified, inferred, stale, and
  unsupported behavior.
- Map its Axum, OpenAI-compatible, MCP, ACP, AG-UI, A2A, memory, Docker, and OpenCode
  plugin boundaries without publishing undocumented subscription-authentication
  techniques or stale model catalogs.
- Define a lifecycle-based skill-versus-agent decision test covering process ownership,
  typed protocol endpoints, durable state, concurrency, authentication, deployment,
  release lifecycle, and public consumer contracts.
- Adapt `orchestrate-prometheus-application` to classify the ten scenarios, select the
  correct harness/loop sequence and producer/critic roles, emit references to the
  canonical prompt packs, require Karpathy phase records, and block “working” claims
  until `hybrid-runtime-verification` evidence exists.
- Keep one template source and synchronize validated copies across all six supported
  project harness directories and generated project instructions.

## Capabilities

### New Capabilities

- `native-agent-case-study`: Evidence-qualified generator-to-product history and a
  repeatable decision contract for creating skills versus typed native agents.
- `prometheus-application-orchestration`: A portable routing skill that selects and
  validates scenario, harness, model-role, loop, retention, and completion contracts.

### Modified Capabilities

None.

## Impact

- Affects `docs/prompting/case-studies/`, decision guidance, the canonical
  `templates/project-skills/orchestrate-prometheus-application/` source, all six
  harness copies, activation hooks, and generated `AGENTS.md`/`CLAUDE.md` guidance.
- References `cand-008` and `cand-009`; it does not copy OpenAI Proxy source or modify
  the supporting repository.

## Dependencies

- `prompting-guide-foundation`
- `prompting-guide-harness-loops`
- `prompting-guide-scenario-recipes`
