# `connected-skill-packages` — Skill Specification

> **Status:** v0.1.0 draft (for HMA v0.2.0)
> **Parent doc:** [`05-hma-pmp-companion-architecture.md`](./05-hma-pmp-companion-architecture.md)
> **File path:** `skills/connected-skill-packages/SKILL.md` (+ 5 mirrors)

---

## §0 · Frontmatter

As shipped in `skills/connected-skill-packages/SKILL.md`:

```yaml
---
name: connected-skill-packages
description: Install, upgrade, validate, or remove a git-based agent skill package marketplace consumed by the Prometheus Companion. Use when extending the substrate with third-party skill packages, pairing a new device, shipping a package that must be installable, or recovering from a broken marketplace. Triggers on skill package, marketplace, marketplace.json, plugin install, plugin upgrade, plugin remove, connected skill, install contract, hybrid-mobile-architecture, knowme-builder, plugin marketplace add, skill bundle, additional skills.
---
```

`scripts/check-skill-contracts.mjs` requires the frontmatter keys to be
exactly `name` and `description`, in that order, with `description` a single
line of at most 1024 characters. It rejects `license`, `version`,
`allowed-tools`, and `metadata`, so the trigger vocabulary that would
otherwise live in those keys is folded into `description` — which is what the
harness matches on anyway. `name` must equal the skill's directory name.

---

## §1 · Purpose

The Companion ships with a built-in substrate (the
prometheus-skill-pack) but is **extensible**. Operators add
new skill packages — the HMA package is the canonical example
— by installing them as **connected skill packages** in the
Companion's "Plugins & Skill Packages" page.

A connected skill package is:

- A **git repository** (a marketplace) the Companion has
  cloned into `~/.prometheus/skill-packages/<id>/`
- A **marketplace manifest** (`marketplace.json`) at the repo
  root that declares plugins and skills
- A **set of plugins** (with `plugin.json`) the operator has
  chosen to enable
- A **set of skills** the harness has registered (Claude
  Code's `.claude/skills/`, Codex's `.codex/skills/`, etc.)
- An **optional service** (if the package ships a binary or
  a LaunchAgent — HMA does not today)
- A **compatibility matrix** with the PMP and with the
  Companion

The Companion's role is to **be the operator's view** of
this. The HMA's role is to **be the package**. The two must
agree on the contract; this skill is the contract.

---

## §2 · When to invoke

Invoke this skill when:

- The user asks to install a new skill package
- The user adds a new marketplace (`/plugin marketplace
  add <url>`)
- The user upgrades a package
- A marketplace is broken and needs to be re-validated
- A skill is missing and the user wants to know why
- The Companion's "Connected Skill Packages" page is
  showing a stale entry
- The user wants to ship a new skill package and needs the
  install contract

Do **not** invoke this skill when:

- The user just wants to install a single skill (use
  `/plugin install` directly)
- The user is debugging a Claude Code plugin issue (use the
  existing Claude Code plugin docs, not this skill)

---

## §3 · The four operations

The skill teaches the four operations: **install, upgrade,
validate, remove**. Each is a Tauri command exposed by the
Companion and a script in the HMA repo.

### §3.1 Install

**Companion (consumer side):**

```rust
#[tauri::command]
pub async fn install_skill_package(
    spec: SkillPackageSpec,    // { id, git_url, ref, sha? }
) -> Result<SkillPackageManifest, String>
```

1. **Resolve the target path:**
   `~/.prometheus/skill-packages/<id>/`
2. **If exists, refuse** (use `upgrade_skill_package` instead).
3. **Else, git clone:**
   `git clone <git_url> <target> --branch <ref> --depth 1`
4. **Verify the install contract** (see §3.3 below).
5. **Register with the active harness:**
   - Claude Code: `claude plugin marketplace add <target>` +
     `claude plugin install <id>@<id>`
   - Codex: write the `plugin.json` into
     `~/.codex/skills/<id>/` and link the skills
   - Other: see §3.5
6. **Persist a PEM `skillPackage` entity** with the result.

**HMA (producer side) — what the package must do to be
installable:**

- Have a valid `marketplace.json` at the repo root
- Have a valid `plugin.json` (or a `strict: false` skill
  bundle entry in `marketplace.json`)
- Pass `scripts/verify-skill-manifest.sh` (the install
  contract check)
- Be reachable via the `git_url` (HTTPS or SSH)

### §3.2 Upgrade

**Companion (consumer side):**

```rust
#[tauri::command]
pub async fn upgrade_skill_package(
    id: String,
    target_sha: Option<String>,  // explicit pin; default = origin/HEAD
) -> Result<SkillPackageManifest, String>
```

