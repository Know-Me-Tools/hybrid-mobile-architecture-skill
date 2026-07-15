# Analysis — phase-codegen-and-ci-verification

> Generated 2026-07-15 · Scope: the skill's **bootstrap/installation process** — four
> toolchain pillars that must be verified-or-installed on any box before the skill
> operates (user-directed addendum to the assessment's PoC scoping). All versions
> verified against live sources on 2026-07-15.

## 0. The requirement

The skill's startup process must run through ALL of the following and confirm each is
installed and operational before beginning work:

1. Rust toolchain + WASM support + a FULL Prometheus Skill System instance
   (https://github.com/Prometheus-AGS/prometheus-skill-system.git) incl. self-improving loops
2. OpenSpec, latest version (spec execution engine)
3. Flutter/Dart beta channel, latest (includes the Dart MCP server)
4. Node.js 24+ LTS, bun, pnpm, TypeScript 7.0.2+ (latest — user-revised from ≥6.0)

## 1. Pillar findings (verified)

### P1 — Prometheus Skill System
- Repo is **public**, active (updated 2026-07-13). ⚠ Docs self-identify as
  "prometheus-skill-pack" but the slug is `prometheus-skill-system` — bootstrap must use
  the correct URL.
- FULL instance = 8 language skill domains + process/architecture skills, the 4-layer
  pipeline (ZeeSpec → PMPO → OpenSpec → forge-rs), self-improving loops (pmpo-outer-loop,
  Karpathy learning loop), 7 Rust binaries built to `~/.local/bin` (`prometheus`, `forge`,
  `pk`, `pk-cherry`, `liter-llm`, `surreal-memory-server`, `prometheus-rust-auditor`),
  MCP services (pk-cherry :8942, forge :8943, surreal-memory :23001 via Docker), hooks.
- Documented install: clone `--recurse-submodules` → `scripts/check-prerequisites.sh
  --install --build-tools` → `install-skills-flat.sh` → `install-mcp-services.sh` →
  `configure-mcp-all-tools.sh` → `prometheus-services.sh load` → surreal-memory docker.
- Prereqs it expects but does NOT install: Rust toolchain, **`wasm32-unknown-unknown`
  rustup target**, Node ≥18, Git; optional Go 1.22+, Docker.
- Verification: `npm run doctor`, `scripts/check-mcp-health.sh`, `pk doctor --json`,
  `prometheus doctor`. Required-binary set for the smoke test: forge/pk/liter-llm/prometheus.
- This machine: substantially installed and live (binaries present, hooks writing,
  plugin MCPs registered; `pk doctor` 2 PASS + 3 expected WARNs). Bootstrap rule:
  treat *binaries present + pk doctor passes + MCP health OK* as installed, regardless
  of clone location.

### P2 — OpenSpec
- Canonical: **npm `@fission-ai/openspec`** (Fission-AI, openspec.dev). Latest **1.6.0**
  (2026-07-10). Brew formula exists but this machine's binary is npm-global (symlink
  into node_modules) despite living at /opt/homebrew/bin.
- ⚠ **The bare npm name `openspec` is squatted garbage (0.0.0, 2022)** — the scoped name
  is mandatory. ⚠ Don't mix brew + npm channels (same binary path) — detect existing
  channel via the symlink and upgrade through it.
- This machine: 1.4.1 — **two releases behind**. Upgrade: `npm i -g @fission-ai/openspec@latest`.

### P3 — Flutter/Dart beta
- Latest beta **3.47.0-0.1.pre** (2026-07-13, Dart 3.13.0-282.1.beta), from the official
  releases JSON (the currency check should query that feed, not hardcode).
- This machine: beta 3.45.0-0.1.pre — **two monthly betas stale**; `flutter upgrade`.
- Dart MCP server ships in any 2026 beta; operational check = `dart mcp-server --help`
  exits 0 (verified locally).
- ⚠ **Our own `scripts/install-flutter.sh` is wrong for this requirement**: it clones
  `--depth 1 -b stable`; a shallow stable clone cannot switch channels. Must clone
  `-b beta` non-shallow (or unshallow first). `flutter upgrade` post-switch is multi-GB,
  5–15 min — no short timeouts.
- After each beta bump, re-verify frb-codegen compatibility (Dart-SDK-sensitive).

### P4 — Node 24 LTS / bun / pnpm / TypeScript 7 (latest)
- Node **24.x is Active LTS** (through Apr 2028); Node 26 becomes LTS Oct 2026 — so
  `fnm install 24` (pinned), NOT `--lts` (a moving target). Machine: 24.16.0 ✓.
- bun latest 1.3.14 (machine ✓, but **check-env.sh doesn't check bun at all**).
- pnpm latest 11.13.0 (machine 11.11.0, fine). Prefer npm-global/standalone over
  corepack (being unbundled from Node).
- **TypeScript pillar → 7.0.2 (latest), user-revised.** npm `latest` = 7.0.2, the
  Go-native compiler — `npm i -g typescript@latest` is now the correct install (no pin).
  Machine has 6.0.3 global → bootstrap upgrades it. Scaffolds updated this pass:
  scaffold-tauri.sh ^5.9→^7.0.0, scaffold-packages.sh ^5.6→^7.0.0 (3 sites) — stale pins
  were a live Rule-22 violation in our own generators. ⚠ TS7 risk to verify at PoC time:
  ecosystem compat (vite plugins, vitest, frb-generated .d.ts consumers) with the native
  compiler; tsconfig defaults are strict/esnext/es2025 since 6.0 — scaffolded tsconfigs
  must stay explicit.

## 2. Build-vs-adopt verdict

**Extend the existing `scripts/check-env.sh`** (adopt/extend own installer) rather than
writing a parallel bootstrap script — it already has the check/install/summary pattern,
is the documented entry point (`bash scripts/check-env.sh --install`), and is invoked by
`scaffold-hybrid.sh`. Restructure it into **pillar-based sections** with per-pillar
`--install` remediation and an explicit "operational" (not just present) gate. Fix
`install-flutter.sh` (beta, non-shallow). Not contested — no alternative scores close.

### The 7-item delta (current check-env.sh → required)
1. Node floor 22→24; `fnm install --lts` → `fnm install 24` (both call sites).
2. Add bun (presence+version; install via bun.sh script).
3. Add TypeScript ≥7.0.2 check; install `typescript@latest` (7.x line, user-directed).
4. Add OpenSpec ≥1.6.0; channel-aware upgrade via `@fission-ai/openspec`; never bare `openspec`.
5. Add Prometheus Skill System: binaries in ~/.local/bin + `pk doctor --json` +
   `check-mcp-health.sh` as operational gates; full documented install flow when missing;
   add its transitive prereqs — **`wasm32-unknown-unknown` target** (check-env currently
   installs only mobile targets) and Docker presence (surreal-memory), optional Go.
6. Flutter **beta-channel enforcement** + minimum (vs releases JSON) + `dart mcp-server --help`
   gate; rewrite install-flutter.sh (`-b beta`, no `--depth 1`).
7. Staleness detection (Flutter beta vs releases feed; openspec vs npm view) — warn-tier,
   not blocking.

## 3. Impact on the phase plan

Adds one foundational change ahead of the PoC work: **C-B01 bootstrap-pillars** (rewrite
check-env.sh into the pillar model + fix install-flutter.sh + doc updates in
CLAUDE.md/AGENTS.md "Required tool versions" → pillar table). The PoC changes from the
assessment then *depend on* a passing bootstrap — which also resolves assessment gap G-1
(frb 2.11/2.12 alignment belongs in the bootstrap's Rust pillar) and pre-verifies the
toolchain the codegen pass needs. This machine's own staleness (Flutter 3.45→3.47,
openspec 1.4.1→1.6.0) becomes the bootstrap's first live test case.

## 4. Open questions

1. **How aggressive is remediation by default?** `flutter upgrade` (multi-GB) and the full
   skill-system install are long operations — recommend: check-only by default, remediate
   under `--install`, long ops behind an additional `--full` flag. (Plan-time default OK.)
2. **Skill-system clone location** when absent: recommend `~/.prometheus-skill-system` or
   respect an env var (`PROMETHEUS_SKILL_SYSTEM_HOME`).
3. Staleness gates: warn vs fail for "installed but behind latest" (recommend warn).

## 5. Base-rules propagation (user directive, applied at analyze time)

The full 40-rule Prometheus Base Rules set is now canonical in-repo at
`AGENT_BASE_RULES.md` and wired into every generation path (done this pass, verify in PoC):

- **Our work**: CLAUDE.md/AGENTS.md reference the file as binding (replacing the
  "session context" reference).
- **Dispatched agents**: `.kbd-orchestrator/dispatch/prompts/_preamble.md` lists it as
  authority #0.
- **Generated projects**: `scaffold-hybrid.sh` copies `AGENT_BASE_RULES.md` into every
  scaffolded project and emits a CLAUDE.md/AGENTS.md declaring it binding.
- **Skills**: all 5 project-skill templates carry a binding-rules preamble; skills
  activated in this repo inherit the mandate via CLAUDE.md.

Plan impact: the PoC build (C-G2/G-5) must verify the emitted rules files land correctly;
scaffold TS pins already corrected ^5.x → ^7.0.0 (Rule 22 self-violation found and fixed).
