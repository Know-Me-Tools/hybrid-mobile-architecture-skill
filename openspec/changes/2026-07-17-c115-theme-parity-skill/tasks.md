# Tasks — 2026-07-17-c115-theme-parity-skill

- [ ] T1 — Rewrite `templates/project-skills/hybrid-design-tokens/SKILL.md`: real
      pipeline workflow, corrected theme-factory framing, generated-files-are-read-only
      rule, link to `references/theming.md`. Keep the directive description/trigger
      words and `[[skill]]` cross-links intact.
- [ ] T2 — Write `references/theming.md` (methodology: token architecture, semantic
      mapping discipline, parity scope statement, pitfalls, OpenDesign pull on-ramp
      with the verified push/KB limitations).
- [ ] T3 — Update `CLAUDE.md` reference index row + `references/ui-skills.md` tables
      (theme-factory row re-labeled; new pipeline referenced).
- [ ] T4 — VERIFY: grep confirms no remaining "emits BOTH" false claim anywhere in
      templates/ or references/; skill still activates via `skill-activation.py`
      matcher on a theming prompt in a scratch project.
