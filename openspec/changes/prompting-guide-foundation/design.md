## Context

The site already builds with Docusaurus 3.10.1, an isolated prompting docs plugin,
local search, sanitization, and GitHub Pages. The defect is fragmented ownership and
weak content/evidence validation: root prompting documents are partial, site-local
documents are shorter summaries, and the current registry validator checks only field
presence and URL syntax.

## Goals / Non-Goals

**Goals:**

- Establish one editable prompting source.
- Define contracts that later playbooks and recipes can satisfy mechanically.
- Make model guidance traceable to dated official evidence and generated from one
  registry.
- Extend the existing privacy boundary to the canonical source.

**Non-Goals:**

- Migrating to Astro, changing GitHub Pages, or upgrading Docusaurus.
- Authoring the detailed harness, loop, scenario, or case-study pages in this change.
- Publishing raw private memory or treating URL liveness as proof of a claim.

## Decisions

### Consume the root source directly, with one bounded fallback

The prompting plugin will first be configured with `path: '../docs/prompting'` because
the official plugin contract resolves paths relative to the site. A clean build must
prove this before deleting site-local summaries. If repository/watch constraints make
that unsafe, a deterministic prebuild copy is allowed; it must be generated, carry a
warning banner, and be protected by a parity hash. Maintaining two editable trees is
not an option.

### Use JSON Schema for shape and project code for semantics

Ajv (`cand-003`) will validate recipe, harness, and registry schemas. A small Node
validator will enforce cross-file rules such as existing skill references,
producer/critic separation, source sufficiency, platform invariants, non-empty prompt
blocks, and public-boundary termination. The stale frontmatter-only plugin
(`cand-010`) is rejected because it covers less of the contract.

### Treat the model registry as data, not prose

Mutable claims and role routing will be generated into Markdown or MDX from the
validated registry. Stable prompting principles remain hand-authored. Entries will
store claim-level source references and confidence so a family page cannot silently
stand in for an exact model ID.

### Sanitize before Docusaurus reads content

Sanitization will scan `docs/prompting/` plus the existing site sources. The policy
will use explicit prohibited patterns and source classification, produce actionable
file/line diagnostics, and run before content generation and the production build.

## Risks / Trade-offs

- **[Parent-directory content behaves differently in CI]** → prove it in a fresh
  build before removing summaries and retain only the deterministic-copy fallback.
- **[Schema compliance creates superficial completeness]** → add semantic checks for
  non-empty prompts, role separation, architecture, evidence, and termination.
- **[Official pages change or disappear]** → date evidence, use a freshness policy,
  and keep failures explicit rather than silently reclassifying models.
- **[Generated routing obscures editorial judgment]** → retain reviewed stable
  principles beside the generated, visibly dated tables.

## Migration Plan

1. Add schemas, validators, evidence fields, and generation scripts without removing
   current content.
2. Prove direct canonical-source consumption in a clean build.
3. Move or rewrite the two site summaries into the root taxonomy, update sanitizer
   scope, and remove the editable duplicates.
4. Generate routing content and fail on uncommitted drift.
5. Roll back by restoring the previous plugin path; canonical source and schemas remain
   useful and no user data migration is involved.

## Open Questions

No blocking product decision remains. Execution must prove whether direct parent-path
consumption works with the pinned Docusaurus version; that proof selects the documented
fallback automatically.

## Analyze reuse evidence

- **cand-001 — Docusaurus/plugin-content-docs (adopt):** npm reported Docusaurus
  3.10.2/MIT/Node 20+ on 2026-07-18, while this project already proves its pinned
  3.10.1 build; official plugin documentation confirms a docs path relative to the
  site directory. Sources: <https://www.npmjs.com/package/@docusaurus/plugin-content-docs>,
  <https://docusaurus.io/docs/api/plugins/@docusaurus/plugin-content-docs>.
- **cand-002 — local search (adopt):** the active MIT repository supports Docusaurus
  v2/v3 offline search and npm 0.55.2 matches this project's installed version.
  Sources: <https://github.com/easyops-cn/docusaurus-search-local>,
  <https://www.npmjs.com/package/@easyops-cn/docusaurus-search-local>.
- **cand-003 — Ajv (adopt):** npm reported 8.20.0/MIT and official documentation
  confirms JSON Schema 2020-12 support. Ajv covers shape only; project semantics remain
  explicit code. Sources: <https://www.npmjs.com/package/ajv>,
  <https://ajv.js.org/json-schema.html>.
