# Tasks — 2026-07-16-c112-tauri-custom-titlebar-skill

> Delivered 2026-07-16. Skill lives at `templates/project-skills/tauri-custom-titlebar/`;
> registered in `scripts/add-project-skills.sh`, the activation hook's trigger map, and
> the README/AGENTS/CLAUDE skill lists. Install verified against a scratch project root.

- [x] T1 — Author `templates/project-skills/tauri-custom-titlebar/SKILL.md`: frontmatter
      with a directive, trigger-rich description; Base Rules binding block; the
      TJ-ARCH-MOB-001 marker — matching the conventions of the sibling skills.
- [x] T2 — Document the desktop pattern: `decorations: false` in tauri.conf.json, the
      Titlebar component contract, macOS traffic-light vs Windows/Linux control order,
      and `startDragging()` on mousedown (with the reason `data-tauri-drag-region`
      alone is insufficient for the whole bar).
- [x] T3 — Document surface gating and OFFER OPTIONS rather than defaulting: the
      `isTauri()` module-scope guard (Tauri API calls throw in a plain web page), and
      per-surface alternatives — web: browser chrome + optional in-app header, no window
      controls; mobile/PWA: platform app bar, never a desktop title bar. Agents must
      pick deliberately per surface.
- [x] T4 — Document the a11y contract: aria-labels on every control, keyboard
      reachability, and the fact that removing OS chrome removes OS-provided
      accessibility affordances that must be replaced.
- [x] T5 — Cross-link from the skill index / README the same way sibling project-skills
      are surfaced; verify the PoC's existing Titlebar.tsx matches what the skill
      prescribes (it is the reference implementation).
