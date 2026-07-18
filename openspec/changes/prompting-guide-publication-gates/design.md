## Context

The existing Pages workflow and Docusaurus production build work, but they expose only
two short prompting routes and validate neither recipe completeness nor real harness
use. The preceding changes create canonical content, data contracts, playbooks,
recipes, and orchestration. This change integrates them and makes truthful publication
an observable release property.

## Goals / Non-Goals

**Goals:**

- Publish every required page through the existing KnowMe site.
- Layer fast deterministic content checks before browser and external checks.
- Require representative real-harness evidence for phase certification.

**Non-Goals:**

- Replacing Docusaurus or GitHub Pages.
- Hosting server-side applications on Pages.
- Treating automated axe output as complete accessibility certification.

## Decisions

### Order gates from deterministic and fast to environmental

The command chain will run sanitization and generation drift first, then Ajv and
semantic/source/architecture validation, Docusaurus build, route/search/sitemap
assertions, internal links, bounded external links, Playwright, and axe. This gives
fast failures while retaining browser-level evidence.

### Adopt focused dependencies, keep policy in project scripts

Ajv, Playwright Test, and `@axe-core/playwright` are adopted (`cand-003`, `cand-005`,
`cand-006`). Linkinator is adapted with retries/timeouts/allowlists (`cand-004`).
Project-owned scripts encode Prometheus-specific recipe, source, route, and skill
policies. The existing local search and Pages workflow remain (`cand-002`, `cand-011`).

### Separate build eligibility from phase certification

Deterministic content/site/browser gates determine whether Pages may deploy.
Representative Codex and ACP/CLI execution evidence determines whether the KBD phase
may be certified complete. This avoids making every docs build launch an autonomous
harness while preventing documentation-only self-certification.

### Store execution fixtures as sanitized evidence manifests

Fixtures will record commands, artifact hashes/paths, declared authority, exit status,
public observations, critic verdict, failures/recovery, and retention IDs. Raw chat,
credentials, private wiki pages, and personal paths are excluded.

### Visual checks cover both themes and sizes

Playwright projects will cover representative desktop/mobile viewports and theme
states. Screenshots support human Flat 2.0/branding review; axe and keyboard checks
cover machine-detectable and interaction issues.

## Risks / Trade-offs

- **[Browser dependencies slow CI]** → cache browsers, test representative routes, and
  apply explicit timeouts.
- **[External link checks are flaky]** → keep internal links fatal and separate;
  bound/retry external checks with a reviewed policy.
- **[Local search output format changes]** → assert user-observable search results in
  Playwright in addition to inspecting generated data.
- **[Representative harness requires authentication]** → select one already installed
  and authenticated ACP/CLI harness at execution time; absence blocks certification,
  not deterministic site authoring.
- **[Sanitized evidence omits useful debugging detail]** → retain the private superset
  in authorized Karpathy memory and publish only reviewed manifests.

## Migration Plan

1. Add dependencies and scripts with deterministic validators first.
2. Point the prompting plugin to the canonical source and prove all required routes.
3. Add Playwright/axe and bounded link checks locally, then to pull-request CI.
4. Extend Pages upload dependencies only after local/fresh-clone proof.
5. Capture representative harness evidence and mark phase certification separately.
6. Roll back browser/external gates independently if environmental instability is
   proven; deterministic privacy, content, and route gates remain mandatory.

## Open Questions

Execution will select OpenCode, Kimi, or Zed for the ACP/CLI fixture based on installed
authenticated capability. No architecture or content decision is blocked.
