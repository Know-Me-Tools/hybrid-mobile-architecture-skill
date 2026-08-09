# KnowMe Builder

**Version 2.0.0-alpha.2 · governed agentic application generator and skill pack**

KnowMe Builder creates and adopts Flutter, Tauri/React, Axum, and Rust
applications without treating the consumer repository as disposable generator
output. It combines:

- a Rust CLI with ownership-aware generation and upgrades;
- explicit application profiles;
- typed UAR, A2UI, AG-UI, identity, policy, persistence, and native-bridge
  boundaries;
- 30 public, self-contained Agent Skills (one package skill and 29 companions);
- generated commands and advisory activation adapters for Claude Code, Codex,
  OpenCode, and Kimi; and
- conformance, security, documentation, and installation gates.

Public documentation:
[KnowMe Builder documentation](https://know-me-tools.github.io/hybrid-mobile-architecture-skill/)

Start with:

- [Installation](https://know-me-tools.github.io/hybrid-mobile-architecture-skill/reference/installation)
- [CLI reference](https://know-me-tools.github.io/hybrid-mobile-architecture-skill/reference/cli)
- [Generation profiles](https://know-me-tools.github.io/hybrid-mobile-architecture-skill/architecture/profiles)
- [All 30 public skills](https://know-me-tools.github.io/hybrid-mobile-architecture-skill/reference/skills)
- [Services and boundaries](https://know-me-tools.github.io/hybrid-mobile-architecture-skill/reference/services)
- [Utilities and automation](https://know-me-tools.github.io/hybrid-mobile-architecture-skill/reference/utilities)
- [Common use cases](https://know-me-tools.github.io/hybrid-mobile-architecture-skill/reference/use-cases)

## Authority model

Three systems have deliberately separate jobs:

| System | Authority |
|---|---|
| KnowMe Builder | Application architecture, templates, typed adapters, skills, and conformance |
| Prometheus | Project UUID identity, signed KBD events, CRDT claims/conflicts, typed lifecycle, audit, and durable learning |
| Universal Agent Runtime | Agent runs, providers, prompts, governed tools, cancellation, recovery, and A2UI/AG-UI events |

Builder activation hooks are advisory. They never own lifecycle or mutation
authority. Generated applications must not introduce a second agent loop beside
UAR.

## Install

Build and install the CLI from a trusted checkout:

```bash
cargo build --release --locked --manifest-path tools/knowme-builder/Cargo.toml
install -m 0755 tools/knowme-builder/target/release/knowme-builder \
  "$HOME/.cargo/bin/knowme-builder"
knowme-builder --version
```

Install all 30 portable skills directly from the Git repository URL:

```bash
npx skills add https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill \
  --skill '*' -a claude-code -a codex -a opencode -g -y
```

Install the complete native harness package from a trusted checkout:

```bash
bash scripts/install-global-harnesses.sh
```

That registers the Git source through the supported Claude/Codex marketplace
CLIs, installs OpenCode skills plus its native advisory plugin, and records an
ownership receipt. CLI compilation, MCP configuration, and the full Prometheus
runtime are opt-in with `--with-cli`, `--with-mcp`, and `--with-prometheus`.

Verify:

```bash
knowme-builder manifest check
knowme-builder --json doctor --path .
prometheus doctor --json
```

See [docs/global-harness-installation.md](docs/global-harness-installation.md)
for native plugin registration and per-harness verification.

## Generate a project

Profiles are explicit:

```bash
knowme-builder new my-app \
  --profile sovereign-hybrid \
  --mode runnable \
  --check

knowme-builder new my-app \
  --profile sovereign-hybrid \
  --mode runnable
```

Available profiles:

| Profile | Architecture |
|---|---|
| `sovereign-hybrid` | Flutter mobile, Tauri desktop, Rust adapters, embedded/service UAR |
| `governed-web-shell` | React, Axum BFF, service UAR, PEM/PGlite, optional legacy embed |
| `flutter-mobile` | Flutter, Rust, embedded UAR |
| `tauri-desktop` | Tauri/React, Rust, service or in-process UAR facade |
| `axum-web` | React, Axum, service UAR |

`runnable` emits a deterministic agentic vertical slice. `skeleton` may contain
explicitly declared unsupported surfaces and TODOs.

## Adopt an existing application

Do not regenerate an evolved application:

```bash
knowme-builder adopt existing-app \
  --profile governed-web-shell \
  --check

knowme-builder adopt existing-app \
  --profile governed-web-shell \
  --apply
```

Adoption records profile and package state, installs skills, and creates a
project policy overlay without claiming ownership of existing application
files.

## Ownership-aware upgrades

```bash
knowme-builder upgrade existing-app --check
knowme-builder upgrade existing-app --apply
```

`.knowme-builder/generated.lock.json` records the generated path, template,
source digest, last installed digest, ownership, and version. The Builder
replaces only managed files that still match their last installed digest.
Modified files produce a conflict report and proposed replacement.

## Add capabilities

```bash
knowme-builder add feature conversations --path .
knowme-builder add auth verified-session --path .
knowme-builder add module reporting --path .
knowme-builder add legacy-embed frozen-portal --path .
```

Additions are emitted under `.knowme-builder/additions` for deliberate
integration. They do not overwrite feature code.

## Skill bundle

`skills` is the canonical public tree. It contains the package-level
`hybrid-mobile-architecture` skill plus 29 project companions:

- quality and release: `a11y-gate`, `flutter-golden-ui`,
  `tauri-ui-review`, `reference-ui-fidelity`,
  `hybrid-runtime-verification`;
- agent UI and runtime: `a2ui-surface-contract`, `agui-event-contract`,
  `content-block-ui`, `local-inference-lanes`,
  `agent-runtime-security`, `axum-agent-gateway`,
  `persona-scoped-agent`;
- application architecture: `entity-graph-web-shell`, `mini-app-module`,
  `legacy-app-embed`, `pem-local-first`;
- data and privacy: `sync-doctrine`, `peer-profile-sync`, `client-rag`,
  `anonymized-replica`, `domain-glossary-service`;
- design: `hybrid-design-tokens`, `mobile-navigation`,
  `tauri-custom-titlebar`;
- build, delivery, and workflow: `dependency-pin-discipline`,
  `deploy-hybrid-agentic-stack`, `build-branded-docusaurus`,
  `orchestrate-prometheus-application`, `karpathy-progress-memory`.

Install or check project copies:

```bash
knowme-builder skills install --path .
knowme-builder skills check --path .
```

Generated harness trees must not be edited independently:

```bash
bash scripts/sync-harness-skills.sh
bash scripts/sync-harness-skills.sh --check
```

## Application runtime contract

A runnable profile must support:

```text
message
  → UAR run
  → model stream
  → governed tool
  → A2UI/AG-UI event
  → persisted projection
  → restart recovery
```

UI layers are projections. They do not own provider routing, prompts, tools,
policy, or run lifecycle.

Application-facing tool requests go through UAR governance:

1. trusted server/tool resolution;
2. JSON Schema validation;
3. independent effect classification;
4. verified identity and policy;
5. confirmation when required;
6. idempotent, bounded, cancellable execution;
7. result validation/redaction; and
8. immutable audit outcome.

## Verification

Core package checks:

```bash
node scripts/check-builder-authority.mjs --release
node scripts/check-skill-contracts.mjs
node scripts/check-runtime-security.mjs
node scripts/check-prometheus-boundary.mjs
node scripts/sync-skill-resources.mjs --check
bash scripts/sync-harness-skills.sh --check
bash scripts/check-git-url-discovery.sh
bash scripts/test-harness-installer.sh
cargo test --locked --manifest-path tools/knowme-builder/Cargo.toml
```

Documentation:

```bash
cd site
npm ci
npm run release:check
```

A build is not runtime evidence. Use `hybrid-runtime-verification` for a clean
checkout, production artifact, real launch, persistence, public workflow, and
physical-device proof when native bridges or local inference are involved.

## Repository map

| Path | Purpose |
|---|---|
| `builder.manifest.json` | Canonical package, profile, skill, template, target, and harness manifest |
| `tools/knowme-builder` | Rust CLI |
| `skills` | Canonical 30-skill public source |
| `templates/project-skills` | Generated 29-skill project/scaffold projection |
| `assets/templates` | Maintained profile, feature, adapter, native, build, and contract templates |
| `compatibility` | Prometheus and UAR external contract descriptors |
| `versions.toml` | Builder application-stack version authority |
| `scripts` | Bootstrap, generation, compatibility, audit, and installation utilities |
| `site` | Public Docusaurus source and publication gates |
| `docs` | Specifications, evidence, prompting guides, research, and documentation map |

Read [docs/documentation-map.md](docs/documentation-map.md) before treating a
dated assessment or research file as current authority.

## Release status

`2.0.0-alpha.2` adds standards-conformant Git-URL distribution and current
Prometheus 1.7 integration to the production-convergence architecture and
consumer adoption support. Stable `2.0.0` remains gated by the complete consumer CI
suites and current physical-device certification required by their profiles.
