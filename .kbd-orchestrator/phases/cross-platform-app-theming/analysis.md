# Analysis — cross-platform-app-theming

_Generated 2026-07-17. Mode: stack-specified (Flutter + Tauri/React 19 + Tailwind 4 fixed
by TJ-ARCH-MOB-001). Inputs: assessment.md (including its two research-agent passes),
plus this stage's Tier 1/3 queries (5 total, under budget)._

## Landscape

The assessment established the problem shape; this stage's research confirms the
landscape has a genuine hole where our requirement sits:

- **`gh search repos "tailwind flutter theme sync"` returns zero results.** Nothing on
  GitHub syncs a Tailwind theme and a Flutter theme from one source. The dual-compile
  pipeline this phase needs does not exist to adopt — anywhere.
- **`gh search repos "style-dictionary flutter"`** surfaces only demos: best hit is
  1★, last updated 2024. No forkable skeleton.
- **Registry health (npm, checked live):**
  - `style-dictionary` 5.5.0 — modified 2026-06-21, actively maintained. ✅
  - `@tokens-studio/sd-transforms` 2.0.3 — modified 2026-01-26, active. ✅ (optional,
    only if Figma/Tokens Studio ingestion is wanted later)
  - `style-dictionary-figma-flutter` 0.6.1 — last published **2022-05-03**. Abandoned.
    ❌ Ruled out (assessment had flagged "maintenance unclear"; now confirmed dead).
- pub.dev candidates were health-checked in the assessment: `design_builder` (1 like),
  `design_tokens_generator` (1 like, own non-standard schema), `figma2flutter`
  (pre-1.0 alpha), `design_tokens_builder`/`token_theme_kit` (unproven). All rejected
  as dependencies; useful only as pattern references.
- `flex_color_scheme` (3.2k likes, 92.6k weekly downloads) is mature but solves a
  different layer (internal Flutter widget-theming consistency, no token ingestion).

## Build-vs-adopt decisions

### D1 — Token build engine: **ADOPT `style-dictionary` v5** (npm devDependency)

The parser/build engine — DTCG-format token parsing, alias/reference resolution,
multi-output builds, transform hooks — is exactly what Style Dictionary does, it's the
industry standard, and it's actively maintained. Writing our own parser would violate
Rule 2 (Simplicity First) in the other direction: hand-rolling reference resolution and
mode/theming semantics is where home-grown token tools rot.

**Simplicity tension, recorded honestly:** today's KnowMe token set is one flat table
(~18 colors × 2 modes + 4 font families). A ~200-line hand-rolled script could compile
that. Style Dictionary earns its place only because this is a *skill package that
generalizes across projects* — future projects will want aliases, tiers
(primitive→semantic), and more output targets. If this were a one-app fix, adopt would
be the wrong call.

### D2 — Dart/Flutter output format: **BUILD first-party** (no viable adoption)