1. **Resolve the target path:** `~/.prometheus/skill-packages/<id>/`
2. **`git fetch origin <ref>`** in the target dir
3. **`git reset --hard <sha>`** (or `origin/<ref>` if no
   explicit sha)
4. **Re-verify the install contract** (manifest may have
   changed)
5. **Re-register with the harness** (plugins may have
   been added or removed)
6. **Update the PEM `skillPackage` entity** with the new
   sha

**HMA (producer side):** the repo should tag releases
(`v0.2.0`, `v0.2.1`, …) and the Companion should default to
the latest tag (not the branch HEAD). Branch HEAD is
unstable.

### §3.3 Validate

**Companion (consumer side):**

```rust
#[tauri::command]
pub async fn validate_skill_package(
    id: String,
) -> Result<ValidationReport, String>     // { ok, warnings, errors[] }
```

The Companion runs four checks:

1. **`scripts/verify-skill-manifest.sh`** — does the
   `plugin.json` match the actual `skills/<name>/SKILL.md`
   tree?
2. **Schema check** — every `SKILL.md` has valid YAML
   frontmatter with `name`, `description`, and a
   `description` < 1024 chars
3. **Anti-pattern check** — no `@radix-ui/*` direct
   imports, no `@tanstack/react-query`, no
   `curl ... | bash` patterns in skill bodies
4. **Compatibility check** — the package's declared
   `pmpCompatibility` matches the installed PMP version

**HMA (producer side):** the package must ship
`scripts/verify-skill-manifest.sh` and ensure it returns
0 on a clean tree.

### §3.4 Remove

**Companion (consumer side):**

```rust
#[tauri::command]
pub async fn remove_skill_package(
    id: String,
    confirm: bool,        // require explicit confirmation
) -> Result<(), String>
```

1. **Unregister from the active harness** (the inverse
   of `claude plugin install`)
2. **`rm -rf <target>`** the install path
3. **Mark the PEM `skillPackage` entity as `enabled: false`**
   and `removedAt: <now>` (do **not** delete the entity;
   the operator may want to re-add it later)

---

## §4 · The install contract (the HMA-side guarantee)

The HMA repo must satisfy 4 conditions to be installable:

1. **Valid `marketplace.json`** at the repo root. Schema:
   `https://json-schema.org/draft/2020-12/schema` with
   required fields `name`, `version`, `skills[]`.
2. **Valid `plugin.json`** at the repo root. Required:
   `name`, `version`, `skills[]`, optional
   `mcpServers`, `repository.url`.
3. **Every `SKILL.md` referenced in `plugin.json` exists** AND
   has a valid `name` in its YAML frontmatter that matches
   its directory name. Verified by
   `scripts/verify-skill-manifest.sh`.
4. **Idempotent install.** The install path is
   `git clone` (idempotent) or
   `git pull --ff-only --reset-hard <sha>` (idempotent).
   No global state outside the install path.

The Companion enforces conditions 1, 2, 3 with its validator.
Condition 4 is a behavior check; a failure here surfaces as
"install appears to work but the harness can't find the
skills."

---

## §5 · The harness-aware install (Claude Code / Codex / Kimi / OpenCode / Mavis)

The Companion reads the `HARNESS` env var (default
`claude-code`) and registers the package accordingly. The
mapping:

| `HARNESS` | Register command | Verify |
|---|---|---|
| `claude-code` | `claude plugin marketplace add <target> && claude plugin install <id>@<id>` | `claude plugin list` |
| `codex` | write `<target>/.codex-plugin/plugin.json` into `~/.codex/plugins/<id>/`, symlink the skills into `~/.codex/skills/<id>/` | `codex plugin list` |
| `kimi` | same shape, into `~/.kimi-code/plugins/<id>/` and `~/.kimi-code/skills/<id>/` | `kimi plugin list` |
| `opencode` | same shape, into `~/.opencode/plugins/<id>/` and `~/.opencode/skills/<id>/` | `opencode plugin list` |
| `mavis` / `MiniMax` | same shape, into `~/.minimax/plugins/<id>/` and `~/.minimax/skills/<id>/` | `minimax plugin list` |

The HMA repo already mirrors every skill to the per-harness
directories (`.agents/`, `.claude/`, `.codex/`, `.kimi/`,
`.kimi-code/`, `.opencode/`, `templates/project-skills/`).
The Companion reads the active harness and picks the right
mirror.

The full mapping is in `companion/src/commands/harness.rs`
(new file in the Companion crate).

---

## §6 · The recommended marketplace catalog (shipped with the Companion)

