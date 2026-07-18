ASSESSMENT: build-detailed-prompting-guide
Project: Hybrid Mobile Architecture Skill
Date: 2026-07-18
Codebase baseline: The repository has a healthy branded Docusaurus/Pages delivery path and compact prompting summaries, but it does not contain or publish the detailed, copyable prompting system required by this phase.
Cross-tool progress: none recorded in this phase's canonical progress file

RESEARCH METHOD AND EVIDENCE
- Applied the Prometheus deep-research stages to local-source inventory, official-source search, retrieval, verification, conflict checking, citation selection, and report synthesis.
- Used Firecrawl search as the primary web-search tool and Firecrawl scrape for retrieval. Searches were restricted to official OpenAI, Anthropic, OpenCode, Kimi, Zed, Google Antigravity, Docusaurus, GitHub, MiniMax, Alibaba Cloud, and DeepSeek domains.
- Retrieved the live public KnowMe Pages routes and sitemap. The public prompting section exposes only `/prompting/playbook` and `/prompting/harnesses`.
- Retrieved every URL currently cited by `docs/prompting/model-registry.yaml`. All returned HTTP 200 on 2026-07-18. This verifies link reachability, not every capability claim or routing recommendation.
- Attempted the background `prometheus-research` daemon to preserve a full research package. Its job remained at stage 0 with a dead child PID and a stale checkpoint, so it was cancelled. No daemon-generated report is treated as evidence; the Firecrawl results and local inspection are the evidence used here.
- Inspected the current OpenAI Proxy source rather than relying on the existing case-study paragraph. Its current Axum router exposes OpenAI-compatible chat/model endpoints, AG-UI streaming, optional A2A discovery, memory routes, MCP stdio/HTTP, and an ACP stdio mode. It also contains Docker and OpenCode-plugin packaging. Generator lineage is asserted by the operator but is not proven by an artifact in this repository.

IMPLEMENTATION STATUS
- Source prompting guide: [PARTIAL] — `docs/prompting/prometheus-application-prompting-guide.md` is 1,300 words and names the control loop, six harnesses, guardrails, ten scenarios, and a short case study; it supplies only three generic copyable prompts and no end-to-end recipe.
- Scenario packs: [PARTIAL] — `docs/prompting/scenario-packs.md` is 965 words. Each of ten scenarios has prerequisites, one first prompt, skill/role/artifact notes, and a stop condition, but none has the required discovery, Feynman, KBD, research, plan, bounded implementation, verification, critic, reflection, recovery, and termination prompt sequence.
- Harness playbooks: [STUB] — the source guide gives one paragraph per harness; the public site reduces all six to 114 words. There are no copyable setup commands, project-file layouts, permission examples, MCP examples, headless/autonomous invocations, evidence capture, or handoff examples.
- Model registry: [PARTIAL] — 14 dated entries and official-source URLs exist and all cited URLs were reachable. The validator only checks required fields and HTTPS syntax; it does not check live status, source recency, exact model-to-source correspondence, claim support, duplicate IDs, enum validity, or generation of routing guidance from the registry.
- Learning and autonomy loops: [PARTIAL] — Feynman, KBD, Karpathy, PMPO, producer/critic, retry, and stop ideas are named, but the guide does not show real invocations, input/output artifacts, waypoint transitions, authority envelopes, budget examples, failure recovery, or complete loop transcripts.
- OpenAI Proxy case study: [STUB] — the current public/source guide has two paragraphs. It omits the generator-to-product trace, architecture map, protocol boundary evidence, current-versus-generated delta, verification commands, and the decision test for skill versus typed native agent. The proxy's own earlier protocol assessment is also stale relative to its current implementation, so it cannot be copied as current truth.
- Reusable orchestration skill: [PARTIAL] — `orchestrate-prometheus-application` is a 270-word routing checklist. Identical copies exist in all six project harness skill directories, but it does not emit the promised harness-specific prompt sequences, registry-derived role selection, scenario completeness checks, or scratch verification.
- Docusaurus prompting publication: [STUB] — `site/docs/prompting` contains only two files totaling 242 words. The live sitemap confirms there are no scenario, loop, model, case-study, or per-harness routes.
- GitHub Pages delivery: [DONE] — the pinned custom Actions workflow builds on pull requests and deploys from `main` with Pages permissions; the live public routes return HTTP 200.
- Sanitization and search plumbing: [PARTIAL] — the current site sanitizer passes and local search includes `/prompting`, but the sanitizer scans site-local `docs`/`src`/`static` only. Publishing root docs directly would require extending the public-content boundary to the canonical prompting source.
- Verification automation: [PARTIAL] — registry structure, public-content sanitization, broken-link failure, and Docusaurus production build exist. There is no recipe-schema validator, staged-prompt completeness test, official-source liveness/freshness gate, scenario-to-architecture rules audit, expected-route check, or representative harness execution proof.