Confirmed twice (assessment tier 3/4 + this stage's tier 1): nothing adoptable exists.
The custom format is the core net-new engineering of this phase. It must emit:

1. An **explicitly constructed `ColorScheme`** (full constructor; `.fromSeed` banned for
   defined brand colors — it invents values for non-primary roles).
2. A `TextTheme` from type-scale tokens.
3. A hand-rolled **`ThemeExtension<T>`** (`AppTokens`) for everything outside Material's
   model: raw brand colors (ember, cyan…), spacing scale, radii, elevation — with
   `copyWith`/`lerp` implemented so light/dark animate correctly.
4. A **semantic mapping table as explicit input, not inference**: flat brand tokens →
   Material slots (e.g. ember→primary, red→error, surface/card→surface/surfaceContainer)
   must be authored per-project in the token file, because Material 3's role model
   cannot be derived mechanically from a flat web palette (assessment pitfall 1).

### D3 — Tailwind/web output: **ADOPT Style Dictionary's `css/variables` format** (thin config, no custom code)

The web side needs only CSS custom properties in the shape
`desktop/src/index.css` already uses (`@theme { --color-*: … }` + `body.light`
overrides). SD's built-in CSS format covers this with minor config; OpenDesign's own
token-first-Tailwind migration is the working precedent for CSS-vars-as-source →
Tailwind `@theme` aliases.

### D4 — Token file format: **W3C DTCG JSON** at `design/tokens.json`

SD v5 parses DTCG natively; DTCG is where the ecosystem is converging; and
`templates/project-skills/hybrid-design-tokens/SKILL.md` already names
`design/tokens.json` as the intended source location — we make its claim true instead
of inventing a new path.

### D5 — Drift audit: **BUILD** (extend `scripts/audit.sh`, no library)

Mechanism: the compiler stamps a content hash of `design/tokens.json` into every
generated file's header comment; `audit.sh` recomputes and compares. Hash mismatch or a
hand-edited generated file fails the audit. Also lint for the two banned patterns:
`ColorScheme.fromSeed(` in app code and raw `Color(0xFF…)` outside generated files
(mirrors OpenDesign's guard that bans default Tailwind palette utilities).

### D6 — Runtime theme wiring: **BUILD** (trivial standard pattern, no package)

`@riverpod` `Notifier<ThemeMode>` + derived `Provider<ThemeData>` computed from
generated constants. `flex_color_scheme` explicitly **not** adopted now — it's an
optional consumer-side layer, and Rule 2 says don't add it until a real widget-coverage
gap shows up in practice.

### D7 — OpenDesign integration: **ADOPT existing surface as-is, read-only pull + one additive entry**

- **Pull:** the existing `od mcp` tools (`get_artifact`, `get_file`, `search_files`)
  already let any coding agent pull a design project's CSS/tokens. The theming skill
  documents this as the ideation→tokens on-ramp. No fork changes.
- **Attach:** one additive `design-systems/knowme/` entry in the fork
  (`open-design.json` + `DESIGN.md`), following the exact convention of the ~150
  existing entries. The `DESIGN.md` becomes a **fourth compiler output** — generated
  from `design/tokens.json`, never hand-authored — so OpenDesign's own generation runs
  stay on-brand from the same source of truth.
- **Deferred (per assessment, verified against `docs/plugins-spec.md`):**
  bidirectional conversational push (no write path to design-system resources exists;
  daemon-only writes) and KB/wiki manifest extension (`od.context` has exactly 7
  fields, none fit; the schema-supported escape hatch is a custom MCP server declared
  in `context.mcp[]`). Both need their own proposals against the fork if pursued.

## Candidate summary

| Gap | Verdict | Candidate | Health |
|---|---|---|---|
| Token build engine | adopt | `style-dictionary@^5.5` | active (2026-06) |
| Figma/Tokens Studio ingest | optional-later | `@tokens-studio/sd-transforms@^2` | active (2026-01) |
| Dart output format | build | first-party SD custom format | — |
| Web output format | adopt-config | SD built-in `css/variables` | ships with SD |
| Flutter theme consumer | reject-for-now | `flex_color_scheme` | active, wrong layer |
| Any pub.dev token codegen | reject | design_builder et al. | unproven/abandoned |
| Drift audit | build | `audit.sh` extension + hash stamps | — |
| Runtime wiring | build | `@riverpod` Notifier pattern | — |
| OpenDesign pull/attach | adopt | existing `od mcp` + plugin convention | in fork today |

## Open questions (for /kbd-spec)

1. **Semantic mapping authoring shape** — where in `design/tokens.json` does the
   brand→Material mapping live (a `$extensions` block per DTCG convention vs. a sibling
   `mapping` section)? Spec must fix this before the Dart format is written.
2. **Compiler invocation point** — pnpm script at project root vs. inside `desktop/`;
   and whether scaffold runs it at generation time (recommended: yes, so a fresh project
   is born in-sync).
3. **rem→dp policy** — declare the fixed mapping (1rem = 16dp) in the skill and document
   the known divergence under user text-scaling (assessment pitfall 4), or attempt
   adaptive scaling (rejected by default: complexity without a requirement).
4. **Retrofit scope** — does this phase fix `apps/knowme-poc/mobile` as the worked
   example (recommended: yes, it's the binding requirement made concrete), or only the
   scaffold + skill?

No contested stack choice arose (stack was specified); no elicitation required.
