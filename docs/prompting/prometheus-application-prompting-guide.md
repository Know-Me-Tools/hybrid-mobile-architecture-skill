# Prometheus application prompting and orchestration guide

**Research verification date:** 2026-07-17

## The control loop

```text
Feynman learn
→ KBD assess
→ research and analyze
→ decision-complete plan
→ bounded implementation
→ public-boundary verification
→ adversarial critic
→ Karpathy retention
→ next waypoint
```

Use the Feynman pass when the system cannot explain the domain, constraint, or
tradeoff in plain language. Grade the explanation, identify gaps, and re-study
before architecture. KBD then records the current waypoint and the evidence needed
to leave it. Implementation proceeds in bounded phases with explicit authority.
The producer never certifies its own work: a critic checks observable criteria.
Karpathy memory records the delta and reusable lesson without turning a failed
guess into a permanent rule.

## Prompt contract

Every implementation prompt should name:

1. Outcome and user-visible behavior.
2. Sources of truth and non-negotiable architecture.
3. Allowed repositories and external actions.
4. Required skills and their order.
5. Artifacts to create or modify.
6. Public-boundary verification and clean-checkout proof.
7. Time, token, retry, and stop limits.
8. Retention at the phase boundary.

Do not ask one prompt to research, redesign architecture, mutate multiple products,
deploy production, and certify completion. Stage the prompts, and carry decisions
forward as explicit artifacts.

## Harness playbooks

### Codex

Use `AGENTS.md` for durable repository instructions and project-local skills under
`.agents/skills`. Separate planning from execution, use goals only when explicitly
requested, and delegate independent work only when authorized. Capture tool evidence
and keep the worktree clean enough to distinguish existing work. A critic task should
review requirements and public boundaries, not merely rerun the producer’s tests.

### Claude Code

Use `CLAUDE.md`, project skills, hooks, subagents, and headless streaming. A headless
loop requires a budget, wall-clock timeout, maximum repeated failure count, stop
condition, and human checkpoints before external or destructive actions. Hooks may
record events or remind skill activation; they may not silently broaden authority.

### OpenCode

Use project skills, named agents, commands, permissions, and MCP from project config.
Separate build and critic agents. Deny broad filesystem or shell permissions by
default, and add narrow exceptions for the phase. Verify plugins against the current
OpenCode API rather than assuming Claude or Codex configuration is portable.

### Kimi Code CLI

Use plan mode for the Feynman/KBD and decision phases, auto mode only after authority
and stop conditions are explicit, and hooks/plugins for evidence capture. ACP can host
the agent in an editor, but the Kimi process still owns model, tools, and authentication.

### Google Antigravity

Use its agents, skills, MCP, hooks, and SDK only after checking the installed version's
actual capability surface. Store project rules in tracked files, keep external actions
approval-gated, and retain exported evidence because UI state alone is not durable.

### Zed

Choose deliberately among the native Zed Agent, ACP external agents, and terminal
threads. Native agents use Zed models and tools; ACP agents usually own their own
auth and configuration; terminal threads preserve a CLI’s native behavior. Do not
assume a capability in one path exists in another. Use Zed’s review surface for the
critic pass and the agent's own instruction files for durable policy.

## Model routing

Generate routing recommendations from `model-registry.yaml`; do not duplicate stale
prices or context limits in prompts. Default to a balanced implementation model.
Escalate to a frontier architecture model for cross-repository decisions and to an
independent model family for criticism. Use fast models for bounded mechanical work,
not unresolved architecture. Vendor benchmarks are leads for evaluation, not proof.

## Autonomous loop guardrails

- Begin from an inventoried worktree and make atomic commits.
- Set a public success condition, maximum retries, wall-clock budget, and token budget.
- After two repeated failures on the same approach, stop and reassess rather than
  weakening a test.
- A producer cannot delete or rewrite a failing acceptance criterion.
- Cross-model critics grade evidence against requirements and actively look for
  sycophancy, omitted surfaces, unsafe defaults, and unverifiable claims.
