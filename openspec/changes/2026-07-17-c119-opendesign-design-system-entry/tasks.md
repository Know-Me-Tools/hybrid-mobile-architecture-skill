# Tasks — 2026-07-17-c119-opendesign-design-system-entry

- [ ] T1 — Generate `DESIGN.md` for KnowMe via the c114 pipeline output; author
      `open-design.json` matching the existing design-system convention (copy the
      stripe entry's shape; i18n titles optional for a first-party-fork entry).
- [ ] T2 — Place the entry in the fork per its contribution policy
      (`plugins/_official/design-systems/knowme/` vs `community/` — check
      `plugins/AGENTS.md`); validate: JSON syntax, `pnpm guard`,
      `od plugin validate` when available.
- [ ] T3 — Add the round-trip workflow section to `references/theming.md`
      (pull-only loop, hash-stamp drift guard, explicit non-goals with the
      docs/plugins-spec.md citations).
- [ ] T4 — VERIFY: with the daemon running, `od mcp` lists the resource
      `od://design-systems/knowme/DESIGN.md` and its content matches the generated
      file; an OD generation run with `designSystem: "knowme"` attaches the context
      (smoke: `start_run` or manual UI run).
