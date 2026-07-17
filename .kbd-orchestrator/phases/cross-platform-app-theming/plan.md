# Plan — cross-platform-app-theming

_Generated 2026-07-17. Backend: OpenSpec (changes already specced in
`openspec/changes/`). No evolver bridge. Library annotations from
`library-candidates.json`._

## Ordering rationale

c114 is the load-bearing change — every other change consumes its outputs (generated
Dart, CSS, DESIGN.md, hash stamps). It runs alone in wave 0. Three changes depend only
on c114 and touch disjoint surfaces (skill templates / scaffold scripts / audit
script), so they parallelize as wave 1. The retrofit (c118) needs the audit (c117) to
prove itself, and the OpenDesign entry (c119) extends the doc c115 writes — both land
in wave 2.

## Waves

### Wave 0 — foundation

1. **2026-07-17-c114-token-pipeline** — `library: style-dictionary@^5.5` (adopt,
   npm health verified 2026-06) + first-party Dart format (build; no adoptable
   candidate exists anywhere). The parity mechanism itself.
   _Recommended agent: this session / opus-class — core engineering, semantic
   mapping judgment._

### Wave 1 — propagation (parallelizable, disjoint surfaces)

2. **2026-07-17-c115-theme-parity-skill** — fix the false `theme-factory` claim;
   `references/theming.md`; index updates. _Docs/skill surface._
3. **2026-07-17-c116-scaffold-theme-wiring** — kill the placeholder `tokens.dart`
   (scaffold-flutter.sh:164) and stock `ThemeData.dark()` (:1279,:1290); projects
   born in-sync. _Scaffold-script surface._
4. **2026-07-17-c117-theme-drift-audit** — hash + lint enforcement in `audit.sh`
   (`fromSeed` ban, raw `Color(0xFF…)` ban, narrow allowlist). _Audit-script surface._

### Wave 2 — proof and integration

5. **2026-07-17-c118-knowme-mobile-retrofit** — depends c114 + c117. The binding
   requirement made concrete: KnowMe mobile renders the exact desktop tokens; audit
   passes in `all` mode; round-trip identity on desktop CSS. **This change is the
   phase's acceptance test.**
6. **2026-07-17-c119-opendesign-design-system-entry** — depends c114 + c115.
   `library: od mcp` surface (adopt as-is, read-only). One additive
   `design-systems/knowme/` entry in the fork; pull-only workflow documented; push/KB
   explicitly deferred.

## Non-goals (recorded so execute doesn't drift into them)

- Bidirectional conversational push into OpenDesign (no daemon write path — needs its
  own proposal against the fork).
- KB/wiki `od.context` manifest fields (schema has exactly 7 fields; escape hatch is
  `context.mcp[]`).
- Pixel-identical rendering across Skia/browser (parity scope = identical token
  values; see assessment pitfalls).

## Exit criteria

- All 6 changes merged/archived; c118's parity evidence recorded in its tasks.md.
- `bash scripts/audit.sh all apps/knowme-poc` (or equivalent invocation) passes with
  the theme check active.
- No `ThemeData.dark(useMaterial3: true)` or placeholder palette remains in
  `scripts/scaffold-flutter.sh`.