- PMPO may improve a metaprompt, but it may not edit requirements to fit output.
- “Working” requires `hybrid-runtime-verification` from a clean checkout.

## Scenario packs

Each scenario uses four prompts: learn/plan, implement one waypoint, verify/critic,
and retain/advance.

| Scenario | Required skill sequence | Observable stop condition |
|---|---|---|
| Full KnowMe hybrid | orchestrate → architecture → UI skills → deploy → runtime verify | Flutter, Tauri, and Axum share one Rust workflow |
| Flutter-only + Rust FFI | orchestrate → Flutter/Rust → mobile navigation → golden/a11y | real iOS/Android launch crosses FFI |
| Tauri local agent | orchestrate → Tauri/Rust → ContentBlock UI → runtime verify | offline persisted chat works with local inference |
| Automation product | orchestrate → agent workflow → protocol/UI → deploy | one Hand streams inspectable tool events |
| Multi-tenant SaaS | orchestrate → auth/data model → Forge/Fabric/Gate/Keto → deploy | tenant isolation and authenticated public workflow pass |
| Claude Desktop-style client | orchestrate → MCP/skills/files/model routing → Tauri | a permissioned MCP tool executes and is auditable |
| Ideation studio | Feynman → research → Karpathy → product workflow | an idea is challenged, evidenced, and retained |
| Native Rust agent | orchestrate → native-agent creator → protocol tests | agent exposes its declared protocols and Docker health |
| Multi-cloud deployment | deploy catalog → GitOps → critic | every overlay renders and promotes immutable digests |
| Branded docs portal | branded Docusaurus → a11y → runtime verify | fresh build, both themes, sanitized public content |

### Copyable first prompt

```text
Classify this request against the Prometheus application scenarios. Read the binding
architecture and relevant skills. Run a Feynman gap assessment before choosing an
architecture. Produce a decision-complete, waypoint-based plan with explicit authority,
artifacts, public-boundary success criteria, retry/stop limits, critic role, and
Karpathy retention. Do not implement yet.
```

### Copyable implementation prompt

```text
Implement only waypoint <name> from the approved plan. Preserve existing work and
architecture. Invoke the listed skills before their matching work. Verify through the
named public boundary, record failures honestly, stop after two repeats of the same
failed approach, and append the verified delta to project memory. Do not claim the
application works unless the clean-checkout runtime gate passes.
```

### Copyable critic prompt

```text
Act as an independent adversarial verifier. Grade the implementation against the
original requirement and observable criteria, not the producer's summary. Inspect
public boundaries, security defaults, clean-checkout reproducibility, omitted platforms,
and evidence. Return pass/fail per criterion, concrete evidence, and the smallest
required correction. Do not edit the criteria.
```

## OpenAI Proxy generator case study

The native-agent creator produced a Rust/Axum product with an OpenAI-compatible HTTP
API, MCP over stdio and HTTP, ACP, AG-UI, A2A discovery, skills and memory, Docker
packaging, tests, and an OpenCode plugin. Its useful lesson is the separation between
one typed agent core and multiple thin delivery protocols. Protocol adapters should
translate, not reimplement agent behavior.

The case study also shows what must not be copied blindly: model catalogs age quickly,
authentication behavior needs current vendor documentation, and undocumented
subscription-authentication techniques are not a public product contract. Generate
the skeleton, then research and verify each external boundary before release.

## Skill creation as learning

Create a new skill only when a gap is operational, repeatable, and likely to recur.
The Feynman loop supplies the plain-language model; implementation supplies a proven
procedure; the critic supplies failure modes; Karpathy memory supplies provenance.
Validate the skill in a scratch project before adding activation hooks. For a durable
runtime capability with protocols and independent lifecycle, use the native-agent
creator instead of disguising a service as a skill.

## Official research index

The machine-readable registry links each model to dated official sources. Harness
research should start with the current official documentation for
[Codex](https://developers.openai.com/codex/),
[Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview),
[OpenCode](https://opencode.ai/docs/),
[Kimi Code](https://www.kimi.com/code/docs/),
[Zed agents](https://zed.dev/docs/ai/agents), and the installed Antigravity SDK.