CROSS-TOOL PROGRESS
- NONE — `progress.json` records no completed, active, or blocked changes for this phase.
- STATE DRIFT — `current-waypoint.json` correctly names this phase but still carries ten unrelated application changes and a stale `/kbd-apply` `nextCommand` from the previous phase. `position-reminder.txt` also points to the previous phase. These fields must not be used as prompting-guide examples or completion evidence.

SPEC GAP SUMMARY
- The canonical phase goals are the only current spec for this work; `openspec/specs` contains no prompting-guide specification.
- The public site says “The full guide includes ten staged recipe packs,” but it does not publish those packs. This is a false affordance, not merely abbreviated navigation.
- A complete recipe needs a stable schema with: prerequisites; discovery prompt; Feynman prompt; KBD assess/analyze/spec/plan prompts; research prompt; bounded implementation prompts; verification prompt; independent critic prompt; reflection/retention prompt; recovery prompt; stop conditions; authority boundary; expected artifacts; evidence contract; required skills; producer and critic role classes; and harness variants.
- Every current scenario is missing most of that schema:
  - Full hybrid: lacks prompts that allocate shared-Rust versus Flutter/Tauri/Axum responsibilities and prove one cross-surface workflow.
  - Flutter-only: lacks FFI codegen, simulator/device, persistence/restart, and platform-parity prompt stages.
  - Tauri local inference: lacks model acquisition/fallback, offline proof, packaging-equivalent launch, Assistant UI/PEM/PGlite layering, and diagnostic recovery prompts.
  - Automation: lacks workflow-state, approval authority, resumability, event replay, artifact, and destructive-tool checkpoint prompts.
  - Multi-tenant SaaS: lacks threat-model, tenancy/RLS, identity/authorization, BYOK secret boundary, realtime isolation, and anonymous-mode decision prompts.
  - Local agent client: lacks MCP trust, file grants, skill discovery, conversation/event storage, model routing, approval denial, and audit-replay prompts.
  - Ideation studio: lacks falsification rubric, contradictory-evidence search, experiment design, scoring, decision journal, and skill-generation thresholds.
  - Native Rust agent: lacks capability classification, adapter selection, one-core constraint, generator invocation, consumer contract tests, Docker proof, and skill-versus-agent decision prompts.
  - Multi-cloud deployment: lacks source locks, build/attestation, digest mirroring, Compose profile, CNPG, GKE/AKS/EKS render, GitOps promotion, ingress/gateway/TLS option, and no-direct-deploy prompts.
  - Branded docs portal: lacks content classification, canonical-source choice, information architecture, Flat 2.0/KnowMe visual gate, local search, Pages/container, sanitization, accessibility, screenshot, and link-recovery prompts.
- The harness section must be six real playbooks rather than one compatibility paragraph:
  - Codex: `AGENTS.md` discovery, project skills/plugins, plan/approval boundaries, CLI/app examples, evidence capture, and handoff.
  - Claude Code: `CLAUDE.md`, skills/plugins, hooks, subagents, non-interactive/headless flags, permission modes, session continuation, budgets, and streaming evidence.
  - OpenCode: project skill paths, named primary/subagents, allow/ask/deny permissions, commands, MCP, ACP, and producer/critic separation.
  - Kimi Code CLI: config TOML, skill directories, plugins/hooks/MCP, plan versus auto, non-interactive output, ACP, step limits, and handoff.
  - Google Antigravity: workspace/global skills, plugins, hooks, MCP, SDK/CLI distinction, approvals, artifact export, and installed-version checks.
  - Zed: native Agent Panel versus ACP external agents versus terminal threads, per-path auth/config ownership, tool permissions, MCP/skills, review surface, and thread handoff.
- Model claims are reachable but not yet audit-grade. Routing prose must be generated from a dated registry and show source sufficiency, exact model IDs, availability, and confidence. A reachable family page is insufficient when a prompt names an exact API model or harness-only alias.
- The guide needs executable loop examples. The Feynman skill, KBD lifecycle, Karpathy recorder, skill creator, and native-agent creator already define concrete artifacts and commands, but the guide currently paraphrases them instead of teaching users how to run them.

RESEARCH-BACKED PUBLICATION FINDINGS
- The existing Docusaurus prompting plugin instance is the correct ownership boundary; official Docusaurus documentation supports multiple docs-plugin instances and a docs path relative to the site directory.
- The lowest-drift source arrangement is to make `docs/prompting` the canonical content tree and configure the prompting plugin to read `../docs/prompting`. If that path fails a scratch build, use a deterministic prebuild copy with a generated-file banner and parity check; do not maintain hand-written root and site summaries.
- The required public information architecture is materially larger than two pages: start-here/prompt contract; loop guides; model-routing guide and generated registry view; six harness playbooks; ten scenario recipes; OpenAI Proxy case study; skill-versus-agent guide; verification/recovery guide; and a source/research policy. Autogenerated nested sidebars can expose this without a hand-maintained route list.
- Local search is already configured for `/prompting` and should index new pages automatically. The Pages workflow is already a suitable custom static-site workflow; implementation should extend content and verification rather than replace the deployment platform.
- Publication must keep raw `.prometheus`/private-wiki/session material out of the site. The sanitizer must scan whichever canonical source tree Docusaurus consumes, and a route/sitemap assertion must prove every required page was built.
- A detailed guide cannot be verified by word count. It needs machine-checkable recipe headings/metadata plus at least one complete scenario exercised in Codex and one ACP/CLI path exercised through OpenCode, Kimi, or Zed.

