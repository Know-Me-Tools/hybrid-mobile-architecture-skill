# `auto-skill-package-integration` — Skill Specification

> **Status:** v0.1.0 draft (for HMA v0.2.0)
> **Parent doc:** [`05-hma-pmp-companion-architecture.md`](./05-hma-pmp-companion-architecture.md)
> **Built on:** `connected-skill-packages` (HMA v0.2.0)
> **File path:** `skills/auto-skill-package-integration/SKILL.md` (+ 5 mirrors)

---

## §0 · Frontmatter

As shipped in `skills/auto-skill-package-integration/SKILL.md`:

```yaml
---
name: auto-skill-package-integration
description: Auto-detect newly available skill packages from a watched git remote or a watched local directory and bring them through a confirmed install, instead of installing each one by hand. Use when an organization ships skills from a shared folder or feed, when a marketplace should be polled for new releases, or when onboarding a device to a team's skill set. Triggers on auto install, watch directory, watch git, skill feed, marketplace feed, plugin marketplace add, organization skills, team skills, detected skill, new skill available.
---
```

`scripts/check-skill-contracts.mjs` requires the frontmatter keys to be
exactly `name` and `description`, in that order, with `description` a single
line of at most 1024 characters. It rejects `license`, `version`,
`allowed-tools`, and `metadata`, so the trigger vocabulary that would
otherwise live in those keys is folded into `description` — which is what the
harness matches on anyway. `name` must equal the skill's directory name.

---

## §1 · Why this skill exists

The `connected-skill-packages` skill is the **manual**
path: the operator clicks Install / Upgrade / Validate /
Remove. That works for a single marketplace, but it
breaks down for the realistic cases:

- A team that shares skills in a `~/my-org-skills/`
  directory on every developer's machine
- A CI workflow that pushes skill updates to a git repo
  every PR merge
- A third-party marketplace with a stable URL the operator
  wants to follow
- An "org-level" skill package that lives outside any
  individual user's home directory

The auto-integration is the **no-friction path**: the
Companion watches a source, and when a new `SKILL.md`
appears, the Companion auto-installs it (or, in confirm
mode, prompts the operator).

---

## §2 · The two source types

| Source | What it is | How the Companion watches it |
|---|---|---|
| **Git URL** | a git repo with a `marketplace.json` at the root (the HMA, the PMP, any third-party marketplace) | `git fetch` + `git diff` every N minutes (configurable; default 15 min) |
| **Local directory** | a directory on disk with a `SKILL.md` per subdir; no git, no marketplace.json | `notify` (macOS) / `inotifywait` (Linux) / `ReadDirectoryChangesW` (Windows) for fs events |

### §2.1 The Git URL source

A Git URL source is a watched git repo. The Companion
treats it like a slow poller:

1. Every `pollIntervalSec` (default 900 = 15 min), the
   Companion runs `git fetch` on the source's local clone
   and `git diff origin/<branch>...<branch>` to detect
   new commits.
2. If the diff is non-empty, the Companion checks each
   changed `SKILL.md` against the 4-condition install
   contract.
3. New / changed `SKILL.md` files are added to the
   detected-skills list; the operator is prompted
   (confirm mode) or the install runs automatically
   (auto mode).
4. The Companion's `skillSource.lastSeenSha` is updated.

The Companion clones the source into
`~/.prometheus/skill-packages/<source-id>/` (the same
path the manual install uses) and reuses the existing
`install_skill_package` Tauri command.

### §2.2 The local-directory source

A local-directory source is a watched directory. The
Companion installs fs-event watchers:

- **macOS:** `FSEventStreamCreate` (via the `notify` Rust
  crate) — the OS notifies on directory changes
- **Linux:** `inotify_init` + `IN_CREATE` / `IN_MODIFY`
  / `IN_DELETE` on the watched directory
- **Windows:** `ReadDirectoryChangesW` on the watched
  directory

