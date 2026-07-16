---
type: Reference
id: c-009-project-skill-templates-for-hybrid-mobile-scaffold
title: C-009 Project Skill Templates for Hybrid Mobile Scaffold
tags:
- hybrid-mobile-architecture
- project-skills
- scaffolding
- claude-hooks
- accessibility
- flutter-golden-tests
- tauri-ui-review
- design-tokens
links:
- hybrid-mobile-architecture-scaffold-phase-initialization
- hybrid-mobile-scaffold-phase-assessment-readiness
- hybrid-mobile-scaffold-phase-executor-completion
sources:
- stdin
timestamp: 2026-07-15T18:57:58.248237+00:00
created_at: 2026-07-15T18:57:58.248237+00:00
updated_at: 2026-07-15T18:57:58.248237+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `scaffold-full-hybrid-project`
- **Position:** `scaffold-full-hybrid-project`
- **Status:** `c009 complete`
- **KBD worktree:** `~/Projects/hybrid-mobile-architecture-src/.kbd-orchestrator/dispatch/worktrees/2026-07-15-c009-project-skills`
- **Captured:** `2026-07-15T18:44:52Z`

This entry records completion of change **C-009 (`project-skills`)** within the scaffold phase initialized by [Hybrid Mobile Architecture Scaffold Phase Initialization](/hybrid-mobile-architecture-scaffold-phase-initialization.md). It follows the broader scaffold assessment flow, including [Hybrid Mobile scaffold phase assessment readiness](/hybrid-mobile-scaffold-phase-assessment-readiness.md) and later assessment updates.

## Phase Goals

- Create a new full instance of the hybrid mobile architecture:
  - Flutter application layer
  - Rust FFI integration layer
  - Tauri shell/runtime integration
  - React 19 frontend surface
- Run scaffolding scripts to generate a complete working project from the reference library.
- Verify generated artifacts conform to `TJ-ARCH-MOB-001`.
- Confirm the environment meets minimum tool version requirements.

## Implemented Artifacts

### Project-local skill templates

Added **5 project-local skill templates** under:

```text
templates/project-skills/
```

Each template includes:

- A directive-style description using `ALWAYS invoke when…`
- Trigger words
- `name` matching the containing folder
- `[[…]]` cross-links

Implemented templates:

| Skill | Purpose |
|---|---|
| `content-block-ui` | Defines the 11-variant `ContentBlock` contract and exhaustiveness expectations. |
| `hybrid-design-tokens` | Establishes one token source that emits Tailwind and `shadcn_flutter` themes. |
| `tauri-ui-review` | Defines screenshot review loop for `320`, `768`, `1024`, and `1440` widths across both themes. |
| `flutter-golden-ui` | Defines VGV golden testing flow plus Dart & Flutter MCP verification. |
| `a11y-gate` | Defines WCAG 2.2 AA cross-surface accessibility checklist. |

### Activation hooks

Added two activation hooks:

- `skill-activation.py`
  - Runs on `UserPromptSubmit`.
  - Matches prompt words to skills.
  - Operates non-blockingly.
- `a11y-reminder.py`
  - Runs on `PostToolUse` after UI edits.

Hook wiring is defined in:

```text
settings.hooks.json
```

### Emitter and scaffold wiring

Added:

```text
scripts/add-project-skills.sh
```

Behavior:

- Performs `jq` deep-merge when available.
- Provides a safe fallback path when `jq` is unavailable or unsuitable.
- Installs project-skill assets additively.
- Is called from all three scaffold scripts.
- Uses `TJ_SKIP_PROJECT_SKILLS` guard to prevent double-installation in the hybrid scaffold path.

### External documentation wiring

Added or updated:

```text
references/ui-skills.md
```

This resolves a dangling `CLAUDE.md` index entry.

## Verification Performed

Boundary behaviors exercised once:

- Fresh install path.
- `jq` merge path preserving prior configuration.
- Hook prompt match path.
- Hook no-match path.
- Hook malformed-input path.
- Python syntax validity.
- JSON validity.

## Scope Boundaries

C-009 intentionally did **not** touch:

- `gen_ui_types`
- `plugin.json`
- `marketplace.json`
- Canonical HTML documentation

Remaining scaffold phase changes `C-001` through `C-012` belong to their own dispatched agents; C-009 is complete and idle. This complements, but does not replace, full scaffold acceptance records such as [Hybrid Mobile scaffold phase executor completion](/hybrid-mobile-scaffold-phase-executor-completion.md), which require concrete artifact verification before acceptance.

## Documented Deviation

`SKILL.md` frontmatter must appear on line 1, so the compliance marker is placed as the first body line instead of before the frontmatter.

## Completion Log

Completion record written to:

```text
.kbd-orchestrator/dispatch/logs/2026-07-15-c009-project-skills.done.md
```

# Citations

1. stdin