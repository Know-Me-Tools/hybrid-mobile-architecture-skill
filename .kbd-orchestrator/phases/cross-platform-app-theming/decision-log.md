# Decision Log — cross-platform-app-theming

### 2026-07-17 — Analyze stage decisions

- **D1 adopt `style-dictionary@^5.5`** as the token build engine (npm health verified
  live: 5.5.0, modified 2026-06-21). Provenance: research (assessment tier 3/4 +
  analyze tier 1/3). Simplicity tension recorded: a flat one-app token set could be
  hand-compiled; SD is justified because this skill package generalizes.
- **D2 build the Dart output format first-party.** No adoptable candidate anywhere
  (gh best hit 1★ demo; pub.dev field all 1-like/alpha/abandoned;
  `style-dictionary-figma-flutter` confirmed dead — last publish 2022-05).
  Hard rules baked in: explicit `ColorScheme` constructor (`.fromSeed` banned for
  defined brand colors), `ThemeExtension<T>` with `copyWith`/`lerp`, authored
  brand→Material semantic mapping as input (never inferred).
- **D3 adopt SD built-in `css/variables`** for the web/Tailwind output (config only).
- **D4 W3C DTCG JSON at `design/tokens.json`** — makes `hybrid-design-tokens`'
  existing claim true rather than inventing a new path.
- **D5 build drift audit** into `scripts/audit.sh` via token-hash stamps in generated
  file headers + `fromSeed`/raw-`Color(0xFF…)` lints.
- **D6 build runtime wiring** as plain `@riverpod` Notifier + derived Provider;
  `flex_color_scheme` explicitly rejected-for-now (wrong layer, Rule 2).
- **D7 OpenDesign: read-only pull via existing `od mcp` + one additive
  `design-systems/<brand>/` entry** whose `DESIGN.md` is a generated compiler output.
  Bidirectional push and KB/wiki manifest extension **deferred** — verified
  unsupported by `docs/plugins-spec.md` (daemon-only writes; `od.context` = exactly
  7 fields). Escape hatch if pursued later: custom MCP server via `context.mcp[]`.
- **No contested stack choice** — stack fixed by TJ-ARCH-MOB-001; no elicitation run.

### 2026-07-17 — Spec stage decisions

- **Backend: openspec** (project.json `openspec_available: true`; prior-phase changes
  follow `openspec/changes/<id>/{proposal.md,tasks.md}`). Ran `openspec init --tools
  claude,codex,opencode,kimi --force` per user direction — Zed is not a supported
  adapter in OpenSpec 1.6.0, so it was skipped (flagged to user).
- **Six changes cut** (c114–c119): pipeline → skill/docs → scaffold wiring → drift
  audit → PoC retrofit (the binding requirement's worked example) → OpenDesign
  design-system entry. Deferred scope (OD push, KB/wiki fields) stated as explicit
  non-goals inside c119 rather than left ambient.
- **Open question resolutions baked into c114:** brand→Material mapping lives in
  `design/theme.config.mjs` as Dart-format options (DTCG has no file-level
  `$extensions`; a mapping group would parse as tokens); invocation is a root
  `pnpm tokens:build` run at scaffold time; rem→dp fixed at 1rem = 16 logical px
  with divergence documented; PoC retrofit confirmed in-phase (c118).
- ZeeSpec gate: inactive (no `.zeespec/`), verdict n/a.
