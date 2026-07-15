# C-009 project-skills — DONE (claude/sonnet-5), REVIEWED, merge-pending

Delivered (all plan deliverables present):
- templates/project-skills/{content-block-ui,hybrid-design-tokens,tauri-ui-review,
  flutter-golden-ui,a11y-gate}/SKILL.md — directive "ALWAYS invoke when..." descriptions
  with rich trigger keywords (activation research applied)
- templates/project-skills/hooks/{skill-activation.py,a11y-reminder.py} + settings.hooks.json
- references/ui-skills.md (external shortlist + project-local + activation mechanics)
- scripts/add-project-skills.sh (emitter) + scaffold-{hybrid,flutter,tauri}.sh wiring

QA: SKILL.md frontmatter well-formed; ContentBlock contract accurate; scaffold wiring sane.
Cleaned: stray __pycache__/*.pyc removed.

MERGE CAVEAT: branched from main BEFORE C-001. Its scaffold-hybrid.sh edits target the OLD
single-crate layout (rust/gen_ui_core). Must reconcile against C-001's rewritten
scaffold-hybrid.sh at merge — take C-009's skill-install hunk, keep C-001's layered-workspace
invocation. Do NOT fast-merge.
