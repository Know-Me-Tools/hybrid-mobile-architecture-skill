# prompting-guide-verification Specification

## Purpose
Define the durable verification contract for the Prometheus/KnowMe prompting
guide, including schema, semantic, link, browser, accessibility, representative
harness, GitHub Pages, fresh-clone, and scratch-skill gates required before the
guide can be called complete.
## Requirements
### Requirement: Schema and semantic validation
Ajv SHALL validate registry, recipe, and harness data shapes. Project semantic checks
MUST validate required prompt blocks, non-empty content, skill references,
producer/critic separation, role vocabulary, architecture rules, evidence/source
sufficiency, authority boundaries, artifacts, recovery, and public-boundary stop
conditions.

#### Scenario: Structurally valid content is semantically incomplete
- **WHEN** a file passes JSON Schema but references an absent skill, duplicates
  producer and critic, or lacks executable verification evidence
- **THEN** semantic validation SHALL fail with a source-specific diagnostic

### Requirement: Source and link validation
Internal links SHALL be fatal in the Docusaurus build. Linkinator SHALL check the
built site and selected official external sources with bounded timeouts, retries, and
a reviewed allowlist; transient external failure SHALL remain distinguishable from an
invalid internal route.

#### Scenario: Internal route is broken
- **WHEN** any guide link targets a missing built route or fragment
- **THEN** the required build gate SHALL fail immediately

#### Scenario: External vendor site rate-limits CI
- **WHEN** a reviewed official source returns a transient rate-limit or availability
  error after bounded retries
- **THEN** the external-link report SHALL identify the condition according to policy
  without weakening internal-link enforcement

### Requirement: Browser and accessibility verification
Playwright SHALL verify representative start, harness, loop, scenario, case-study, and
model routes at desktop and mobile viewports in light and dark themes, including
navigation, local search, copyable prompts, Mermaid, responsive layout, and focus.
`@axe-core/playwright` SHALL scan representative routes, supplemented by keyboard and
visual review.

#### Scenario: Prompt can be copied
- **WHEN** a user activates the copy control on a required staged prompt
- **THEN** the clipboard SHALL contain the complete prompt text in reading order and
  the control SHALL expose an accessible status

#### Scenario: Automated accessibility violation is found
- **WHEN** axe reports a configured-impact violation on a representative route
- **THEN** the publication gate SHALL fail with route and rule evidence

### Requirement: Route and search inventory gate
The verification system SHALL maintain the required stable route inventory and assert
that every route appears in generated output, sitemap, and local-search data.

#### Scenario: Ten recipes exist but one is not indexed
- **WHEN** all recipe files build but a scenario is absent from search or sitemap
- **THEN** release validation SHALL fail rather than calling publication complete

### Requirement: Representative harness execution evidence
Before the phase is certified, one full-hybrid recipe SHALL be exercised in Codex and
one representative recipe SHALL be exercised in an installed, authenticated ACP/CLI
harness selected from OpenCode, Kimi, or Zed. Evidence MUST record invocation, durable
artifacts, authority, failures/recovery, public-boundary observation, critic verdict,
and retention without exposing private session content.

#### Scenario: Only documentation tests pass
- **WHEN** schemas, links, and browser checks pass but representative harness execution
  evidence is absent
- **THEN** the guide MAY build but phase certification SHALL remain incomplete

### Requirement: GitHub Pages release gate
The pinned Pages workflow SHALL run sanitization, generation-drift, schema, semantic,
source, architecture, route, link, production-build, browser, and accessibility checks
before uploading the static artifact. It MUST NOT perform cluster deployment, secret
provisioning, or server-side application release.

#### Scenario: Any required gate fails on main
- **WHEN** a required validation command exits non-zero
- **THEN** the Pages artifact SHALL not be uploaded or deployed

### Requirement: Fresh-clone and scratch-skill proof
Completion SHALL include a frozen install and production build from a fresh clone plus
a scratch-project exercise proving the upgraded orchestration skill can classify a
scenario, resolve its guide references, select producer/critic roles, and enforce the
runtime verification gate.

#### Scenario: Local ignored artifacts mask a dependency
- **WHEN** the clean clone lacks ignored build outputs or caches
- **THEN** install, validation, and build SHALL still succeed from committed sources
  and lockfiles
