# Decision log — build-detailed-prompting-guide

## 2026-07-18T06:41:53Z — Retain Docusaurus and GitHub Pages

**Options:** retain the existing Docusaurus stack; migrate to Astro Starlight; create a
separate documentation repository.
**Decision:** retain Docusaurus 3, its prompting plugin instance, local search, and the
current Pages Actions workflow.
**Provenance:** assessment build evidence, live Pages routes, official Docusaurus and
GitHub documentation.
**Rationale:** publication infrastructure is working. The unmet requirement is detailed
content and evidence, not framework capability. A migration would add unrelated work.

## 2026-07-18T06:41:53Z — One canonical prompting source

**Options:** edit root and site copies; consume root docs directly; generate a copy.
**Decision:** make `docs/prompting` canonical and configure the existing prompting
plugin to consume `../docs/prompting`. Use a deterministic generated copy only if a
clean scratch build disproves parent-path support.
**Provenance:** Docusaurus `plugin-content-docs` path contract and current duplication
failure.
**Rationale:** two editable trees already allowed the public summaries to claim content
that was never published.

## 2026-07-18T06:41:53Z — Standard validation plus project semantics

**Options:** hand-roll all validation; use a frontmatter-only remark plugin; combine
Ajv, Linkinator, Playwright, axe, and small project scripts.
**Decision:** adopt Ajv, Playwright, and axe; adapt Linkinator; build only the
Prometheus-specific semantic rules. Reject the stale frontmatter-only plugin.
**Provenance:** npm registry metadata and official project documentation.
**Rationale:** battle-tested tools cover generic mechanics, while repository-owned code
must enforce skill references, staged prompts, architecture, evidence, and routing.

## 2026-07-18T06:41:53Z — Preserve harness differences

**Options:** one universal harness command; six official-source playbooks with a shared
Agent Skills baseline.
**Decision:** use Agent Skills only for portable package structure and document Codex,
Claude Code, OpenCode, Kimi, Antigravity, and Zed separately.
**Provenance:** official harness documentation retrieved during assessment and Analyze.
**Rationale:** permissions, session ownership, plugins, headless modes, ACP, and evidence
capture are not portable merely because `SKILL.md` is portable.

## 2026-07-18T06:41:53Z — Registry-derived model routing

**Options:** copy routing claims into prose; generate views from the dated registry.
**Decision:** keep a machine registry with claim-level evidence and generate public role
tables from it.
**Provenance:** all current source URLs were reachable, while the existing validator was
shown to validate only field presence and HTTPS syntax.
**Rationale:** generated guidance prevents model IDs, context, availability, and roles
from drifting independently.

## 2026-07-18T06:41:53Z — Treat OpenAI Proxy as reference evidence

**Options:** present the repository as untouched generator output; omit it; document the
generator-to-current delta.
**Decision:** use it as a source-inspected case study and distinguish generated,
subsequently added, verified, inferred, and unsupported behavior.
**Provenance:** current source, route definitions, package layout, and commit history.
**Rationale:** the product is valuable evidence, but an unqualified lineage claim or
undocumented subscription-authentication guidance would be inaccurate.

## 2026-07-18T06:41:53Z — Skill versus native agent boundary

**Decision:** create a skill for repeatable host-executed instructions. Create a typed
native agent when the capability owns a process, protocol endpoint, durable state,
concurrency, authentication, deployment, or independent release lifecycle.
**Provenance:** Agent Skills specification, current orchestration skill, native-agent
creator contract, and OpenAI Proxy source.
**Rationale:** lifecycle ownership is a more reliable boundary than feature complexity.
