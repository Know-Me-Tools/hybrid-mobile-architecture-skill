# Assessment — cross-platform-app-theming

_Generated 2026-07-17. Project: Hybrid Mobile Architecture (TJ-ARCH-MOB-001 skill package)._

## Summary

The binding requirement — Flutter theme must be **precisely identical** to the React 19
theme, not merely similar — is currently **violated in the one concrete example this repo
has**, and the mechanism that's supposed to prevent that (`hybrid-design-tokens` skill
pointing at `theme-factory`) **does not do what its own documentation claims**. This is a
real, present gap, not a hypothetical one. The assessment below is grounded in file-level
evidence, not inference.

## Evidence: theme drift exists today

Three independent facts, verified in this session:

1. **`apps/knowme-poc/desktop/src/index.css`** — the real, current KnowMe brand: dark-first
   palette, `--color-ember` (#FF6A3D) / `--color-cyan` (#00C2DC) accents on `#0B0F14`
   background, Space Grotesk/Inter/Roboto/JetBrains Mono type stack, explicitly commented
   as "sourced from `docs/reference-app/*.html`."
2. **`apps/knowme-poc/mobile/lib/core/theme/tokens.dart`** — a *different, stale* brand
   system, self-labeled `// travisjames.ai brand system`, with a violet accent
   (`#8B78FF`), different background (`#0D0D18`), different hex values across the board.
   This file is not derived from the desktop tokens; it predates them or was copy-pasted
   from an unrelated project.
3. **`apps/knowme-poc/mobile/lib/main.dart`** — doesn't even reference the `T` tokens
   class from (2). Both `MaterialApp` instances call `theme: ThemeData.dark(useMaterial3:
   true)` — Flutter's stock Material 3 dark theme, zero brand customization applied at
   the point that actually renders the app.

So there are three states in play (desktop-real, mobile-stale, mobile-actually-rendered),
and none of them match. The project's own implementation plan
(`docs/reference-app/knowme-poc-architecture-and-implementation-plan.md:380-381`) already
flags this as open debt: _"Flutter mobile branding parity — the KnowMe tokens live only
in the desktop CSS today; the token→ThemeData mirror lands with the first mobile-facing
change."_ That mirror has not landed.

## Evidence: the claimed fix doesn't exist

`templates/project-skills/hybrid-design-tokens/SKILL.md` (emitted into every scaffolded
project) states: _"Use the `theme-factory` skill (Anthropic) to author/regenerate
tokens: it emits BOTH a Tailwind/shadcn CSS token block and a Flutter theme from one
definition."_

This is false as of the vendored skill. `theme-factory`'s actual `SKILL.md`
(`~/.claude/plugins/marketplaces/skills/skills/theme-factory/SKILL.md`) is a **static,
curated collection of 10 named color/font themes for slide decks and artifacts** (Ocean
Depths, Sunset Boulevard, etc.), applied by picking one and hand-copying its palette/font
pair. It has no token-compilation logic, no Flutter output, no Tailwind output, no
programmatic pipeline of any kind. It is the wrong tool for this job, and the skill that
depends on it is giving downstream agents false confidence that automated parity already
exists.

**This is the highest-priority finding.** Any plan for this phase must either (a) build
the actual token→Tailwind+Flutter compiler that `hybrid-design-tokens` currently only
claims to have, or (b) correct the skill's claims and point at a real tool. Given the
binding requirement, (a) is required regardless.

## Evidence: scaffold-level root cause

`scripts/scaffold-flutter.sh` is where new projects are born, and it reproduces the same
disconnect at generation time:

- Line 164: hardcodes a placeholder `lib/core/theme/tokens.dart` with its own arbitrary
  palette — unrelated to whatever the paired Tauri/React scaffold produces.
- Lines 1279, 1290: hardcode `theme: ThemeData.dark(useMaterial3: true)` into the
  generated `main.dart`.

So the drift found in `knowme-poc` is not a one-off implementation mistake — it's the
scaffold's designed behavior. Fixing only `knowme-poc` would leave every future
`scaffold-hybrid.sh` run reproducing the same bug.

## OpenDesign integration surface (fork at `/Users/gqadonis/Projects/references/open-design`)

Read directly from source (`plugins/spec/SPEC.md`, `apps/daemon/src/mcp.ts`,
`plugins/open-design/.mcp.json`, a live `design-systems/stripe/open-design.json` example,
and the repo's own `specs/change/20260509-token-first-tailwind/spec.md`):

### Plugin format (real, stable, already used by ~150 first-party design-system plugins)

- A publishable plugin is a directory: `SKILL.md` (portable agent contract, YAML
  frontmatter `name`/`description`) + optional `open-design.json` (marketplace manifest).
- `open-design.json` has an `od.mode` enum that **already includes `"design-system"`**
  as a first-class mode, and a `context.designSystem.ref` + `context.assets` field for
  attaching a `DESIGN.md` brand spec to a generation pipeline. Every existing
  design-system plugin (`stripe`, `apple`, `airbnb`, `shadcn`, etc.) is exactly this
  shape: `open-design.json` + `DESIGN.md`.
- **This means a "KnowMe" or "Prometheus" design-system plugin is directly buildable
  today with the existing schema** — no spec change required for the read/reference
  side. `context.assets: ["./DESIGN.md"]` would carry a generated brand doc; `DESIGN.md`
  content would need to be authored/generated from the token source (see Recommendation).
- `od.capabilities` is a small enumerated set: `prompt:inject`, `fs:read`, `fs:write`,
  `mcp`, `subprocess`, `bash`, `network`, `connector`, `connector:<id>`. There is **no
  capability today for "read an external knowledge base" or "push structured business
  analysis / wiki content back into OD's own graph"** — that's new surface, not a
  restriction relaxation.

### MCP server (real, running today via `od mcp --daemon-url http://127.0.0.1:7456`)

Read the actual tool registrations in `apps/daemon/src/mcp.ts` (1858 lines) rather than
guessing:

- **Read tools:** `list_projects`, `get_active_context`, `get_project`, `get_file`,
  `get_artifact` (bundles entry file + all referenced siblings — HTML/JSX/CSS graph
  traversal, preferred over multiple `get_file` calls), `search_files`, `list_files`.
- **Write tools:** `create_artifact`, `write_file`, `delete_file`, `create_project`,
  `delete_project`.
- **Run/agent tools:** `start_run`, `get_run`, `cancel_run`, `list_agents`, `list_skills`,
  `list_plugins`.
- **Design-system and skill content is exposed as MCP *resources*, not tools:**
  `od://design-systems/<id>/DESIGN.md` and `od://skills/<id>/SKILL.md`. The server
  comment at `mcp.ts:596-597` is explicit: _"Reference material is exposed as MCP
  resources, not tools — read `od://design-systems/<id>/DESIGN.md` when you need the
  brand spec."_ Resources in MCP are agent-readable, not natively writable by the
  protocol itself (there's no `resources/write` verb in MCP) — writes go through
  `write_file`/`create_artifact` against project files instead.
- `create_artifact` and `start_run` both accept an optional `designSystem` id
  (`args.designSystem` → `body.designSystemId`), which is how a generation run attaches
  brand context.

### Implication for the user's four asks

1. **"Build plugins/integrations for OpenDesign... to directly consume their
   formatting output for code generation of themes native to React and Flutter."**
   Directly supported today: a coding agent (this one, or any Claude Code / Cursor
   session) can already run `od mcp` and call `get_artifact`/`get_file` against any
   OpenDesign project to pull its generated CSS/token output, then compile that into
   Tailwind `@theme` + Flutter `ThemeData`. No new OpenDesign-side code is required for
   the *pull* direction — only a new **consumer-side** tool/skill in this repo that
   knows how to call the `od` MCP tools and run the token compiler (see Recommendation).
2. **"Leverage OpenDesign's local MCP servers... push changes from our conversations
   into it as well as pulling designs from it."** Pulling is solved as in (1). Pushing
   is also solved for artifact content — `write_file`/`create_artifact` write into an
   OpenDesign project today. What is **not** solved, and needs genuine design work, is
   *conversational* push — i.e., "the insight from this Claude Code conversation should
   update OpenDesign's own brand/DESIGN.md state," which is a two-way sync problem, not
   a single MCP call. Treat this as an open design question for the next stage
   (analyze/plan), not a solved problem.
3. **"Support business analysis ideation and building/maintaining karpathy knowledge
   bases and LLM wikis from the integrations."** No existing hook point in either the
   plugin manifest schema or the MCP tool/resource surface. This is net-new scope. The
   nearest existing analog inside OpenDesign's own plugin taxonomy is the `extend` lane
   (`plugins/spec/SPEC.md` §3: "Help authors create more plugins") and the generic
   `context.assets` array on a plugin manifest, which is a flat file list, not a
   queryable knowledge base connection. A knowledge-base bridge is realistically an
   **external service this repo owns** (e.g., a small adapter that watches
   `.prometheus/knowledge/wiki/` and OpenDesign's DESIGN.md corpus and keeps a shared
   Surreal/graph store in sync), not a thing OpenDesign's plugin format can express
   natively yet.
4. **"If it makes sense to build a general plugin directly into our fork of
   open-design."** Plausible for the narrow "read/attach design-system context" case —
   a `design-systems/knowme/` (or `prometheus/`) entry following the exact
   `open-design.json` + `DESIGN.md` shape already used by the ~150 existing entries
   would let OpenDesign's own AI generate on-brand artifacts using this repo's tokens.
   That is low-risk, additive, and matches existing conventions exactly. Building
   deeper two-way sync or KB integration *inside the fork* is higher-risk (couples this
   repo's roadmap to OpenDesign's upstream release cadence) versus building it as an
   *external* tool that only depends on OpenDesign's already-stable MCP contract. Prefer
   the external-tool lever for anything beyond the DESIGN.md-attachment case; revisit
   in-fork changes only if the MCP/plugin surface genuinely can't express what's needed
   (true today for the KB/wiki-sync ask, per point 3).

## Flutter theming ecosystem research

_Firecrawl-backed research pass, 2025-2026 packages._

**No mature, well-adopted "Style Dictionary for Flutter" formatter exists.** Style
Dictionary itself (style-dictionary/style-dictionary, 4.7k★, v5.5.0, actively maintained,
Amazon-originated / community-governed under styledictionary.com) ships official iOS,
Android, CSS, JS, HTML formats but **no official Dart/Flutter output** — its plugin
architecture (custom transforms/formats) is the designed extension point for adding one,
not a workaround.

Every dedicated community Flutter-token package found is low-adoption and should not be
treated as a dependency to bet the architecture on:

| Package | Signal |
|---|---|
| `style-dictionary-figma-flutter` (npm) | 47★/8 forks, generates Dart data classes (not `ThemeData` directly) |
| `design_builder` (pub.dev) | 1 like, 55 downloads — closest to the stated need (W3C tokens → `ThemeExtension`) but unvetted |
| `design_tokens_generator` (pub.dev) | 1 like, 181 weekly downloads, own JSON schema (not W3C/Style Dictionary) |
| `design_tokens_builder`, `token_theme_kit` (pub.dev) | Same profile — small, unproven |
| `figma2flutter` (pub.dev) | Tokens Studio → Dart, pre-1.0 (v0.3.1-alpha), explicit breaking-change warning |

`flutter_gen` is real and actively maintained (v4.3.0) but is an asset/font codegen tool,
not a theme/token compiler — out of scope for this need.

**The one genuinely mature, high-adoption package in this space is `flex_color_scheme`**
(3.2k likes, 92.6k weekly downloads, 150 pub points) — but it solves *internal Flutter
theming consistency* (every Material widget picks up `ColorScheme` correctly), not
*cross-platform token import*. It has no token-ingestion mechanism of its own.

**Material 3 dynamic color vs. fixed palette:** `ColorScheme.fromSeed` is confirmed the
**wrong** primary mechanism for this requirement — it derives an entire tonal palette
algorithmically from one seed color (HCT color space) for *device-derived* theming, and
will not reproduce exact Tailwind hex values for non-primary roles; it invents them.
Community consensus (RydMike's Adaptive Theming Guide, FlexColorScheme docs) is to
construct `ColorScheme` **explicitly via its full constructor**, mapping each token
value → each semantic slot 1:1, using `.fromSeed` only as an optional fallback generator
for undefined tones — never as the source of truth for defined brand colors.

**`ThemeExtension<T>`** is the official, stable Flutter SDK API for tokens beyond
`ColorScheme`/`TextTheme` (spacing, radii, elevation) — requires implementing `copyWith`
and `lerp`. No dominant codegen tool targets this pattern specifically; the 2025
community default is still hand-written `ThemeExtension` classes with immutable token
structs, not auto-generation.

**Riverpod theme state:** unremarkable — a `@riverpod` `Notifier<ThemeMode>` (or
`AsyncNotifier` if persisted) plus a derived `Provider<ThemeData>` computed from the
generated token constants, watched via `ref.watch` in `MaterialApp.router(theme: ...)`.
No special Riverpod 3.3 considerations found.

**Ecosystem recommendation:** bet on **Style Dictionary (core) with a custom,
first-party-owned Dart/Flutter format** — not any existing community Flutter-token
package. Concrete pipeline: token JSON → Style Dictionary build → (a) existing `css`
format feeding Tailwind v4 `@theme` aliases directly, and (b) a custom Dart format
emitting an explicitly-constructed `ColorScheme`, a `TextTheme`, and a hand-rolled
`ThemeExtension<T>` for non-Material tokens. Treat `flex_color_scheme` as an optional
consumer-side layer on top of the generated `ColorScheme`, not the pipeline itself.
Revisit this space in 6-12 months — Style Dictionary v5, Tokens Studio, and the DTCG
(W3C) format are still moving targets.

## Deep-research + sycophancy-check pass

_External prior-art research plus an adversarial self-check via the
sycophancy-correction MCP tool._

**External prior art:** Style Dictionary is confirmed as the dominant multi-platform
token pipeline (W3C Design Tokens 2025.10-draft compatible), validating "one token
source, multiple compiled outputs" as sound — consistent with OpenDesign's own
CSS-vars-first Tailwind migration already reviewed above. **No mature, published
Figma/AI-tool → Flutter+React dual-compile pipeline exists anywhere** — only separate
single-target pipelines (Figma→React, or Figma→Flutter via Tokens Studio + Widgetbook).
One team's public issue tracker explicitly names the opposite of success: a Flutter app
whose hand-written `ThemeData` "makes the mobile app easy to drift away from the web
app's design-system tokens" — described as a live, unsolved pain point elsewhere, which
is exactly the failure mode already found in this repo's `knowme-poc`.

**Known pitfalls (industry-wide, not specific to this repo):**

1. Material 3's tonal-surface/elevation/seed-role model actively fights a flat brand
   palette — semantic remapping is required, not just value substitution — and any
   token the Material model doesn't cover needs a `ThemeExtension` escape hatch with
   correct `copyWith`/`lerp`.
2. Third-party widgets and platform/native views can silently ignore theme tokens — a
   known Flutter gap that matters especially at this architecture's FFI/native-surface
   boundaries.
3. Font metrics differ between Flutter's (Skia) text layout engine and a browser's, even
   given identical font files and nominal sizes — "same font, same size" does not
   guarantee the same rendered line box.
4. **`dp` and `rem` are not the same abstraction and don't convert 1:1** — `rem` tracks
   the document root font size (user/OS adjustable); Flutter's `dp` is device-pixel-ratio
   logical pixels tied to physical density, not user font-size preference. A naive
   `1rem = 16dp` mapping diverges under browser zoom or OS text-scaling/accessibility
   settings.
5. Flutter Web has documented overflow bugs under large font-scale/pixel-ratio
   combinations — pixel-stable layout and full a11y text scaling are in tension even
   within Flutter's own web target.

**Practical implication carried into this assessment:** "precisely the same theme"
should be explicitly scoped to **tokens** (color roles, type scale, spacing scale,
radius, elevation values) rather than literal pixel-identical rendering — the latter is
not achievable across a Skia canvas and a browser layout engine, industry-wide, not a
gap specific to this stack. The binding requirement in `goals.md` should be read as
"same token values, applied through each platform's own rendering pipeline," and the
plan/spec stage should say this explicitly so "precisely the same" isn't later
misread as pixel-perfect parity.

**Critique of the in-progress plan (adversarial, not rubber-stamped):**

- **Token-compiler architecture (Claim 1): well-supported.** Confirmed sound by both
  Style Dictionary's production use and OpenDesign's own internal precedent.
  `theme-factory` as it exists today is confirmed the wrong tool and needs to become an
  actual transform pipeline — a real, scoped engineering task, not a rename.
- **"OpenDesign MCP supports bidirectional sync" (Claim 2): does NOT hold up.** Checked
  directly against `docs/plugins-spec.md` (line 636: "only the daemon writes
  `AppliedPluginSnapshot`; CLI/UI clients are read-only") and the general posture of
  `context.designSystem.ref` as an input *resolved into* a run, never a target written
  back to. `write_file` exists but operates on OD **project files**, not on
  design-system **reference resources** (`od://design-systems/<id>/DESIGN.md`) — these
  are different object types in the system. Conversational "push into OpenDesign" as
  the user described it (updating the canonical design-system reference from a
  Flutter/React coding session) is **not supported by the documented surface today**.
  Either treat OpenDesign's design system as a one-way pull at scaffold time (re-pull on
  drift, no live sync), or accept that genuine bidirectional sync requires new write
  endpoints on the OD daemon itself — a change to OpenDesign, not to this skill package.
- **"Build a new plugin directly inside the OpenDesign fork" (Claim 3): not the default
  choice.** This repo's actual point of contact is skills embedded in *scaffolded*
  Flutter/Tauri projects, which need to work whether or not OpenDesign is even running.
  An external tool that calls OpenDesign's existing MCP tools to *pull* tokens, then
  runs them through the Style-Dictionary-style compiler, achieves the requirement
  without touching the fork at all. In-fork work should be justified specifically (e.g.
  OpenDesign's own users want a first-class dual-platform-token mode), not adopted
  by default merely because OpenDesign is the design tool in use.
- **"Extend the plugin manifest for business-analysis/KB context" (Claim 4): not a
  manifest-only change.** `docs/plugins-spec.md` (line 273-283) enumerates
  `od.context`'s actual fields: `skills`, `designSystem`, `craft`, `assets`,
  `claudePlugins`, `mcp`, `atoms` — no knowledge-base/ideation field exists. Adding one
  requires daemon-side resolution into the agent's system prompt (`composeSystemPrompt()`,
  §11.3), loader validation, and `ApplyResult` round-tripping — real OpenDesign-side
  code, not a JSON edit. The schema's own documented escape hatch (§22: compose a custom
  MCP server declared in `context.mcp[]`, already schema-supported per the Figma-migration
  example) is the lower-risk path if this is pursued at all.

**Sycophancy check result:** `detect_sycophancy` (strict) ran against a draft conclusion
paragraph and returned `sycophancy_score: 0.045` with one flagged pattern — **S-06,
medium severity: high-confidence language without a derivable reasoning chain.** The
flagged text had called bidirectional sync "a minor implementation detail... clearly
supported already," citing only that `write_file` exists. On inspection that claim was
not just unsupported but **actually wrong** — `write_file` targets project files, not
the read-only design-system resource the sync requirement targets. `correct_sycophancy`
in `full_restructure` mode errored (requires explicit reasoning-before-conclusion
structure already in place), so the fix was applied directly: Claim 2 above now leads
with the specific spec citations before stating the conclusion, rather than asserting
feasibility first.

## Gaps against phase goals

| Goal (from `goals.md`) | Status |
|---|---|
| Author a theming skill defining tokens → Tailwind + Flutter methodology | **Not started.** `hybrid-design-tokens` exists but delegates to a tool (`theme-factory`) that can't do this. |
| Flutter theme MUST be precisely identical to React 19 theme (binding) | **Currently violated** — three-way drift documented above. |
| Document methodology with `theme-factory` as prior art | Prior art claim is **inaccurate**; must be corrected, not just cited. |
| Worked example from KnowMe reference app | **Real token source exists** (`desktop/src/index.css`) and is usable directly — no need to reverse-engineer from the static HTML docs. |
| Wire into `scaffold-hybrid.sh`/`scaffold-flutter.sh` | **Root cause confirmed** at `scaffold-flutter.sh:164,1279,1290` — scaffold hardcodes an unrelated placeholder theme and stock Material dark theme. |
| Audit/lint hook for drift | **No existing mechanism.** `scripts/audit.sh` was not found to have any theme-token check. |
| Update CLAUDE.md reference index | Not started; straightforward once the skill exists. |
| OpenDesign plugin/MCP integration (user's added scope) | Existing MCP + plugin surface is real and directly usable for pull/attach; push-conversation-to-OD and KB/wiki integration are open design problems, not yet supported by OpenDesign's schema. |

## Recommendation for next stage (analyze/plan)

1. Treat "fix the false claim in `hybrid-design-tokens` + ship a real token compiler" as
   the P0 deliverable — everything else depends on it existing. Bet the compiler itself
   on **Style Dictionary (core) with a custom, first-party-owned Dart/Flutter output
   format** — not any existing community Flutter-token package (all are low-adoption,
   several pre-1.0). Pipeline: token JSON → Style Dictionary → (a) `css` format feeding
   Tailwind v4 `@theme` aliases, (b) a custom Dart format emitting an **explicitly
   constructed** `ColorScheme` (never `.fromSeed` for defined brand colors — it invents
   values for undefined roles), a `TextTheme`, and a hand-rolled `ThemeExtension<T>` for
   spacing/radius/elevation tokens outside Material's model.
2. Scope the binding requirement precisely in the spec: "precisely the same theme" means
   **identical token values** consumed through each platform's own rendering pipeline,
   not literal pixel-identical rendering — that's unachievable across Skia and browser
   layout engines industry-wide (font metrics, `dp` vs `rem` scaling differ structurally)
   and shouldn't be an unstated implicit bar this work gets judged against later.
3. Use `apps/knowme-poc/desktop/src/index.css` as the canonical token source for the
   worked example (real, current, already in-repo) rather than re-deriving from the
   static HTML spec docs.
4. Scope deliverables distinctly and in this order:
   - (a) the token-compiler skill/tool itself (P0, per #1)
   - (b) the scaffold fix (`scripts/scaffold-flutter.sh:164,1279,1290`) so new projects
     stop generating an unrelated placeholder theme and stock `ThemeData.dark()`
   - (c) an audit/lint check (extend `scripts/audit.sh`) that fails when Flutter
     `ColorScheme`/`ThemeExtension` values have drifted from the canonical token source
   - (d) the OpenDesign design-system plugin entry (`design-systems/knowme/
     open-design.json` + generated `DESIGN.md`, following the exact existing ~150-entry
     convention) as a separate, smaller, low-risk **read-only pull** addition — no fork
     changes needed beyond adding this one entry
5. Do **not** attempt "push conversational insights into OpenDesign" as part of this
   phase — verified against the spec (`docs/plugins-spec.md`: "only the daemon writes
   `AppliedPluginSnapshot`; CLI/UI clients are read-only") that the documented MCP/plugin
   surface has no write path to design-system reference resources today. If genuine
   bidirectional sync is still wanted, it's a separate proposal against the OpenDesign
   fork itself (new daemon write endpoints), not achievable by wiring existing tools.
6. Do **not** attempt the "karpathy knowledge base / LLM wiki" integration as a plugin-
   manifest change — `context` has exactly 7 fields today (`skills`, `designSystem`,
   `craft`, `assets`, `claudePlugins`, `mcp`, `atoms`), none of which fit, and adding one
   requires daemon-side resolution/validation code in the fork, not a JSON edit. If
   pursued, prefer the spec's own documented escape hatch — a custom MCP server declared
   in `context.mcp[]` (already schema-supported) — over waiting on a core schema change.
