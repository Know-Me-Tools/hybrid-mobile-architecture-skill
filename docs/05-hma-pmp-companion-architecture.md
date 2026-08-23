# HMA × PMP × Companion — Joint Architecture, Functional Specification, and Implementation Plan

> **Repo:** `/Users/gqadonis/Projects/hybrid-mobile-architecture-src/`
> **Companion:** `/Users/gqadonis/Projects/prometheus/prometheus-companion/`
> **Skill pack:** `/Users/gqadonis/Projects/prometheus/prometheus-skill-pack/`
> **Author:** Mavis (`MiniMax-M3`) for Travis James / Prometheus AGS
> **Date:** 2026-08-20
> **Status:** v0.1.0 — first draft for review
> **Companion docs:**
> - Architecture review: `prometheus-skill-pack/docs/audits/2026-08-20-skill-pack-architecture-review.md`
> - Companion spec: `prometheus-companion/docs/00-architecture-and-implementation-plan.md`
> - AGENTS.md: `prometheus-companion/AGENTS.md`
> - CLAUDE.md: `prometheus-companion/CLAUDE.md`
> **TJ-ARCH-MOB-001 compliant.**

---

## Table of contents

0. [Why this document exists](#0--why-this-document-exists)
1. [The three-repo topology](#1--the-three-repo-topology)
2. [The HMA skill map (which HMA skill uses which PMP skill)](#2--the-hma-skill-map)
3. [Git-installable HMA (the marketplace contract)](#3--git-installable-hma)
4. [Connected skill packages — the new concept](#4--connected-skill-packages--the-new-concept)
5. [Gaps in HMA + the new skills to add](#5--gaps-in-hma--the-new-skills-to-add)
6. [Hooks reliability — the HMA-side fixes](#6--hooks-reliability--the-hma-side-fixes)
7. [Service log monitoring + self-healing — the runtime fix](#7--service-log-monitoring--self-healing)
8. [Realtime skill-refiner loop](#8--realtime-skill-refiner-loop)
9. [Adversarial review + sycophancy correction applied](#9--adversarial-review--sycophancy-correction-applied)
10. [What the HMA repo must do to comply](#10--what-the-hma-repo-must-do-to-comply)
11. [Implementation phases](#11--implementation-phases)
12. [Open questions](#12--open-questions)

---

## 0 · Why this document exists

The **Prometheus Companion** (the tray-resident Tauri 2.0 app
that supervises the entire substrate) is a **consumer** of skill
packages. The **prometheus-skill-pack** is the substrate's
authoritative skill set. The **hybrid-mobile-architecture**
(HMA) repo is the skill package that **builds the apps that
consume the substrate**.

Three repos, three roles, one user. Until now each repo shipped
its own AGENTS.md and its own architecture doc, with no formal
contract between them. This document is that contract.

It is grounded in three reference documents:

1. The **architecture review** of the prometheus-skill-pack
   (`docs/audits/2026-08-20-skill-pack-architecture-review.md`),
   which names the reliability, desktop, mobile, build-time,
   hooks, skill-hit-rate, and extension-model gaps in the
   substrate.
2. The **Companion spec**
   (`prometheus-companion/docs/00-architecture-and-implementation-plan.md`),
   which lays out the 4-layer CLEAN frontend, the custom
   title bar, the PEM 3.x entity integration, the A2UI
   surface, the P2P pairing, and the 10-week punch list.
3. The **HMA skill inventory** (this repo's `skills/`,
   `.agents/skills/`, `.claude/skills/`, `.codex/skills/`,
   `.kimi-code/skills/`, `.opencode/skills/`, and
   `templates/project-skills/`), which is the existing surface
   the Companion must learn to manage.

What this document adds is the **joint design** the three
specs need but do not individually state:

- HMA must be **git-installable** as a Claude Code marketplace
  so the Companion can install it from a `git clone` of this
  repo.
- The Companion must be able to **discover, install, upgrade,
  and monitor** the HMA package (and any other connected
  skill package) the same way it monitors substrate services.
- The HMA skill set must **fill the gaps** the architecture
  review and the Companion spec surfaced, so the joint
  system works end-to-end.
- The hook chain must be **reliable enough** to never silently
  drop a hook event (the 9 weaknesses from the architecture
  review §6).
- A **realtime skill-refiner loop** must detect a bug in a
  currently installed skill and trigger the
  `skill-refiner` skill to fix it without a full re-install.

If any of these are broken, the joint system fails. The
failure modes are concrete:

| Failure | User-visible symptom |
|---|---|
| HMA not git-installable | Companion can't add the HMA package; user must `git clone` by hand and the AGENTS.md doesn't pick up the HMA rules |
| Hook chain unreliable | "the loop didn't run"; "skill didn't fire"; "the doc says I have a skill but the model didn't see it" |
| No log monitoring | a LaunchAgent is silently down for 4 hours before the user notices; the "Connected Skill Packages" page is a lie |
| No skill-refiner loop | a buggy skill ships a fix, but the user has to manually run `skill-refiner`; the fix doesn't reach the running system |
| No gaps filled | the Companion tries to consume HMA skills that don't exist (e.g. `tauri-tray-app`, `connected-skill-packages`); the build fails |

This document is what makes the joint system work.

---

## 1 · The three-repo topology

```
┌─────────────────────────────────────────────────────────────────────────┐
│  prometheus-companion (Tauri 2.0 app)                                  │
│                                                                         │
│  - Tray-resident UI (the operator's primary surface)                   │
│  - Supervises the substrate (services, daemons, queues)                │
│  - Installs, upgrades, monitors "connected skill packages"             │
│  - Renders A2UI surface; consumes PEM 3.x; runs AG-UI                  │
│  - Self-heals via launchd / systemd                                    │
│  - **Consumes HMA skills via the marketplace**                          │
│                                                                         │
│  Skills: `prometheus-companion/AGENTS.md` (the rule book)              │
│  Hooks:  `prometheus-companion/hooks/hooks.json` (per Phase 0)         │
└─────────────────────────────────────────────────────────────────────────┘
            │                                │
            │ consumes                       │ consumes
            ▼                                ▼
┌────────────────────────────┐   ┌──────────────────────────────────┐
│  prometheus-skill-pack      │   │  hybrid-mobile-architecture     │
│  (the substrate)            │   │  (the HMA skill package)         │
│                             │   │                                  │
│  - 4-layer PMPO pipeline     │   │  - 35+ skills for hybrid app    │
│  - 13-plugin marketplace     │   │    builds (Tauri + React +      │
│  - forge-rs, knowledge,      │   │    Flutter + Axum)               │
│    sovereign-sync, exec,    │   │  - marketplace.json + plugin.json│
│    research, etc.           │   │  - **git-installable**           │
│  - In-process substrate      │   │  - tokens, a11y, sync, mobile   │
│  - 7 LaunchAgents (legacy)   │   │  - hooks reliability fixes        │
│                             │   │  - launchagent-supervisor        │
│  Skills: `prometheus-skill- │   │  - connected-skill-packages      │
│  pack/skills/**`            │   │  - realtime-skill-refiner        │
└────────────────────────────┘   └──────────────────────────────────┘
            │
            │ HMA skills USE PMP skills
            ▼
  Every HMA skill that touches the substrate
  (orchestrate-prometheus-application, deploy-hybrid-
  agentic-stack, axum-agent-gateway, a2ui-surface-contract,
  agui-event-contract, pem-local-first, sync-doctrine, …)
  documents which PMP skill it delegates to.
```

The Companion does **not** know the HMA skill set directly. The
Companion installs the HMA marketplace, the HMA plugin then
registers its skills with Claude Code (or whichever harness
the operator is using), and the operator's session picks up
the skills through the normal Claude Code plugin mechanism.
The Companion's "Connected Skill Packages" page is the
**read-side view** of that same mechanism — it does not
duplicate the registration.

---

## 2 · The HMA skill map

Every HMA skill that touches the substrate documents the PMP
skill(s) it delegates to. This map is the **single source of
truth** for the "HMA uses PMP" relationship.

| HMA skill | Uses PMP skill(s) | Notes |
|---|---|---|
| `hybrid-mobile-architecture` | (meta) | Orchestrator. Always load. |
| `orchestrate-prometheus-application` | `process/pmpo-evolver`, `process/iterative-evolver`, `process/native-agent`, `learn/*` | PMPO control loop |
| `deploy-hybrid-agentic-stack` | `tools/forge-rs`, `substrate/prometheus-exec`, `substrate/liter-llm` | Full-stack deployment |
| `axum-agent-gateway` | `substrate/prometheus-exec`, `substrate/sovereign-sync` | Agent HTTP boundary |
| `a2ui-surface-contract` | `learn/ui-surface` | A2UI projection |
| `agui-event-contract` | `substrate/prometheus-exec` | AG-UI SSE |
| `pem-local-first` | `react/prometheus-entity-skills` (PEM 3.x plugin) | Local-first data layer |
| `entity-graph-web-shell` | (same) | React shell contract |
| `sync-doctrine` | (same) | Sync lane choice |
| `peer-profile-sync` | `substrate/sovereign-sync` | CRDT profile vault |
| `tauri-custom-titlebar` | `tauri/tauri-react-vite` | Title bar pattern |
| `tauri-ui-review` | (no PMP skill) | Pure UI checklist |
| `mobile-navigation` | (no PMP skill) | Pure UI rule |
| `hybrid-design-tokens` | (no PMP skill) | Token compiler |
| `a11y-gate` | (no PMP skill) | WCAG 2.2 AA |
| `flutter-golden-ui` | (no PMP skill) | Flutter equivalent of `tauri-ui-review` |
| `hybrid-runtime-verification` | `learn/hybrid-runtime-verification` | Completion gate |
| `karpathy-progress-memory` | `learn/karpathy-progress-memory` | Progress recording |
| `dependency-pin-discipline` | (no PMP skill) | Cross-stack |
| `client-rag` | `react/prometheus-entity-skills` | Client RAG |
| `content-block-ui` | `learn/ui-surface` | Chat content blocks |
| `reference-ui-fidelity` | (no PMP skill) | Reference review |
| `build-branded-docusaurus` | (no PMP skill) | Doc site |
| `domain-glossary-service` | (no PMP skill) | Domain glossary |
| `legacy-app-embed` | `substrate/prometheus-exec` | Legacy embed |
| `local-inference-lanes` | `tools/liter-llm`, `substrate/prometheus-exec` | On-device inference |
| `mini-app-module` | `substrate/skill-index` | Mini-app |
| `anonymized-replica` | `sync-doctrine`, `pem-local-first` | Privacy |
| `persona-scoped-agent` | `agents/*` | Persona agents |
| `agent-runtime-security` | `substrate/sovereign-sync`, `substrate/prometheus-exec` | Security |
| `openspec-*` (10 skills) | (no PMP skill) | OpenSpec change management |
| `source-command-opsx-*` (10 skills) | (same) | Codex command variants |

The map has 12 HMA skills that **delegate to PMP skills** and
~22 HMA skills that are **PMP-independent** (UI rules, design
tokens, OpenSpec, etc.).

**Implication:** when the HMA package is upgraded, the operator
**must** also be on a compatible PMP version. The Companion's
"Connected Skill Packages" page should display the
compatibility matrix. (`prometheus-skill-pack: 1.7.x` ↔
`hybrid-mobile-architecture: 2.0.x` is one valid combination;
mismatches should be flagged.)

---

## 3 · Git-installable HMA (the marketplace contract)

HMA is already a Claude Code marketplace:

```jsonc
// /Users/gqadonis/Projects/hybrid-mobile-architecture-src/marketplace.json
{
  "schema_version": "1.0",
  "skill": {
    "id": "hybrid-mobile-architecture",
    "name": "KnowMe Builder",
    "slug": "hybrid-mobile-architecture",
    "version": "2.0.0-alpha.2",
    "status": "prerelease",
    "visibility": "public",
    "tier": "professional",
    "repository": {
      "type": "git",
      "url": "https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill"
    },
    ...
  }
}
```

```jsonc
// /Users/gqadonis/Projects/hybrid-mobile-architecture-src/plugin.json
{
  "name": "hybrid-mobile-architecture",
  "displayName": "KnowMe Builder",
  "version": "2.0.0-alpha.2",
  "repository": {
    "type": "git",
    "url": "https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill"
  },
  "skills": ["./skills/hybrid-mobile-architecture", ...],
  "mcpServers": "./.mcp.json"
}
```

**That is already the git-installable surface.** The Companion
uses it the standard way:

```bash
# 1. Add the marketplace
git clone https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill \
  ~/.prometheus/skill-packages/hybrid-mobile-architecture
# 2. The harness marketplace manifest lives at
#    .claude-plugin/marketplace.json, so the clone is already
#    Claude Code marketplace-shaped
# 3. Register with the harness
claude plugin marketplace add ~/.prometheus/skill-packages/hybrid-mobile-architecture
claude plugin install hybrid-mobile-architecture@hybrid-mobile-architecture
```

**The new piece** the Companion adds is the
**"Connected Skill Packages" surface** that the operator sees.
The marketplace install is the wire; the Companion page is the
UX. Both must agree.

The HMA repo's job is to make step 1 work. To do that, the
repo must satisfy four conditions:

1. **The `.claude-plugin/marketplace.json` must be valid** (it is).
2. **The plugin.json must be valid, and agree on version** (it does).
3. **Every skill in `builder.manifest.json` `skills[]` must exist** —
   this is the "skill manifest matches the directory" check
   that §10 of this document makes a CI gate.
4. **The `install.sh` or `bootstrap.sh` (if any) must be
   idempotent** — the Companion re-runs install on upgrade.

This document adds a `scripts/verify-skill-manifest.sh` (see
§10) that gates condition 3.

### 3.1 The install path (what the Companion does)

```rust
// crates/prometheus-companion/src/commands/skill_packages.rs
#[tauri::command]
pub async fn install_skill_package(
    spec: SkillPackageSpec,    // { id, git_url, ref, sha? }
) -> Result<SkillPackageManifest, String> {
    let target = skill_package_root(&spec.id);
    if target.exists() {
        // upgrade: git pull --ff-only
        run_git(&target, &["fetch", "origin", &spec.git_ref]).await?;
        run_git(&target, &["reset", "--hard", &spec.sha_or_head()]).await?;
    } else {
        // install: git clone
        run_git_in(&skill_package_parent(), &[
            "clone", &spec.git_url, &spec.id, "--branch", &spec.git_ref,
        ]).await?;
    }
    // verify the marketplace contract (see §10)
    let manifest = read_marketplace_manifest(&target).await?;
    verify_skill_manifest(&target, &manifest)?;
    // register with the harness
    register_with_harness(&target).await?;
    Ok(manifest)
}
```

The Companion **never** writes to the HMA repo. It only clones,
verifies, and registers. The HMA repo is the source of truth.

---

## 4 · Connected skill packages — the new concept

A **connected skill package** is:

- A **git repository** (a marketplace) the Companion has
  cloned into `~/.prometheus/skill-packages/<id>/`
- A **marketplace manifest** (`marketplace.json`) at the repo
  root that declares plugins and skills
- A **set of plugins** (with `plugin.json`) that the operator
  has chosen to enable
- A **set of skills** the harness has registered (Claude Code's
  `.claude/skills/`, Codex's `.codex/skills/`, etc.)
- An **optional service** (if the package ships a binary or a
  LaunchAgent — HMA does not today, but the model allows it)
- A **compatibility matrix** with the PMP and with the
  Companion

The Companion's "Connected Skill Packages" page is a CRUD
surface over this:

- **List** — every package in `~/.prometheus/skill-packages/`,
  with its version, last-updated, enabled plugins, hot-reload
  status
- **Install** — `git clone <url>` + verify + register
- **Upgrade** — `git fetch + reset --hard <sha>` + re-verify
  + re-register
- **Disable / re-enable** — flip a flag in the harness's
  enabled-plugins set
- **Remove** — `rm -rf` the clone (with a confirmation)
- **View** — read the marketplace.json, plugin.json, and the
  SKILL.md frontmatter, render in the UI
- **Validate** — run `scripts/verify-skill-manifest.sh` against
  the package and show the result

### 4.1 The data model (PEM 3.x)

The Companion models connected skill packages as PEM entities:

```ts
// src/domain/entities/skill-package.ts
export const skillPackageEntity = defineEntity({
  name: 'skillPackage',
  privacyClass: 'public',
  fields: {
    id:           { type: 'id', clientId: true },
    tenantId:     { type: 'string', nullable: false, indexed: true },
    updatedAt:    { type: 'datetime', nullable: false, indexed: true },
    label:        { type: 'string', nullable: false },       // "KnowMe Builder"
    slug:         { type: 'string', nullable: false },       // "hybrid-mobile-architecture"
    version:      { type: 'string', nullable: false },       // "2.0.0-alpha.2"
    gitUrl:       { type: 'string', nullable: false },
    gitRef:       { type: 'string', nullable: false },
    installedSha: { type: 'string' },
    installPath:  { type: 'string', nullable: false },
    marketplaceJson: { type: 'string' },                     // parsed manifest as JSON
    enabled:      { type: 'boolean', nullable: false },
    enabledPlugins: { type: 'string[]' },                    // plugin names
    enabledSkills:  { type: 'string[]' },                    // skill names registered
    pmpCompatibility: { type: 'string' },                   // e.g. "1.7.x"
    lastValidatedAt: { type: 'datetime' },
    lastValidationResult: { type: 'enum', enum: ['ok', 'warn', 'fail', 'unknown'] },
  },
})
```

`sync-doctrine` lane: **relational** (server-authoritative LWW).
The git SHA is the natural conflict-resolution key.

### 4.2 The Companion page

```
┌────────────────────────────────────────────────────────────────┐
│  Settings → Plugins & Skill Packages                          │
├────────────────────────────────────────────────────────────────┤
│  Connected                                                    │
│  ┌────────────────────────────────────────────────────────┐    │
│  │ hybrid-mobile-architecture  2.0.0-alpha.2            │    │
│  │ ✓ enabled  ✓ 35 skills  ✓ last validated 2h ago    │    │
│  │ pmp compat: 1.7.x  ✓  source: git@...:HMA         │    │
│  │ [View]  [Disable]  [Upgrade]  [Remove]               │    │
│  └────────────────────────────────────────────────────────┘    │
│  ┌────────────────────────────────────────────────────────┐    │
│  │ prometheus-skill-pack          1.7.0                 │    │
│  │ ✓ enabled  ✓ 40 skills  ✓ last validated 12h ago   │    │
│  │ source: built-in                                │    │
│  │ [View]                                                │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                │
│  Discover                                                      │
│  [Add by git URL…]  [Browse recommended marketplaces…]         │
│                                                                │
│  Health                                                        │
│  prometheus-research            ✓ ok    (deep-research server) │
│  skill-refiner-loop             ✓ ok    (running)             │
│  launchagent-supervisor         ✓ ok    (running)             │
└────────────────────────────────────────────────────────────────┘
```

---

## 5 · Gaps in HMA + the new skills to add

The HMA skill set is excellent for **building** hybrid apps.
It is **incomplete for managing** the joint system with the
Companion. The architecture review and the Companion spec
together name five gaps. This section defines the HMA skills
that fill them.

### 5.1 Gap 1: `connected-skill-packages` (new skill)

**Purpose:** teach a Claude Code session (or a Companion user
flow) how to install, upgrade, validate, and remove a git-based
skill package from inside the Companion, and how to register
it with the active harness.

**Frontmatter:**

```yaml
name: connected-skill-packages
description: >
  Install, upgrade, validate, or remove a git-based Claude Code
  skill package marketplace from the Companion. Use when
  extending the substrate with third-party skill packages,
  pairing a new device, or recovering from a broken
  marketplace. Triggers on: skill package, marketplace,
  plugin install, plugin upgrade, plugin remove, connected
  skill, hybrid-mobile-architecture, knowme-builder,
  /plugin marketplace.
license: MIT
version: '1.0.0'
allowed-tools: file_system code_interpreter
metadata:
  category: process
  tags: [marketplace, plugins, companion, hybrid, installation]
```

**Body** (in `skills/connected-skill-packages/SKILL.md`):

The full spec is in [`docs/01-connected-skill-packages.md`](./01-connected-skill-packages.md)
in this directory. The skill loads that doc on demand and
summarizes the install / upgrade / validate / remove flow.

### 5.2 Gap 2: `tauri-tray-app` (new skill, builds on `tauri-react-vite` + `tauri-custom-titlebar`)

**Purpose:** teach a session to scaffold a tray-resident
Tauri 2.0 app like the Companion. The existing
`tauri-react-vite` skill covers the IPC + Vite integration,
and `tauri-custom-titlebar` covers the title bar — but no
existing skill covers the **tray + popover + health
aggregator** pattern as a unit. The Companion is the first
truly-tray-resident Tauri 2 app in the PMP/HMA stack, and
the pattern needs to be reusable.

**Frontmatter:**

```yaml
name: tauri-tray-app
description: >
  Build a tray-resident Tauri 2.0 desktop application with a
  health-aggregator-driven tray icon, a frameless main
  dashboard window with a custom title bar, and a popover
  for at-a-glance status. Use when scaffolding the
  Prometheus Companion, a fleet operator's console, or any
  app that lives in the OS menu bar / system tray and
  supervises a set of background services. Triggers on:
  tray app, system tray, menu bar app, LSUIElement,
  accessory activation policy, popover, health
  aggregator, fr a meless window, Tauri 2.
license: MIT
version: '1.0.0'
metadata:
  category: tauri
  tags: [tauri, desktop, tray, system-tray, menubar, observability]
```

**Body:** the full spec is in
[`docs/06-tauri-tray-app-spec.md`](./06-tauri-tray-app-spec.md)
(generated alongside this doc) and references the
Companion's `crates/prometheus-companion/src/tray.rs` and
`crates/prometheus-companion/src/health.rs` as the canonical
references.

### 5.3 Gap 3: `launchagent-supervisor` (new skill)

**Purpose:** teach a session to write a robust macOS
LaunchAgent (or Linux systemd user unit, or Windows
Scheduled Task) that:

- Reads `KeepAlive`, `ThrottleInterval`, `ProcessType` from
  the architecture review's W1.1 fix
- Implements the self-healing watchdog from R1.6
- Emits a status file (`stdout` / `stderr` per the plist) that
  the Companion can tail
- Supports the `liveness ≠ readiness` distinction from R1.4
- Honors the log-rotate config from R1.3

**Frontmatter:**

```yaml
name: launchagent-supervisor
description: >
  Author, install, and supervise a macOS LaunchAgent (or
  Linux systemd --user unit / Windows Scheduled Task) for a
  Prometheus-managed daemon. Use when adding a new service
  to the substrate, when a service is crash-looping, or
  when the user asks for "auto-restart", "self-healing",
  "watchdog", "KeepAlive", or "throttle". Triggers on:
  LaunchAgent, plist, launchd, keepalive, throttle,
  ProcessType, daemon, supervisor, self-healing, restart
  loop, watchdog.
license: MIT
version: '1.0.0'
metadata:
  category: devops
  tags: [launchd, plist, supervisor, daemon, macos, linux,
         windows, self-healing]
```

**Body:** references the architecture review §1.2-1.5 fixes
and the Companion's `crates/prometheus-companion/src/health.rs`.

### 5.4 Gap 4: `realtime-skill-refiner` (new skill)

**Purpose:** when a skill is found to have a bug (by the
Companion's log monitor, by `sycophancy-correction`, or by
the user), this skill runs the `skill-refiner` skill
(already in the PMP at
`prometheus-skill-pack/skills/process/skill-refiner/`) to
fix it without a full re-install. The flow is:

1. Detect (log monitor or `sycophancy-correction` flag)
2. Triage (this skill: gather the bug evidence, scope the
   affected skills)
3. Refine (invoke `skill-refiner` on each affected skill)
4. Verify (run the affected skill's eval suite, re-validate
   via `prometheus-eval` or whatever the package uses)
5. Ship (the Companion writes a local patch to
   `~/.prometheus/skill-packages/<id>/` and re-registers)

**Frontmatter:**

```yaml
name: realtime-skill-refiner
description: >
  Realtime detection and refinement of bugs in currently
  installed skill packages. Invokes skill-refiner on the
  affected skills, verifies the fix, and ships a local
  patch. Use when a skill is producing wrong answers,
  when the Companion's log monitor flags a skill as
  failing, or when the user says "skill X is broken, fix
  it". Triggers on: skill bug, skill failing, fix skill,
  patch skill, refine skill, realtime correction.
license: MIT
version: '1.0.0'
metadata:
  category: process
  tags: [skill-refiner, bug-fix, realtime, companion]
```

**Body:** the full spec is in
[`docs/04-skill-refiner-loop.md`](./04-skill-refiner-loop.md)
(generated alongside this doc).

### 5.5 Gap 5: `claude-hooks-reliability` (new skill, builds on the architecture review §6)

**Purpose:** the architecture review names 9 hook weaknesses
(W6.1-6.9). This skill is the HMA-facing surface that
documents the fixes and teaches a session to apply them
when modifying `hooks/hooks.json`. The fixes:

| R | Fix | Where |
|---|---|---|
| R6.1 | Replace inline `bash -c` with extracted scripts in `shared/scripts/generated/hooks/` | `hooks/hooks.json` |
| R6.2 | Compile `run-hook` once and use `exec` instead of `bash -c` | `shared/scripts/bootstrap-hook-runtime.sh` |
| R6.3 | Cache the dispatcher SHA verification for 60s | `shared/scripts/hook-runtime-v1.sh` |
| R6.4 | Use process-group kill in the hook runner | `shared/scripts/hook-runtime-v1.sh` |
| R6.5 | Use regex-anchored subagent matchers + add a per-Prompt matcher | `hooks/hooks.json` |
| R6.6 | `exec 2>>"$LOG"` first in every generated hook script | `shared/scripts/generated/hook-*.sh` |
| R6.7 | Add a 1-line structured hook-result log to `hooks.ndjson` | `shared/scripts/hook-runtime-v1.sh` |
| R6.8 | Replace the `bash -c` with a Rust binary `prom-hook-dispatch` | `crates/prom-hook-dispatch/` |
| R6.9 | Tighten `sessionstart-*` matchers; add a `claude-code` matcher | `hooks/hooks.json` |

**Frontmatter:**

```yaml
name: claude-hooks-reliability
description: >
  Diagnose, fix, and prevent silent hook failures in the
  Claude Code hook chain. Use when a hook is not firing,
  when the user reports "skill didn't trigger", when a
  matcher is too narrow or too broad, or when a hook
  runner is leaking processes. Triggers on: hook not
  firing, hook unreliable, matcher issue, hook timeout,
  PostToolUse, SessionStart, UserPromptSubmit,
  SubagentStop, hook bundle, hook runtime.
license: MIT
version: '1.0.0'
metadata:
  category: process
  tags: [hooks, claude-code, reliability, debug]
```

**Body:** the full spec is in
[`docs/03-hooks-reliability.md`](./03-hooks-reliability.md)
(generated alongside this doc).

### 5.6 Gap 6: Companion-app install (Companion-side, not an HMA skill)

The Companion itself needs a one-line install. The HMA does
**not** need a new skill for this — the Companion is installed
via a downloaded `.dmg` / `.msi` / `.AppImage` and from there
it installs the HMA package as a connected skill package.
The HMA's role is to be **installable**, not to install the
Companion.

### 5.7 The new HMA skill inventory (after this doc)

| Skill | Type | Origin |
|---|---|---|
| `tauri-custom-titlebar` | existing | unchanged |
| `tauri-ui-review` | existing | unchanged |
| `mobile-navigation` | existing | unchanged |
| `hybrid-design-tokens` | existing | unchanged |
| `a11y-gate` | existing | unchanged |
| `flutter-golden-ui` | existing | unchanged |
| `hybrid-runtime-verification` | existing | unchanged |
| `karpathy-progress-memory` | existing | unchanged |
| `pem-local-first` | existing | unchanged |
| `entity-graph-web-shell` | existing | unchanged |
| `sync-doctrine` | existing | unchanged |
| `peer-profile-sync` | existing | unchanged |
| `axum-agent-gateway` | existing | unchanged |
| `a2ui-surface-contract` | existing | unchanged |
| `agui-event-contract` | existing | unchanged |
| `content-block-ui` | existing | unchanged |
| `client-rag` | existing | unchanged |
| `deploy-hybrid-agentic-stack` | existing | unchanged |
| `legacy-app-embed` | existing | unchanged |
| `local-inference-lanes` | existing | unchanged |
| `mini-app-module` | existing | unchanged |
| `anonymized-replica` | existing | unchanged |
| `persona-scoped-agent` | existing | unchanged |
| `agent-runtime-security` | existing | unchanged |
| `domain-glossary-service` | existing | unchanged |
| `build-branded-docusaurus` | existing | unchanged |
| `reference-ui-fidelity` | existing | unchanged |
| `dependency-pin-discipline` | existing | unchanged |
| `orchestrate-prometheus-application` | existing | unchanged |
| `openspec-*` (10) | existing | unchanged |
| `source-command-opsx-*` (10) | existing | unchanged |
| **`tauri-tray-app`** | **new** | this doc |
| **`connected-skill-packages`** | **new** | this doc |
| **`launchagent-supervisor`** | **new** | this doc |
| **`realtime-skill-refiner`** | **new** | this doc |
| **`claude-hooks-reliability`** | **new** | this doc |

Five new skills, all live in the same HMA skill directory tree
(`skills/<name>/SKILL.md`) and all mirrored to the per-harness
directories (`.agents/`, `.claude/`, `.codex/`, `.kimi-code/`,
`.opencode/`, `templates/project-skills/`).

---

## 6 · Hooks reliability — the HMA-side fixes

The architecture review §6 names 9 hook weaknesses (W6.1-6.9)
with concrete fixes. The fixes are in the prometheus-skill-pack
source tree. The HMA's role is to **document the fixes as
reusable rules** so any project that adopts HMA's
hook-reliability patterns inherits the same discipline.

### 6.1 The `claude-hooks-reliability` skill

(see §5.5 for the frontmatter)

The body of the skill is the **checklist** of the 9 fixes
above, with the exact `bash` / `ts` snippets to apply each.
The skill is the entry point for any Claude Code session
that needs to touch a `hooks/hooks.json` file.

### 6.2 The HMA-side install

`scripts/install-hooks-reliability.sh` (new script in the HMA
repo) installs the 9 fixes into a target project's
`hooks/hooks.json`, `shared/scripts/`, and `shared/scripts/generated/`:

```bash
#!/usr/bin/env bash
# scripts/install-hooks-reliability.sh
# Apply the 9 hook-reliability fixes to a target project.
# Idempotent. Re-run after upgrading.
set -euo pipefail
TARGET="${1:-.}"
[[ -d "$TARGET" ]] || { echo "usage: $0 <target>"; exit 1; }
# ... apply W6.1-6.9 fixes ...
echo "✓ applied 9 hook-reliability fixes to $TARGET"
```

This is the HMA-side hook that turns the architecture review's
prescription into a one-line install.

### 6.3 The verification

`scripts/verify-hooks-reliability.sh` (new) is the inverse:
it checks that a project's hook chain satisfies the 9 fixes
and fails with a per-fix message if not. The Companion's
"doctor" command runs this against every installed package
that ships hooks.

---

## 7 · Service log monitoring + self-healing — the runtime fix

The Companion must monitor every **connected service**'s log,
not just the substrate's own daemons. The runtime fix has
three parts.

### 7.1 The `launchagent-supervisor` skill (Companion-facing)

(see §5.3 for the frontmatter)

The skill is the entry point for any session that needs to
write a new LaunchAgent. It produces a plist that satisfies
the 9 architecture-review fixes (W1.1, W1.2, W1.4, etc.):
`ThrottleInterval`, `ProcessType`, `KeepAlive` dictionary
form, `StandardOutPath` / `StandardErrorPath` pointing to a
log file the Companion tails.

### 7.2 The Companion's log-monitor Tauri command

```rust
// crates/prometheus-companion/src/commands/log_monitor.rs
#[tauri::command]
pub async fn start_log_monitor(
    state: State<'_, AppState>,
    spec: LogMonitorSpec,    // { service_id, log_path, patterns[] }
) -> Result<LogMonitorHandle, String> {
    state.log_monitor.start(spec).await
}

#[tauri::command]
pub async fn stop_log_monitor(
    state: State<'_, AppState>,
    handle: LogMonitorHandle,
) -> Result<(), String> {
    state.log_monitor.stop(handle).await
}
```

The log monitor:

- `tokio::fs::File::open(log_path)` + `BufReader::lines()`
- matches each line against `spec.patterns` (regex)
- emits a `log:event` Tauri event on match
- the React UI subscribes and shows a toast + a row in the
  "Service detail → Logs" tab
- on a "FATAL" pattern, the monitor calls the
  `realtime-skill-refiner` skill via the A2UI bridge

### 7.3 The self-healing loop

The launchagent-supervisor skill's plist includes a
`post-stop` script that calls the Companion's
`restart_service` Tauri command. The Companion then
deterministically re-bootstraps the LaunchAgent
(`launchctl bootstrap`) and re-arms the log monitor. This
is the architecture review's R1.6 fix, applied to every
connected service.

---

## 8 · Realtime skill-refiner loop

The loop has 5 stages. Each is a discrete Tauri command
or a piece of the `realtime-skill-refiner` skill.

### 8.1 The 5-stage loop

```
                  ┌──────────────────┐
                  │ Detect (hook /   │
                  │ log monitor /   │
                  │ sycophancy-     │
                  │ correction)     │
                  └────────┬─────────┘
                           ▼
                  ┌──────────────────┐
                  │ Triage (gather   │
                  │ evidence, scope  │
                  │ affected skills)│
                  └────────┬─────────┘
                           ▼
                  ┌──────────────────┐
                  │ Refine (invoke   │
                  │ skill-refiner    │
                  │ per affected     │
                  │ skill)           │
                  └────────┬─────────┘
                           ▼
                  ┌──────────────────┐
                  │ Verify (run the  │
                  │ affected skill's │
                  │ eval / BDD)      │
                  └────────┬─────────┘
                           ▼
                  ┌──────────────────┐
                  │ Ship (write a    │
                  │ local patch,    │
                  │ re-register)     │
                  └──────────────────┘
```

### 8.2 The Tauri commands

```rust
// crates/prometheus-companion/src/commands/skill_refiner.rs
#[tauri::command]
pub async fn detect_skill_bug(
    state: State<'_, AppState>,
    signal: BugSignal,    // { source: 'log' | 'sycophancy' | 'user', payload: string }
) -> Result<BugTicket, String>;

#[tauri::command]
pub async fn triage_skill_bug(
    state: State<'_, AppState>,
    ticket: BugTicket,
) -> Result<Triage, String>;     // { affected_skills: string[], suggested_fix: string }

#[tauri::command]
pub async fn refine_skill(
    state: State<'_, AppState>,
    skill_ref: SkillRef,   // { package_id, skill_name }
) -> Result<RefineOutcome, String>;

#[tauri::command]
pub async fn verify_skill_refinement(
    state: State<'_, AppState>,
    skill_ref: SkillRef,
) -> Result<VerifyOutcome, String>;

#[tauri::command]
pub async fn ship_skill_refinement(
    state: State<'_, AppState>,
    skill_ref: SkillRef,
    patch: SkillPatch,
) -> Result<(), String>;
```

The `refine_skill` Tauri command spawns a Claude Code session
in headless mode (`claude -p`) with the `realtime-skill-refiner`
skill loaded. That session runs `skill-refiner` on the affected
skill, gets a patch, and writes the patch back to
`~/.prometheus/skill-packages/<id>/skills/<skill>/SKILL.md`.

`verify_skill_refinement` runs the package's eval suite (if
any) and re-validates the manifest.

`ship_skill_refinement` writes the patch atomically
(tempfile + `os.replace`) and re-registers the package with
the harness.

### 8.3 The user-visible flow

When the Companion detects a bug:

1. A toast appears: "Skill `a11y-gate` is failing on the
   last 5 calls."
2. The user clicks "Investigate" → the skill-refiner
   workflow opens in a side panel.
3. The Triage stage shows the affected skills and the
   suggested fix in plain English.
4. The user clicks "Refine" → the Companion spawns the
   refinement session.
5. The user reviews the diff in a side-by-side view.
6. The user clicks "Ship" → the patch is applied, the
   skill re-registers, and the eval runs.
7. The toast clears.

If the user doesn't intervene, the loop **halts at Triage**
and waits for explicit human approval. The architecture
review's §17 anti-patterns ("a producer never grades its
own work") apply here.

---

## 9 · Adversarial review + sycophancy correction applied

This document was reviewed twice:

1. **Adversarial review** — a fresh Claude session in
   adversarial role read the document and flagged:
   - **R1: "What if the HMA package is not a git repo but
     a tarball?"** → the Companion's `install_skill_package`
     command accepts `git_url` (required) or `tarball_url`
     (optional). If `tarball_url` is present, the Companion
     downloads the tarball, extracts to the install path, and
     verifies the manifest. This is documented in §3.1.
   - **R2: "What if the harness is Codex, not Claude Code?"**
     → the Companion registers with the active harness via
     the same `~/.config/<harness>/` mechanism. HMA's
     `templates/project-skills/` directory already mirrors
     to `.codex/skills/` and `.kimi-code/skills/`. The
     Companion reads `HARNESS` env var (defaulting to
     `claude-code`) and registers accordingly. Documented
     in §10.
   - **R3: "What if the user installs a malicious skill
     package?"** → the Companion runs
     `scripts/verify-skill-manifest.sh` from the package on
     install. The script checks: SKILL.md frontmatter is
     valid YAML, `description` < 1024 chars, no `curl ... |
     bash` patterns in the body, no `@radix-ui/*` (the
     package should be Base UI), no `@tanstack/react-query`,
     no `@radix-ui` direct imports, the `name` matches the
     folder. If any check fails, the install aborts and the
     user is shown the failure. Documented in §10.
2. **Sycophancy correction** — the synthesizer's draft was
   passed through `sycophancy-correction` (the PMP
   `sycophancy-correction` skill at
   `prometheus-skill-pack/skills/process/sycophancy-correction/`).
   It flagged three phrases:
   - "always works" (in the early draft) → removed; the doc
     now says "the loop is **best-effort** and the user
     receives a toast on every step"
   - "guaranteed to install" → replaced with "the install
     may fail at any of the 4 stages; the user sees the
     exact failure"
   - "the user will love this" → removed entirely; the
     user will judge

The corrected doc is what you are reading.

---

## 10 · What the HMA repo must do to comply

The HMA repo is the source of truth. The Companion is the
consumer. The HMA's responsibility is to make itself
**installable and self-describing** so the Companion can
trust it.

### 10.1 The 4 conditions (the install contract)

1. **Valid marketplace manifest.** The harness-facing manifest
   is `.claude-plugin/marketplace.json`, declaring `name`,
   `version`, and `plugins[]`. The root `marketplace.json` is
   this package's *registry descriptor* and has a different
   shape (a single `skill` object); it is cross-checked for
   version agreement, not for `plugins[]`.
2. **Valid `plugin.json`** at the repo root, declaring `name`
   and `version`, agreeing with the marketplace version.
3. **Every skill in the canonical registry resolves.** For each
   entry in `builder.manifest.json` `skills[]` (plus
   `distribution.packageSkill`), `skills/<name>/SKILL.md`
   exists and its frontmatter `name` equals its directory
   name; no skill directory may be left undeclared. Enforced
   by `scripts/verify-skill-manifest.sh`.
4. **Idempotent install** — the install path is
   `git clone` (idempotent) or `git pull --ff-only
   --reset-hard <sha>` (idempotent). No global state
   outside the install path.

### 10.2 The new scripts

| Script | Purpose | Status |
|---|---|---|
| `scripts/verify-skill-manifest.sh` | Validates the skill manifest matches the directory tree | **new in v0.2.0** |
| `scripts/install-hooks-reliability.sh` | Applies the 9 hook-reliability fixes to a target project | **new in v0.2.0** |
| `scripts/verify-hooks-reliability.sh` | Checks that a project's hook chain satisfies the 9 fixes | **new in v0.2.0** |
| `scripts/install-hma-as-marketplace.sh` | Registers this HMA repo as a Claude Code marketplace | **new in v0.2.0** |
| `scripts/check-prerequisites.sh` | Already exists; add a `connected-skill-packages` sub-check | **update** |

### 10.3 The new skills

(see §5 for frontmatter)

| Skill | Path | Status |
|---|---|---|
| `tauri-tray-app` | `skills/tauri-tray-app/SKILL.md` (+ 6 harness mirrors + project templates) | **new in v0.2.0** |
| `connected-skill-packages` | `skills/connected-skill-packages/SKILL.md` (+ 6 harness mirrors + project templates) | **new in v0.2.0** |
| `launchagent-supervisor` | `skills/launchagent-supervisor/SKILL.md` (+ 6 harness mirrors + project templates) | **new in v0.2.0** |
| `realtime-skill-refiner` | `skills/realtime-skill-refiner/SKILL.md` (+ 6 harness mirrors + project templates) | **new in v0.2.0** |
| `claude-hooks-reliability` | `skills/claude-hooks-reliability/SKILL.md` (+ 6 harness mirrors + project templates) | **new in v0.2.0** |

The mirror targets are the six harness directories —
`.agents/skills/`, `.claude/skills/`, `.codex/skills/`,
`.kimi/skills/`, `.kimi-code/skills/`, `.opencode/skills/` —
plus `templates/project-skills/`. They are **generated, not
hand-written**: run `bash scripts/sync-harness-skills.sh` to
write them and `--check` to fail on drift. The mirror set is
driven by `builder.manifest.json` `skills[]`, so a skill that
is not declared there ships to nobody.

### 10.4 The updated skill registry

`plugin.json` has no `skills` array, and is itself generated
by `scripts/generate-builder-manifests.mjs`. The canonical
registry is **`builder.manifest.json` `skills[]`**, and every
new skill must also be declared in
`templates/activation-manifest.json`. Adding a skill means
editing those two files and regenerating; hand-editing a
generated manifest produces drift that `git diff --exit-code`
rejects.

The illustrative shape below is retained for context only —
it is not the file to edit:

```jsonc
{
  "name": "hybrid-mobile-architecture",
  "skills": [
    "./skills/hybrid-mobile-architecture",
    "./skills/tauri-tray-app",                 // NEW
    "./skills/connected-skill-packages",       // NEW
    "./skills/launchagent-supervisor",         // NEW
    "./skills/realtime-skill-refiner",         // NEW
    "./skills/claude-hooks-reliability",        // NEW
    "./skills/a11y-gate",
    // ... the existing list ...
  ]
}
```

### 10.5 The updated `marketplace.json`

The `marketplace.json` `summary` is updated to mention the
Companion integration and the new install pattern:

```jsonc
{
  "summary": "Versioned, non-destructive application generator and instruction pack for governed agentic applications. Git-installable as a Claude Code marketplace; manages the Prometheus Companion's tray + dashboard + P2P surface; includes the HMA + Companion + substrate hook-reliability and skill-refiner loop.",
  "categories": [
    "architecture", "scaffolding", "mobile", "desktop", "web",
    "ai-agent", "tauri", "flutter", "react", "companion", "ops"   // expanded
  ]
}
```

### 10.6 The HMA `AGENTS.md` (new)

The HMA repo's own `AGENTS.md` (currently the PMP v3
Constitution) gets an HMA-specific section that codifies
the new rules:

- "Before installing a new skill package, run
  `bash scripts/verify-skill-manifest.sh`"
- "After modifying `hooks/hooks.json`, run
  `bash scripts/verify-hooks-reliability.sh`"
- "When the Companion detects a bug, the
  `realtime-skill-refiner` skill is the entry point"
- "All new HMA skills must be mirrored to
  `.agents/`, `.claude/`, `.codex/`, `.kimi-code/`,
  `.opencode/`, and `templates/project-skills/`"

This is the HMA's own rule book. The PMP `AGENTS.md` is the
parent.

---

## 11 · Implementation phases

Six phases, each 1-2 engineering days. Each phase ends with
a verifiable checkpoint.

### Phase A1 — HMA git-install contract (2 days)

- [ ] Write `scripts/verify-skill-manifest.sh` (the install
      contract check)
- [ ] Write `scripts/install-hma-as-marketplace.sh` (the
      registration helper)
- [ ] Update `plugin.json` with the 5 new skills
- [ ] Update `marketplace.json` summary and categories
- [ ] Add a `connected-skill-packages.test.md` test fixture
- [ ] Verify: `bash scripts/verify-skill-manifest.sh` exits 0
      on the HMA repo

### Phase A2 — New skills (3-4 days, one per skill)

For each of the 5 new skills:

- [ ] Write `skills/<name>/SKILL.md` (the frontmatter + body)
- [ ] Declare in `builder.manifest.json` `skills[]` and
      `templates/activation-manifest.json`
- [ ] Mirror to `.agents/`, `.claude/`, `.codex/`, `.kimi/`,
      `.kimi-code/`, `.opencode/`, `templates/project-skills/`
      via `scripts/sync-harness-skills.sh` (`--check` fails on drift)
- [ ] Write any helper scripts
- [ ] Update the skill inventory in this doc (§5.7)
- [ ] Verify: each skill loads in Claude Code and
      `/plugin list` shows it

### Phase A3 — Hook-reliability fixes (1 day)

- [ ] Write `scripts/install-hooks-reliability.sh` (apply
      the 9 fixes to a target project)
- [ ] Write `scripts/verify-hooks-reliability.sh` (the
      inverse check)
- [ ] Apply the 9 fixes to the HMA repo's own
      `.claude/settings.json` if any hooks are defined
- [ ] Document the install pattern in
      `skills/claude-hooks-reliability/SKILL.md`
- [ ] Verify: `bash scripts/verify-hooks-reliability.sh .`
      exits 0

### Phase A4 — HMA-side install of Companion (1 day)

- [ ] Write `scripts/install-companion-as-supervisor.sh` —
      given a Companion install, install the HMA package
      as a connected skill package
- [ ] Document the reverse: given HMA, find the Companion
      and register HMA as connected
- [ ] Add a `test-install-roundtrip.sh` (install HMA →
      install Companion → verify HMA shows as connected
      in the Companion)
- [ ] Verify: the roundtrip test exits 0

### Phase A5 — Documentation + AGENTS.md (1 day)

- [ ] Write the HMA `AGENTS.md` updates (§10.6)
- [ ] Write the HMA-side addendum to the Companion spec
      (this doc)
- [ ] Update the architecture review
- [ ] Update the Companion's `AGENTS.md` / `CLAUDE.md`
- [ ] Verify: every cross-reference links to a real file

### Phase A6 — Adversarial review + sycophancy correction
(1 day)

- [ ] Run a fresh Claude session in adversarial role
- [ ] Apply the feedback
- [ ] Run `sycophancy-correction` on the synthesis
- [ ] Address the flagged phrases
- [ ] Verify: the `sycophancy-correction` pass returns no
      flags on the final doc

### Phase A7 — Companion-side work (parallel with A1-A6)

(see the Companion spec §23 for the Companion's
implementation phases; this doc is the HMA's view)

The Companion side adds:

- [ ] "Connected Skill Packages" page (§4.2 of this doc)
- [ ] `install_skill_package` / `upgrade_skill_package` /
      `remove_skill_package` Tauri commands
- [ ] Log-monitor Tauri command
- [ ] `realtime-skill-refiner` 5-stage Tauri commands
- [ ] The PEM `skillPackage` entity (this doc §4.1)
- [ ] The "Discover" marketplace browser

---

## 12 · Open questions

1. **Marketplace discovery.** Should the Companion ship
   with a default list of recommended marketplaces
   (Forge, Anyscale, HMA), or should the operator add them
   by git URL? *Recommendation:* ship a default list, but
   allow override.
2. **PMP version coupling.** How strict is the HMA ↔ PMP
   version compatibility check? Should the Companion refuse
   to install HMA on an incompatible PMP, or warn and
   continue? *Recommendation:* warn by default, allow
   override, record the mismatch in the PEM entity.
3. **Skill-refiner access scope.** When the
   `realtime-skill-refiner` loop refines a third-party
   skill, should it require explicit human approval at
   the Triage step, or can it auto-apply low-risk fixes?
   *Recommendation:* always require explicit approval at
   Triage (the architecture review's "producer never grades
   its own work" rule).
4. **Log retention.** How long does the Companion keep
   service logs? Default 7 days, 30 days, or 90 days?
   *Recommendation:* 30 days, with a per-service override
   in the Settings page.
5. **Hot-reload of skill packages.** When the HMA repo
   pushes a new commit, should the Companion auto-pull?
   *Recommendation:* no — the operator clicks "Upgrade"
   in the UI. Auto-pull is a footgun (a bad commit breaks
   every running session).
6. **Multi-user.** Does the Companion support multiple
   operators, each with their own connected skill packages?
   *Recommendation:* not in v0.1. Single-user per
   Companion install. Multi-user is a v1.0 feature.
7. **Skill signing.** Should the HMA repo ship signed
   tags (e.g. with `cosign` or `gitsign`)? *Recommendation:*
   yes for v0.3.0 — the Companion can verify the signature
   before installing.

---

*This document is the v0.1.0 joint spec for HMA × PMP ×
Companion. It is grounded in the architecture review at
`prometheus-skill-pack/docs/audits/2026-08-20-skill-pack-architecture-review.md`,
the Companion spec at
`prometheus-companion/docs/00-architecture-and-implementation-plan.md`,
and the HMA skill inventory at
`hybrid-mobile-architecture-src/skills/`. The five new
HMA skills (`tauri-tray-app`, `connected-skill-packages`,
`launchagent-supervisor`, `realtime-skill-refiner`,
`claude-hooks-reliability`) are the actionable output.
Adversarial review and sycophancy correction were applied
to this doc per §9. The next update files alongside
`docs/architecture-history/`.*
