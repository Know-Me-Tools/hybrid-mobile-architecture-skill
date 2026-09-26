# Portable tooling audit

Read-only baseline: source checkout at `/Users/gqadonis/Projects/hybrid-mobile-architecture-src`; implementation starts from isolated worktree `hybrid-mobile-architecture-portable` at `153f20c`. No audit claim establishes Windows execution.

## Evidence

- `git ls-files '*.sh' '*.py' '*.mts'` found **68 shell files, 8 Python files, zero .mts files** in the baseline, including generated harness mirrors. Count is a tracked-file inventory, not 76 independent implementations.
- `.claude/settings.json:8,21` and `templates/project-skills/settings.hooks.json:8,20` invoke Python hooks. The Claude adapter (`.claude/hooks/skill-activation.py:9-16`) depends on a template outside its installed directory. The canonical activation hook handles malformed input and emits Claude hook JSON (`templates/project-skills/hooks/skill-activation.py:44-74`). OpenCode already has an ESM adapter but uses a different prompt/output shape and lowercase behavior (`.opencode/hooks/skill-activation.mjs:14-34`). Preserve each harness envelope rather than merely renaming scripts.
- `scripts/add-project-skills.sh:33-84` discovers and copies skills but requires find, chmod, jq and mktemp. Existing settings are merged; conversion must preserve unrelated entries and idempotence.
- `scripts/install-harness-package.sh:59-64` mandates git/jq/node/npx; `:75-84` assumes Unix state locations; `:128` uses find; `:180-220` and `:367-420` manage uninstall receipts/config. Native Windows npm .cmd shims require resolving their Node entrypoint, not blanket shell execution. Partial installation must not lose ownership receipts.
- `scripts/sync-harness-skills.sh:9-15,30-37,60-72` establishes canonical `skills/` and generated copies in templates plus six harness trees. Preserve vendored OpenSpec skills outside that canonical set.
- `scripts/normalize-vendored-skills.sh` parses the contract's exported harness/count table and executes Python for frontmatter edits. OpenSpec all-tool initialization now produces 12 skills including propose/update-change; ten-skill hardcoding is stale.
- `scripts/scaffold-hybrid.sh:12-16` ignores legacy options. `scripts/lib-knowme-builder.sh:7-16` already delegates to native Rust, falling back to Cargo. Keep Rust as the only generator, and reject unsupported wrapper arguments before destination writes.
- `scripts/check-env.sh:328-353` downloads shell installers; `:367-386` claims unpinned latest TypeScript. The declared compiler pin is 7.0.2 and development Node is 26.5.0; consumer Node >=22 is a separate policy.
- `assets/templates/scripts/android/build.sh:9-19` hardcodes a macOS SDK fallback and requires Python. iOS orchestration legitimately requires an Apple host; portability means precise host eligibility, not claiming Windows can build iOS.
- `scripts/run-all-gates.sh:40-60` is itself shell and invokes other shell gates. The generated-drift entry mutates artifacts before checking. `.github/workflows/production-convergence.yml:61` tests Ubuntu/macOS only. Windows x64 and ARM64 remain unverified.
- `references/arch-standard.md:16-46` makes shared Rust and explicit UAR modes architectural invariants. `CLAUDE.md:251-278` defines feature boundaries. Hook/runtime conversion must not replace those with a second JavaScript app generator.

## Package integration evidence

Full pack `package.json` currently declares TypeScript ^6.0.3; mini has no compiler dependency and Node >=22. Neither is an existing TS7 source pipeline. The installed agent-team-creator runtime supplies an actual strict NodeNext `.mts` → `.mjs` precedent with exact typescript 7.0.2 and @types/node 22.18.6.

Mini `scripts/AGENTS.md:23-49` requires exec-form hooks, argument arrays, Node CLI entrypoint resolution, native path APIs, atomic writes, CRLF tolerance, copies rather than symlinks, no executable-bit dependence, and complete hook payloads. Mini `lib/distribution/package-builder.mjs:37-52,70-99` rejects symlinks and copies only discovered skills and explicit hook targets; imported module dependencies therefore need an explicit payload contract. Full `scripts/hook-entry.mjs:22-29,79-89` uses Node only as a bootstrap for a compiled dispatcher; copying this file would import full-pack runtime dependencies. Reuse the portable principles, not that activation stack.

## Migration ownership and boundary

Portable-runtime maintainer: strict TypeScript source/build; emitted Node hooks and process launcher; hook installation/verification; canonical skill mirror sync/normalization; scaffold forwarding wrappers; portable harness installer; migration inventory and integration tests. Native maintainer: Rust environment/target diagnostics, generation/adoption/upgrade behavior and generated native platform build helpers. Coordinator: OpenSpec/Compass/team setup, docs/current invocation references, CI and full/mini payload integration. Independent reviewer: findings only.

Remaining shell/Python programs must stay explicitly pending until behavior is ported and live callers updated. Do not delete a script merely to reduce the count. Historical evidence and genuine third-party build internals are exemptions; first-party templates, deploy tools and vendored first-party skill copies are not. Preserve public argument/exit/output contracts where valid; reject previously ignored options explicitly.

## Acceptance

Run emitted .mjs from a copied payload with spaced/Unicode paths and no shell/Python/jq dependency; execute real stdin/stdout hook protocols, config installation twice, user-file preservation, uninstall ownership and child exit forwarding. Build reproducibly using the lockfile and verify emitted bytes. On native Windows x64 and ARM64, prove CLI resolution, paths, file replacement, installed payload operation and relevant Rust toolchains; local macOS success is not Windows evidence. Native scaffold build/run verification is a separate gate from portable-script success.