On any fs event, the Companion re-scans the directory
and computes the diff against the last known state. New
or changed `SKILL.md` files are added to the
detected-skills list.

The Companion does **not** recursively watch subdirs of
the source (that would be slow on large directories). It
only watches for new / deleted / modified subdirectories
that contain a `SKILL.md`. A scan interval of 60s catches
anything that fs events miss.

### §2.3 The directory shape (for local sources)

```
~/my-org-skills/                ← the watched directory
├── my-team-rust/               ← a sub-package
│   ├── SKILL.md
│   ├── templates/
│   └── scripts/
├── my-team-frontend/           ← another sub-package
│   ├── SKILL.md
│   └── ...
├── my-team-mobile/
│   ├── SKILL.md
│   └── ...
└── README.md                    ← optional
```

The Companion discovers each sub-directory that contains
a `SKILL.md` and treats it as a **virtual skill package**.
The package id is the directory name; the package
"marketplace.json" is generated on the fly by the
Companion from the discovered skills.

### §2.4 The "virtual marketplace" for local sources

The Companion builds a synthetic `marketplace.json` from
the discovered skills in a watched directory:

```jsonc
{
  "schema_version": "1.0",
  "skill": {
    "id": "my-org-skills",
    "name": "My Org Skills",
    "version": "<mtime of the directory>",
    "status": "prerelease",
    "visibility": "private",
    "source": "<absolute path to the watched directory>"
  },
  "plugins": [
    {
      "name": "my-team-rust",
      "version": "<mtime of my-team-rust/SKILL.md>",
      "source": "<absolute path to my-team-rust>",
      "skills": ["./SKILL.md"]
    },
    {
      "name": "my-team-frontend",
      "version": "<mtime of my-team-frontend/SKILL.md>",
      "source": "<absolute path to my-team-frontend>",
      "skills": ["./SKILL.md"]
    }
    // ...
  ]
}
```

This synthetic manifest is what the Companion's
existing `install_skill_package` Tauri command consumes.
The command path is identical to the git-URL case; only
the watch mechanism differs.

---

## §3 · The two modes