The Companion ships with a default `recommended-marketplaces.json`:

```jsonc
[
  {
    "id": "hybrid-mobile-architecture",
    "label": "KnowMe Builder (Hybrid Mobile Architecture)",
    "gitUrl": "https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill.git",
    "defaultRef": "main",
    "pmpCompatibility": "1.7.x",
    "description": "Skill package for building hybrid Tauri + React + Flutter + Axum apps.",
    "verifiedPublisher": true
  },
  {
    "id": "prometheus-skill-pack",
    "label": "Prometheus Skill Pack",
    "gitUrl": "https://github.com/Prometheus-AGS/prometheus-skill-system.git",
    "defaultRef": "main",
    "pmpCompatibility": "1.7.x",
    "description": "The substrate's authoritative skill set; usually pre-installed.",
    "verifiedPublisher": true
  }
  // ... the operator may add more
]
```

The Companion reads this list on first launch and shows it
in the "Discover" tab of the Plugins page. The operator can
add custom marketplaces by git URL.

---

## §7 · The data model (PEM 3.x)

The Companion models connected skill packages as PEM
entities. The full schema is in the joint spec §4.1. The
key fields:

| Field | Type | Notes |
|---|---|---|
| `id` | id (clientId: true) | the package slug, e.g. `hybrid-mobile-architecture` |
| `version` | string | semver, from `marketplace.json` |
| `gitUrl` | string | the install source |
| `gitRef` | string | the ref used at install time |
| `installedSha` | string | the commit sha at install time |
| `installPath` | string | `~/.prometheus/skill-packages/<id>/` |
| `marketplaceJson` | jsonb | the parsed manifest |
| `enabled` | boolean | is the package enabled? |
| `enabledPlugins` | string[] | per-plugin enable |
| `pmpCompatibility` | string | e.g. `1.7.x` |
| `lastValidatedAt` | datetime | last successful validate run |
| `lastValidationResult` | enum | `ok` / `warn` / `fail` / `unknown` |

The lane is **relational** (server-authoritative LWW). The
git SHA is the natural conflict-resolution key.

---

## §8 · Anti-patterns (do not do these)

- ❌ Auto-pulling a package on a new commit. Always require
  the operator to click "Upgrade" in the UI. Auto-pull is a
  footgun.
- ❌ Installing a package without running the validation
  gate first. Always validate.
- ❌ Mixing the install path with the user's other
  repositories. Always install to
  `~/.prometheus/skill-packages/<id>/`.
- ❌ Shipping a package without `scripts/verify-skill-manifest.sh`.
  The Companion will refuse to install it.
- ❌ Hiding the manifest from the operator. The Companion
  always shows the parsed `marketplace.json` and the
  per-skill `description` in the UI.
- ❌ Running the harness `plugin install` with elevated
  privileges. The install must work with the operator's
  user-level harness config.

---

## §9 · Skills used (this skill is built on)

- `prometheus-skill-pack/skills/process/clean-skill` — the
  authoring rules every new HMA skill must follow
- `prometheus-skill-pack/skills/process/skill-refiner` — the
  refinement flow when this skill has a bug
- `prometheus-skill-pack/skills/architecture/clean-architecture`
  — the 4-layer CLEAN model
- `hybrid-mobile-architecture/skills/orchestrate-prometheus-application`
  — the multi-phase orchestration
- `hybrid-mobile-architecture/skills/deploy-hybrid-agentic-stack`
  — the deployment patterns

---

## §10 · Definition of done (for this skill being installed in the HMA repo)

- [ ] `skills/connected-skill-packages/SKILL.md` exists with
      the frontmatter above
- [ ] The SKILL.md body covers all of §1-§9
- [ ] Mirrored to `.agents/skills/`, `.claude/skills/`,
      `.codex/skills/`, `.kimi-code/skills/`,
      `.opencode/skills/`, `templates/project-skills/`
- [ ] Added to the `plugin.json` `skills` array
- [ ] The Companion's "Discover" page lists HMA
- [ ] The HMA's `marketplace.json` summary mentions
      "Connected Skill Packages" integration
- [ ] `scripts/verify-skill-manifest.sh` exits 0 on the
      HMA repo with this skill present
- [ ] A roundtrip test (install HMA → install Companion →
      verify HMA shows as connected) exits 0

---

*This is the v0.1.0 spec for the `connected-skill-packages`
skill, to be added to the HMA package in v0.2.0. The skill
itself is the install contract between the HMA (producer)
and the Companion (consumer). See the joint spec
`05-hma-pmp-companion-architecture.md` for the surrounding
context.*