OFFICIAL SOURCE SET (accessed 2026-07-18)
- Codex: https://developers.openai.com/codex/learn/best-practices ; https://developers.openai.com/codex/agent-configuration/agents-md ; https://developers.openai.com/codex/build-skills ; https://developers.openai.com/codex/plugins
- Claude Code: https://docs.anthropic.com/en/docs/claude-code/cli-reference ; https://docs.anthropic.com/en/docs/claude-code/skills ; https://docs.anthropic.com/en/docs/claude-code/sdk
- OpenCode: https://opencode.ai/docs/skills/ ; https://opencode.ai/docs/agents/ ; https://opencode.ai/docs/mcp-servers/ ; https://opencode.ai/docs/acp/
- Kimi Code: https://www.kimi.com/code/docs/en/kimi-code-cli/reference/kimi-command.html ; https://www.kimi.com/code/docs/en/kimi-code-cli/customization/plugins.html ; https://www.kimi.com/code/docs/en/kimi-code/models.html
- Zed: https://zed.dev/docs/ai/external-agents ; https://zed.dev/docs/ai/tool-permissions ; https://zed.dev/docs/ai/mcp
- Antigravity: https://antigravity.google/docs/skills ; https://antigravity.google/docs/cli/plugins ; https://antigravity.google/docs/sdk/overview
- Docusaurus/GitHub Pages: https://docusaurus.io/docs/api/plugins/@docusaurus/plugin-content-docs ; https://docusaurus.io/docs/docs-multi-instance ; https://docusaurus.io/docs/deployment ; https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site
- Model sources: the URLs recorded in `docs/prompting/model-registry.yaml` were individually retrieved successfully; capability claims still require field-level evidence during implementation.

BUILD HEALTH
- build check: [PASS] — `node docs/prompting/validate-model-registry.mjs` validated 14 entries; `npm --prefix site run build` passed sanitization and produced the Docusaurus static build.
- known violations: The background `prometheus-research` daemon failed to progress and was cancelled; KBD reminder/waypoint fields contain stale prior-phase data; no detailed guide routes exist.
- test coverage: [MINIMAL] — current checks verify structural build/sanitization, not content completeness, source freshness, harness correctness, or scenario execution.

CONSTRAINT CHECK
- AGENTS.md violations: The current source is not a code-architecture violation, but its public claim that a full guide exists is unsupported by the published routes. No raw private wiki material was found in the site.
- constraints.md violations: NONE observed in current prompting code. Future scenario text must preserve shared-Rust ownership, PEM 3.x instead of TanStack Query, Shadcn/Assistant UI, platform layering, secret boundaries, and runtime-verification requirements.

GOAL PROGRESS
- Publish comprehensive guide in source and site: [NOT MET] — only compact source summaries and two public summary pages exist.
- Ten complete copyable scenario recipes: [NOT MET] — ten scenario outlines exist; zero meets the required staged-prompt schema.
- Six actual harness playbooks: [NOT MET] — six paragraphs exist; no operational examples.
- Dated official-source model registry and generated role routing: [PARTIAL] — 14 reachable-source entries exist; generation, field-level evidence, and freshness enforcement are missing.
- Teach all requested loops with boundaries and termination: [PARTIAL] — concepts and some guardrails exist; executable workflows and artifacts are missing.
- OpenAI Proxy case study and skill-versus-agent decision: [PARTIAL] — a short summary exists; source evidence, lineage, current delta, and a usable decision framework are missing.
- Navigable, searchable, sanitized, verified publication: [PARTIAL] — infrastructure passes and the two pages are live; required content/routes and completeness verification are absent.

ANALYZE/PLAN INPUTS
- No user decision is blocking analysis. The default should be one canonical `docs/prompting` source tree consumed directly by the existing prompting plugin, with a deterministic-copy fallback only if a scratch Docusaurus build disproves external-path support.
- Analysis must convert the required recipe schema, six harness capability matrices, model evidence rules, case-study boundaries, and site route inventory into explicit change units and acceptance checks.
- Representative execution should be bounded: one full hybrid recipe in Codex and one ACP/CLI recipe in a second harness are sufficient for publication proof; all ten recipes still require structural validation.
- The next stage must correct KBD state drift before using waypoint metadata to generate examples.

SYCOPHANCY REVIEW
- The required detector scored this assessment 0.018 and found only a low-severity S-07 length signal. The length is retained because the assessment must enumerate ten scenario gaps, six harness gaps, publication findings, and evidence. No approval inflation, consensus following, requirement softening, or scope endorsement was detected.

ASSESSMENT COMPLETE