The auto-integration runs in one of two modes
(configurable per-source in the Companion's UI):

1. **Confirm mode** (default) — the Companion detects a
   new `SKILL.md` and shows a toast:
   "Skill `foo` appeared in `~/my-org-skills/`. Install?"
   The operator clicks "Install" or "Skip."
2. **Auto mode** — the Companion installs the new skill
   without asking. The operator gets a notification after
   the install completes.

**Use auto mode only with trusted sources** (a personal
directory, not a public marketplace). Auto mode is the
default only for sources the operator has marked
"verified publisher" (the `verifiedPublisher` flag in
the `recommended-marketplaces.json`).

---

## §4 · The 4-condition install contract (same as the manual path)

Auto-integration is subject to the **same 4-condition
install contract** as the manual path (see
[`01-connected-skill-packages.md`](./01-connected-skill-packages.md)
§4). For a local-directory source, the contract applies
to each sub-package:

1. **Valid manifest** — for git sources, the
   `marketplace.json` is at the repo root. For local
   sources, the Companion's synthetic marketplace is
   well-formed.
2. **Valid `plugin.json`** — for git sources, the
   `plugin.json` is at the repo root. For local sources,
   the Companion derives a `plugin.json` per sub-package
   from the `SKILL.md` frontmatter.
3. **Every `SKILL.md` exists** AND has a valid `name` in
   its YAML frontmatter that matches its directory name.
   Enforced by `scripts/verify-skill-manifest.sh` from
   the HMA.
4. **Idempotent install** — a re-detection of the same
   `SKILL.md` is a no-op (the Companion re-registers with
   the harness but does not duplicate the PEM entity).

If a detected `SKILL.md` fails the contract check, the
Companion does **not** install it; the operator sees
the failure in the "Refinement queue" with the
auto-detect badge.

---

## §5 · The data model (PEM 3.x)

A new PEM entity `skillSource` models the watched
sources:

```ts
// src/domain/entities/skill-source.ts
import { defineEntity } from '@prometheus-ags/prometheus-entity-management'

export const skillSourceEntity = defineEntity({
  name: 'skillSource',
  privacyClass: 'local',   // never server-synced
  fields: {
    id: { type: 'id', clientId: true },
    label: { type: 'string' },
    kind: { type: 'enum', enum: ['git', 'local-dir'] },
    location: { type: 'string' },          // git URL or absolute path
    branch: { type: 'string' },            // for git only
    mode: { type: 'enum', enum: ['confirm', 'auto'] },
    pollIntervalSec: { type: 'number' },   // for git; default 900
    enabled: { type: 'boolean' },
    lastSeenSha: { type: 'string' },        // for git
    lastSeenMtime: { type: 'number' },     // for local
    lastCheckAt: { type: 'datetime' },
    lastDetectedSkills: { type: 'string[]' },
    verifiedPublisher: { type: 'boolean' },  // trusted-source flag
  },
})
```

And a `detectedSkill` PEM entity for the not-yet-installed
skills:

```ts
export const detectedSkillEntity = defineEntity({
  name: 'detectedSkill',
  privacyClass: 'local',
  fields: {
    id: { type: 'id', clientId: true },
    sourceId: { type: 'string', indexed: true },
    packageId: { type: 'string' },
    skillName: { type: 'string' },
    detectedAt: { type: 'datetime' },
    installPath: { type: 'string' },
    status: { type: 'enum', enum: [
      'new', 'confirmed', 'installing', 'installed', 'skipped', 'failed'
    ] },
    errorMessage: { type: 'string' },
  },
})
```

`lane`: **local** (never server-synced). The detected
state is local to the operator's machine.

---

## §6 · The Tauri commands

```rust
// crates/prometheus-companion/src/commands/skill_sources.rs
#[tauri::command]
pub async fn add_skill_source(spec: SkillSourceSpec) -> Result<SkillSource, String>;

#[tauri::command]
pub async fn remove_skill_source(id: String) -> Result<(), String>;

#[tauri::command]
pub async fn check_skill_source(id: String) -> Result<Vec<DetectedSkill>, String>;

#[tauri::command]
pub async fn check_all_skill_sources() -> Result<HashMap<String, Vec<DetectedSkill>>, String>;

#[tauri::command]
pub async fn confirm_detected_skill(id: String) -> Result<(), String>;

#[tauri::command]
pub async fn skip_detected_skill(id: String) -> Result<(), String>;
```

`check_all_skill_sources` is called by a periodic
timer. The Companion also runs `check_skill_source` on
demand when the operator clicks "Check now" in the UI.

### §6.1 The fs-event watcher (Rust)

```rust
// crates/prometheus-companion/src/commands/skill_source_watcher.rs
use notify::{Watcher, RecursiveMode, Event, EventKind};

pub fn watch_local_dir(
    path: PathBuf,
    on_change: impl Fn() + Send + 'static,
) -> Result<notify::RecommendedWatcher, String> {
    let mut watcher = notify::recommended_watcher(move |res: Result<Event, _>| {
        if let Ok(event) = res {
            if matches!(event.kind, EventKind::Create(_) | EventKind::Modify(_) | EventKind::Remove(_)) {
                on_change();
            }
        }
    })?;
    watcher.watch(&path, RecursiveMode::NonRecursive)?;
    Ok(watcher)
}
```

### §6.2 The git poller (Rust)

```rust
// crates/prometheus-companion/src/commands/skill_source_poller.rs
use git2::Repository;

pub async fn poll_git_source(source: &SkillSource) -> Result<Vec<DetectedSkill>, String> {
    let repo = Repository::open(&source.location)?;
    let mut remote = repo.find_remote("origin")?;
    remote.fetch(&[&source.branch], None, None)?;

    let head_oid = repo.head()?.target().ok_or("no head")?;
    let fetch_head = repo.refname_to_oid(&format!("refs/remotes/origin/{}", source.branch))?;

    if head_oid == fetch_head {
        return Ok(vec![]);   // no changes
    }

    // Diff tree from head_oid to fetch_head
    let head_tree = repo.find_commit(head_oid)?.tree()?;
    let fetch_tree = repo.find_commit(fetch_head)?.tree()?;
    let diff = repo.diff_tree_to_tree(
        Some(&head_tree), Some(&fetch_tree), None,
    )?;

    let mut detected = vec![];
    for delta in diff.deltas() {
        let path = delta.new_file().path().ok_or("no path")?;
        if path.extension() == Some("md") && path.file_name() == Some("SKILL.md") {
            detected.push(DetectedSkill::from_path(source, path));
        }
    }
    Ok(detected)
}
```

---

## §7 · The UI

A new "Auto-integrate" panel in the Connected Skill
Packages page shows:

- The watched sources (git URLs and local directories)
- A "Watch this directory" button (opens a file picker)
- A "Watch this git URL" button (opens a URL form)
- The detected-but-not-installed skills (one row each)
  with "Install" / "Skip" actions
- The installed skills (with their source attribution)
- A per-source "Last checked at" + "Last detected" + "Mode"
- A per-source "Check now" button (manual re-scan)

```
┌──────────────────────────────────────────────────────────────────┐
│  Settings → Connected Skill Packages → Auto-integrate            │
├──────────────────────────────────────────────────────────────────┤
│  Watched sources                                                 │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │ ~/my-org-skills/                                         │    │
│  │ local-dir  ✓ confirm mode  ✓ 3 skills detected          │    │
│  │ last checked: 2 min ago  ✓ last detected: 12 min ago    │    │
│  │ [Check now]  [Disable]  [Remove]                          │    │
│  └──────────────────────────────────────────────────────────┘    │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │ git@github.com:my-org/team-skills.git                   │    │
│  │ git  ✓ auto mode  ✓ main  ✓ poll every 15m            │    │
│  │ last checked: 4 min ago  ✓ last detected: 1 hour ago   │    │
│  │ [Check now]  [Disable]  [Remove]                          │    │
│  └──────────────────────────────────────────────────────────┘    │
│                                                                  │
│  Detected (not yet installed)                                    │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │ my-team-rust  /  rust-async-runtime  detected 2h ago     │    │
│  │ from: ~/my-org-skills/my-team-rust/SKILL.md             │    │
│  │ description: "Async runtime patterns for Rust 1.x..."    │    │
│  │ [Install]  [Skip]  [View]                                 │    │
│  └──────────────────────────────────────────────────────────┘    │
│                                                                  │
│  [Watch a directory…]  [Watch a git URL…]                        │
└──────────────────────────────────────────────────────────────────┘
```

---

## §8 · The recommended sources (shipped with the Companion)

The Companion ships with a default
`recommended-sources.json`:

```jsonc
[
  {
    "id": "hma-marketplace",
    "label": "KnowMe Builder (Hybrid Mobile Architecture)",
    "kind": "git",
    "location": "https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill.git",
    "branch": "main",
    "mode": "confirm",
    "pollIntervalSec": 900,
    "verifiedPublisher": true
  },
  {
    "id": "prometheus-skill-pack",
    "label": "Prometheus Skill Pack",
    "kind": "git",
    "location": "https://github.com/Prometheus-AGS/prometheus-skill-system.git",
    "branch": "main",
    "mode": "confirm",
    "pollIntervalSec": 900,
    "verifiedPublisher": true
  },
  {
    "id": "user-shared-skills",
    "label": "My team's shared skills",
    "kind": "local-dir",
    "location": "~/my-org-skills",
    "mode": "auto",
    "verifiedPublisher": true
  }
]
```

The operator can add custom sources via the UI. The
Companion persists the list in
`~/.prometheus/companion/state.json`.

---

## §9 · The hot-reload pattern

When a watched source changes (a `git pull` upstream, a
new `SKILL.md` on disk), the auto-integration detects
the change and runs the 4-condition install contract
on the new / changed skill.

The pattern:

```
upstream commit  ──┐
                   ▼
            Companion polls (or fs-event)
                   │
                   ▼
            diff against last-seen state
                   │
                   ▼
            for each new / changed SKILL.md:
                   │
                   ▼
            run 4-condition install contract
                   │
            ┌──────┴──────┐
            ▼             ▼
        contract        contract
        passes          fails
            │             │
            ▼             ▼
        install         surface in
        (auto or        "Refinement
        confirm)        queue"
            │             │
            └──────┬──────┘
                   ▼
            re-register with
            the active harness
                   │
                   ▼
            persist PEM entity
```

The Companion **never** deletes a skill that was
previously installed; the operator must explicitly
"Remove" it. Auto-integration is **additive only**.

---

## §10 · Security considerations

The local-directory source is the **most dangerous**
source type, because a malicious file in a watched
directory could be auto-installed if the operator
chose auto mode for an untrusted directory.

Defenses:

1. **The 4-condition install contract** — `SKILL.md`
   files are validated against the contract; malicious
   `SKILL.md` files (e.g. with embedded `curl ... | bash`)
   are flagged.
2. **The `verifiedPublisher` flag** — only sources the
   operator has marked trusted can run in auto mode.
3. **The "auto mode" warning** — when the operator tries
   to enable auto mode for an unverified source, the
   Companion shows: "Auto mode is risky for unverified
   sources. Confirm mode is recommended."
4. **The skill-refiner loop** — if a watched skill
   produces a sycophancy flag or a log monitor hit, the
   Companion auto-opens a `bugTicket` and runs the
   realtime skill-refiner loop.

---

## §11 · When to invoke this skill

Invoke when:

- The operator wants auto-install from a git URL or
  local directory
- The operator adds a "Watch this…" action in the UI
- A new `SKILL.md` appears in a watched source
- The Companion's periodic poll detects a change

Do **not** invoke when:

- The user wants to install a single skill from a known
  git URL (use `connected-skill-packages` instead)
- The user is debugging a non-detect issue (use
  `claude-hooks-reliability` instead)

---

## §12 · Skills used (this skill is built on)

- `hybrid-mobile-architecture/skills/connected-skill-packages` —
  the install / upgrade / validate / remove operations
- `prometheus-skill-pack/skills/pem-local-first` — the
  entity pattern
- `prometheus-skill-pack/skills/process/skill-refiner` —
  the underlying refinement (for malicious-skill
  detection)
- `prometheus-skill-pack/skills/process/sycophancy-correction`
  — the bug detector

---

## §13 · Definition of done

- [ ] `skills/auto-skill-package-integration/SKILL.md`
      exists with the frontmatter above
- [ ] The SKILL.md body covers all of §1-§12
- [ ] Mirrored to the 5 per-harness directories
- [ ] Added to the `plugin.json` `skills` array
- [ ] The `skillSource` and `detectedSkill` PEM entities
      are in the Companion's domain
- [ ] The 6 Tauri commands in §6 are implemented
- [ ] The "Auto-integrate" panel renders in the Connected
      Skill Packages page
- [ ] A roundtrip test (drop a new `SKILL.md` into a
      watched dir → Companion detects → operator
      confirms → install completes → entity persisted)
      exits 0
- [ ] A roundtrip test (add a git URL source → Companion
      fetches → detects new skill → operator confirms
      → install completes) exits 0

---

*This is the v0.1.0 spec for the
`auto-skill-package-integration` skill, to be added to
the HMA package in v0.2.0. The skill is the no-friction
path beyond the manual install/upgrade/validate/remove
operations. It supports two source types — a watched
git URL or a watched local directory — and detects new
`SKILL.md` files automatically. The full architecture
review cross-reference is in the joint spec
`05-hma-pmp-companion-architecture.md` and the
architecture review §15.*
