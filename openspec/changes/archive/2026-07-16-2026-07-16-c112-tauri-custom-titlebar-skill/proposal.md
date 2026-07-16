# 2026-07-16-c112-tauri-custom-titlebar-skill

> Phase: phase-codegen-and-ci-verification · Status: proposed
> Assigned harness/model: claude/opus-4.8
> Depends on: (none — extracts existing PoC code)
> Binding: AGENT_BASE_RULES.md (all 40 rules)

## Why

The KnowMe PoC desktop app replaced the OS title bar with a branded custom one
(`tauri.conf.json` `decorations: false` + `desktop/src/shared/components/Titlebar.tsx`):
platform-correct window controls (traffic-light order on macOS, right-aligned on
Windows/Linux), and click-and-hold drag via an explicit `startDragging()` call rather
than relying on `data-tauri-drag-region` alone.

We will want this on **almost every Tauri application**, so it belongs in the skill
package rather than living once in the PoC. Extracting it also captures the two
non-obvious defects the PoC already solved: the drag-region attribute only fires on a
direct mousedown against that element (spacers stay dead without the explicit call),
and every Tauri API import throws at module scope in a plain web page.

## What changes

- New project-local skill `tauri-custom-titlebar` in `templates/project-skills/`,
  following the established SKILL.md conventions (directive description, Base Rules
  binding, TJ-ARCH-MOB-001 marker).
- Skill documents the full pattern: tauri.conf window config, the component contract,
  platform-conditional control placement, drag handling, and the a11y/keyboard story.
- **Surface gating is a first-class part of the skill, not an afterthought.** A custom
  desktop title bar is wrong for web and mobile: browsers own their chrome and there is
  no window to drag, minimize, or close; mobile has no window chrome at all. The skill
  MUST make agents choose per surface rather than emitting the title bar everywhere —
  offering the alternatives (no title bar / plain web header / mobile app bar) instead
  of a Tauri-only component leaking into a PWA or Flutter build.
- Reference the existing `isTauri()`-gated implementation as the worked example.

## Impact

- Additive: a new skill template; no change to PoC runtime behavior.
- Scaffolded projects pick the skill up via the existing project-skills copy path.
