---
type: research-report
title: "Hybrid mobile architecture skill tooling migration: TS 7 .mts→.mjs, native Rust for Windows x64/ARM64, and runnable scaffold contracts"
date: 2026-09-26
confidence: 0.66
verification_status: partial
sources_count: 30
feynman_grade: 0.845
misconceptions_absent: 1.0
contradictions_resolved: 5
okf_version: '0.1'
job_id: job-1790401427-aa9039ab
query: "Assess cross-platform hybrid mobile architecture skill tooling migration (TS 7.0.2 .mts→.mjs without first-party shell/Python; native Rust x86_64/aarch64-pc-windows-msvc; React/Axum, Tauri 2, Flutter+flutter_rust_bridge, shared Rust scaffold contracts)"
depth: deep
citation_style: APA
confidence_below_threshold: true
---

# Hybrid mobile architecture skill tooling migration: TS 7 .mts→.mjs, native Rust for Windows x64/ARM64, and runnable scaffold contracts

> **Confidence:** 0.66 (below the 0.7 plan threshold, flagged for human review) | **Sources:** 30 primary sources | **Feynman grade:** 0.845 (passed; misconceptions absent 1.0; graded by a separate subagent)

## Executive Summary

The migration can work, but only as a support matrix built from evidence. A blanket "runs everywhere" claim would be wrong.

**TypeScript tooling.** TypeScript 7.0 is generally available as a native Go port. The announcement's side-by-side example uses the version range `typescript@^7.0.2` [22]. It ships **no compiler API**, so any tool that needs programmatic compiler access (for example typescript-eslint) must run TypeScript 6.0 alongside it via `tsc6` [22]. `.mts` files are always ES modules [13], and `--rewriteRelativeImportExtensions` rewrites `.mts` import specifiers in the emitted output [14].

**Running tools without a shell.** On Windows, Node cannot start `.cmd`/`.bat` files with `execFile`, and `spawn` fails with `EINVAL` unless a shell is used [16][18]. Current docs deprecate the `shell` workaround (DEP0190) [18]. So "no first-party shell" means resolving real executables rather than calling `.cmd` wrappers.

**Windows ARM64 support.** Both Windows MSVC targets are Tier 1 with host tools [23][26]; `aarch64-pc-windows-msvc` was promoted to Tier 1 in Rust 1.91.0 [30], and MSVC natively cross-compiles between Windows architectures [23]. Dependency support still has to be checked one by one:
- *ring* needs clang plus the ARM64 build tools [21].
- Node.js supports win-arm64 at Tier 2 [17].
- Flutter lists Windows Arm64 as a deployment target [9], but its SDK runs on Arm64 hosts only under x64 emulation [12].
- No retrieved source shows flutter_rust_bridge building or running on Windows ARM64.

**Proving it.** GitHub-hosted `windows-11-arm` runners exist [7], so actual execution evidence can be gathered. This run gathered none.

---

## Key Findings

### 1. First-party runtime: TS 7 `.mts` authored, `.mjs` shipped (SQ1)

- TypeScript 7.0 is a native port written in Go. It performs parsing, type-checking and emitting in parallel [22].
- It turns TS 6.0 deprecations into hard errors: `moduleResolution: node/node10`, `target: es5`, and `module: amd/umd/systemjs/none` are gone. `nodenext` or `bundler` is recommended instead [22].
- **TypeScript 7.0 does not ship a programmatic API.** A different API is expected in 7.1 [22]. Lint or codegen tooling that imports `typescript` must use the `@typescript/typescript6` package, which provides `tsc6` [22].
- `.mts/.mjs/.d.mts` are always ES modules, regardless of `package.json` `type` [13]. `--rewriteRelativeImportExtensions` (since TS 5.7) rewrites relative `.mts` specifiers to their JavaScript equivalents in output [14].
- Node's type stripping is stable in v25.2.0 and v24.12.0 [19]. It does no type checking, runs only erasable syntax, and ignores `tsconfig.json` [19]. Node recommends `module: nodenext`, `rewriteRelativeImportExtensions`, `erasableSyntaxOnly` and `verbatimModuleSyntax` [19].
- *Inference:* shipping compiled `.mjs` keeps the runtime free of any TypeScript dependency and of the type-stripping Node floor. Authoring under `erasableSyntaxOnly` keeps a second path open: the same sources can run directly on Node `^24.12.0 || >=25.2.0` during development.

### 2. Process invocation without a shell (SQ6)

- `.bat`/`.cmd` files are not executable on their own, so `execFile()` cannot launch them [18].
- Since the CVE-2024-27980 fix, passing a `.bat`/`.cmd` to `spawn`/`spawnSync` without `shell` fails with `EINVAL` [16].
- Current docs call `spawn` with `shell` "not recommended" (DEP0190). They list `exec` or `cmd.exe /c` as the ways to run `.cmd`/`.bat` [18].
- *Inference:* a no-shell runner must resolve concrete executables: `node.exe` plus a package's JS entry point, `cargo.exe`, `rustc.exe`, `dart.exe`. Any remaining `.cmd`/`.bat` wrapper needs a documented, argument-validated `cmd.exe /c` exception. Whether the `flutter` and `npm` entry points on Windows are batch wrappers was not checked in this run; test it in preflight rather than assume.

### 3. Rust targets: host tooling vs cross-compilation vs execution (SQ2)

- Rust 1.91.0 (2025-10-30) promoted `aarch64-pc-windows-msvc` to Tier 1 [30]. The rustc book lists it, `x86_64-pc-windows-msvc` and `i686-pc-windows-msvc` as **Tier 1 with host tools** [23][26]. That means rustc/cargo run natively and are tested there [26].
- The MSVC toolchain natively supports cross-compiling from one Windows architecture to another, given the right VS Installer components [23].
- Cross-compiling to `*-windows-msvc` from a **non-Windows host is not supported** [23].
- windows-msvc targets require Windows 10+ for client installs [23].
- *Inference:* the Rust tier guarantees compiler/std behavior. They say nothing about crates with C build scripts (see Finding 4).

### 4. Windows ARM64 dependency support: checked per dependency (SQ3)

| Component | Native host on win-arm64 | Target win-arm64 | Evidence |
|---|---|---|---|
| rustc/cargo | yes, Tier 1 with host tools | yes | [23][26][30] |
| Node.js | yes, **Tier 2** (full test suite; binaries may be delayed) | n/a | [17] |
| Dart SDK | Arm64 "verified" | — | [8] |
| Flutter SDK/tool | **no native SDK**; x64 SDK under emulation (issue open, P3) | yes, deployment target; `build\windows\arm64\…` output | [9][10][12] |
| ring (and any crate depending on it) | needs VS "C++ ARM64 build tools" **and clang**; "no clang" request closed as not planned | — | [11][21] |
| Tauri 2 | build docs cover `--target aarch64-pc-windows-msvc` with the ARM64 build tools; `.msi` only buildable on Windows; Linux/macOS cross only for NSIS, with caveats | yes (build) | [28][29] |
| flutter_rust_bridge | README claims "Windows"; **no Windows ARM64 evidence retrieved** | unknown | [4] |
| Vite/esbuild/rollup native packages | not retrieved in this run | unknown | — |

### 5. Scaffold contracts (SQ4, SQ5)

- **Tauri 2:**
  - Windows development requires the MSVC Build Tools ("Desktop development with C++") and WebView2 [28].
  - Capabilities live in `src-tauri/capabilities/*.json|toml`. All of them are enabled by default until `tauri.conf.json` lists them explicitly [27].
  - Prerequisites say "Windows 7 and later" [28], which conflicts with Rust's Windows 10 floor (see Contradictions).
- **flutter_rust_bridge:**
  - Recommends a `flutter_rust_bridge.yaml` config (`rust_input`, `rust_root`, `dart_output`) and running codegen with no arguments [5].
  - Its Cargokit build glue is tied to the Flutter version (a different Cargokit for Flutter <3.32.0) [6].
- **Pins:**
  - `rust-toolchain.toml` can pin channel, components and **targets**, and is meant to be committed [25]. It sits below explicit overrides in precedence [25].
  - `cargo --locked` fails if `Cargo.lock` is missing or would change [24].
- **React/Axum:** no Axum or Vite primary docs were retrieved within the 30-source cap, so this report makes no Axum-specific contract claim.

### 6. Hook protocols and skill distributions (SQ7)

- **Claude Code:**
  - For most events, only exit code 2 blocks; exit 1 is a non-blocking error [2].
  - Command hooks accept `shell: bash|powershell`, defaulting to PowerShell on Windows [2], and support an `args` array [2].
  - `${CLAUDE_PLUGIN_ROOT}` points at the installed version and changes on update. Persistent state belongs in `${CLAUDE_PLUGIN_DATA}` [3].
  - claude.ai and Cowork **do not install plugins that contain `bin/`** [3].
- **Codex:**
  - Non-managed hooks, including plugin-bundled ones, run only after review, and trust is recorded against the hook's hash [15].
  - It supports a Windows-only `commandWindows` override and runs matching hooks concurrently [15].
- **Agent Skills spec:**
  - `name` is at most 64 characters (lowercase letters, digits, hyphens); `description` is at most 1024 characters [1].
  - Which script languages work depends on the agent [1].

### 7. Reproducibility and independent validation (SQ8)

- SLSA separates "reproducible" (bit-for-bit identical rebuilds) from "verified reproducible" (two or more independent build platforms). It notes that reproducibility does not address source, dependency or distribution threats [20].
- GitHub offers `windows-11-arm` and `windows-11-vs2026-arm` hosted runners [7]. That makes *executed-on-target* evidence obtainable for win-arm64.

---

## Evidence Table

Labels: `verified` (source fetched and supports the exact statement), `unverified` (cited, not checked), `blocked` (check attempted, could not complete), `inferred` (the report's own inference). Critical claims are marked with `*`. Credibility is the stage-05 rubric score. The rubric scores reference docs low on "citation depth" because they carry no bibliography, which pulls down the report-level confidence.

| Claim | Label | Source | Credibility | Confidence |
|-------|-------|--------|-------------|------------|
| *The Agent Skills specification requires SKILL.md with name (max 64 chars, lowercase/digits/hyphens) and description (max 1024 chars) frontmatter. | verified | [1] agentskills.io | 72 | 0.72 |
| *Agent Skills scripts/ language support depends on the agent implementation. | verified | [1] agentskills.io | 72 | 0.72 |
| Agent Skills are loaded progressively: metadata at startup, instructions and resources on demand. | verified | [1] agentskills.io | 72 | 0.72 |
| *In Claude Code hooks, exit code 2 is the only exit code that blocks through the code alone for most events; exit 1 is a non-blocking error. | verified | [2] code.claude.com | 72 | 0.72 |
| *Claude Code command hooks accept a shell field of bash or powershell, defaulting to powershell on Windows. | verified | [2] code.claude.com | 72 | 0.72 |
| Claude Code hook handlers support an args array, allowing an executable plus arguments form. | verified | [2] code.claude.com | 72 | 0.72 |
| *${CLAUDE_PLUGIN_ROOT} resolves to the installed plugin version path and changes on update; persistent state belongs in ${CLAUDE_PLUGIN_DATA}. | verified | [3] code.claude.com | 70 | 0.7 |
| *Claude plugin bin/ executables are placed on the Bash tool PATH, but claude.ai and Cowork do not install plugins that contain a bin/ directory. | verified | [3] code.claude.com | 70 | 0.7 |
| *flutter_rust_bridge v2 claims support for Android, iOS, Windows, Linux, macOS and Web. | verified | [4] github.com | 80 | 0.8 |
| flutter_rust_bridge v2 integrates into existing projects with a one-liner integrate command. | verified | [4] github.com | 80 | 0.8 |
| *flutter_rust_bridge recommends a flutter_rust_bridge.yaml config file and running the codegen with no arguments; config may alternatively live in pubspec.yaml. | verified | [5] cjycode.com | 43 | 0.43 |
| flutter_rust_bridge config keys include rust_input, rust_root and dart_output. | verified | [5] cjycode.com | 43 | 0.43 |
| *flutter_rust_bridge troubleshooting ties Cargokit version compatibility to the Flutter version (e.g. a different Cargokit for Flutter <3.32.0). | verified | [6] cjycode.com | 62 | 0.62 |
| *GitHub-hosted Windows arm64 runners are available under the labels windows-11-arm and windows-11-vs2026-arm for public and private repositories. | verified | [7] docs.github.com | 68 | 0.68 |
| *Dart marks Windows x64 and Arm64 as verified for developing and running Dart code. | verified | [8] dart.dev | 70 | 0.7 |
| *Flutter's supported-platforms page lists Windows Arm64 as a deployment target. | verified | [9] docs.flutter.dev | 74 | 0.74 |
| Flutter Windows build output paths include the target architecture, e.g. build\windows\arm64\runner\Release. | verified | [10] docs.flutter.dev | 76 | 0.76 |
| *The ring issue requesting that aarch64-pc-windows-msvc not require clang was closed as not planned on Feb 25, 2025. | verified | [11] github.com | 76 | 0.76 |
| *Flutter's only Windows SDK assumes an AMD64 host and runs on Windows Arm64 hosts under emulation; the issue to ship a native Arm64 SDK remains open at P3. | verified | [12] github.com | 59 | 0.59 |
| *.mts/.mjs/.d.mts files are always treated as ES modules regardless of package.json type. | verified | [13] www.typescriptlang.org | 73 | 0.73 |
| *Since TypeScript 5.7, --rewriteRelativeImportExtensions rewrites relative .ts/.tsx/.mts/.cts import specifiers to their JavaScript equivalents in output. | verified | [14] www.typescriptlang.org | 72 | 0.72 |
| *Codex requires non-managed hooks, including plugin-bundled hooks, to be reviewed and trusted against the hook's current hash before running. | verified | [15] learn.chatgpt.com | 43 | 0.43 |
| *Codex hooks support a Windows-only commandWindows override. | verified | [15] learn.chatgpt.com | 43 | 0.43 |
| Codex launches multiple matching command hooks for the same event concurrently. | verified | [15] learn.chatgpt.com | 43 | 0.43 |
| *Since the CVE-2024-27980 fix, Node.js errors with EINVAL when a .bat or .cmd file is passed to spawn/spawnSync without the shell option. | verified | [16] nodejs.org | 58 | 0.58 |
| *Node.js lists Windows arm64 (Windows 10+) as a Tier 2 platform, while Windows x64 is Tier 1. | verified | [17] github.com | 92 | 0.92 |
| Node.js Tier 2 platforms have full test coverage and test failures block releases, but binary releases may be delayed by infrastructure issues. | verified | [17] github.com | 92 | 0.92 |
| *On Windows, .bat and .cmd files cannot be launched with child_process.execFile() because they are not executable without a terminal. | verified | [18] nodejs.org | 72 | 0.72 |
| *Node.js documents invoking .bat/.cmd via spawn with the shell option as not recommended (DEP0190), offering exec or spawning cmd.exe with the script as argument instead. | verified | [18] nodejs.org | 72 | 0.72 |
| child_process.execFile() does not spawn a shell by default on Unix-type systems. | verified | [18] nodejs.org | 72 | 0.72 |
| *Node.js type stripping is stable as of v25.2.0 and v24.12.0. | verified | [19] nodejs.org | 47 | 0.47 |
| *Node.js type stripping performs no type checking and executes only erasable TypeScript syntax. | verified | [19] nodejs.org | 47 | 0.47 |
| Node.js ignores tsconfig.json when stripping types, so tsconfig-dependent features such as paths are unsupported. | verified | [19] nodejs.org | 47 | 0.47 |
| .mts files run by Node.js are always executed as ES modules and file extensions are mandatory in imports. | verified | [19] nodejs.org | 47 | 0.47 |
| Node.js recommends tsconfig options module nodenext, rewriteRelativeImportExtensions, erasableSyntaxOnly and verbatimModuleSyntax for code run via type stripping. | verified | [19] nodejs.org | 47 | 0.47 |
| *SLSA distinguishes reproducible builds (bit-for-bit identical output) from verified reproducible builds (two or more independent build platforms). | verified | [20] slsa.dev | 43 | 0.43 |
| *SLSA notes reproducible builds do not address source, dependency, or distribution threats and rebuilders must be truly independent. | verified | [20] slsa.dev | 43 | 0.43 |
| *ring's BUILDING.md requires both the VS 2022 C++ ARM64 build tools and clang components for aarch64-pc-windows-msvc. | verified | [21] github.com | 67 | 0.67 |
| ring cross-compilation requires TARGET_CC and TARGET_AR (or equivalents) to be set. | verified | [21] github.com | 67 | 0.67 |
| *TypeScript 7.0 is generally available as a native port of the TypeScript compiler written in Go. | verified | [22] devblogs.microsoft.com | 75 | 0.75 |
| *TypeScript 7.0 does not ship with a programmatic compiler API; a new, different API is expected in TypeScript 7.1. | verified | [22] devblogs.microsoft.com | 75 | 0.75 |
| *Tools needing programmatic compiler access (e.g. typescript-eslint) must run TypeScript 6.0 side-by-side via the @typescript/typescript6 package, which provides a tsc6 executable. | verified | [22] devblogs.microsoft.com | 75 | 0.75 |
| The TypeScript 7.0 announcement shows a side-by-side install aliasing @typescript/native to typescript@^7.0.2. | verified | [22] devblogs.microsoft.com | 75 | 0.75 |
| *TypeScript 7.0 turns TypeScript 6.0 deprecations into hard errors, including removal of moduleResolution node/node10 in favor of nodenext or bundler. | verified | [22] devblogs.microsoft.com | 75 | 0.75 |
| TypeScript 7.0 no longer supports target es5 or module amd/umd/systemjs/none. | verified | [22] devblogs.microsoft.com | 75 | 0.75 |
| TypeScript 7.0 performs parsing, type-checking, and emitting in parallel. | verified | [22] devblogs.microsoft.com | 75 | 0.75 |
| *aarch64-pc-windows-msvc, i686-pc-windows-msvc and x86_64-pc-windows-msvc are Tier 1 with host tools. | verified | [23] doc.rust-lang.org | 52 | 0.52 |
| *Architectural cross-compilation between Windows platforms is natively supported by the MSVC toolchain when appropriate VS Installer components are selected. | verified | [23] doc.rust-lang.org | 52 | 0.52 |
| *Cross-compilation from a non-Windows host to a *-windows-msvc target may be possible but is not supported. | verified | [23] doc.rust-lang.org | 52 | 0.52 |
| The minimum supported Visual Studio for windows-msvc targets is 2017 but that is not actively tested in CI. | verified | [23] doc.rust-lang.org | 52 | 0.52 |
| *The Rust windows-msvc targets require Windows 10 or higher for client installs (Windows Server 2016+ for servers). | verified | [23] doc.rust-lang.org | 52 | 0.52 |
| *cargo --locked fails when Cargo.lock is missing or would change, and is intended for deterministic CI builds. | verified | [24] doc.rust-lang.org | 43 | 0.43 |
| *rust-toolchain.toml can pin channel, components, targets and profile, and is suitable to check into source control. | verified | [25] rust-lang.github.io | 43 | 0.43 |
| Toolchain selection precedence places rust-toolchain.toml below shorthand, environment and directory overrides. | verified | [25] rust-lang.github.io | 43 | 0.43 |
| *The rustc book lists aarch64-pc-windows-msvc and x86_64-pc-windows-msvc among Tier 1 targets. | verified | [26] doc.rust-lang.org | 84 | 0.84 |
| *Tier 1 with host tools means rustc and cargo run natively on the target and are tested, allowing use as a development platform, not just a compilation target. | verified | [26] doc.rust-lang.org | 84 | 0.84 |
| Tauri 2 capability files live in src-tauri/capabilities as JSON or TOML. | verified | [27] v2.tauri.app | 55 | 0.55 |
| *All capabilities in the capabilities directory are enabled by default until capabilities are explicitly listed in tauri.conf.json. | verified | [27] v2.tauri.app | 55 | 0.55 |
| *Tauri 2 on Windows requires Microsoft C++ Build Tools (Desktop development with C++) and Microsoft Edge WebView2 for development. | verified | [28] v2.tauri.app | 62 | 0.62 |
| *Tauri 2 prerequisites list Windows 7 and later as a supported system. | verified | [28] v2.tauri.app | 62 | 0.62 |
| *Tauri 2 documents building for ARM64 Windows with --target aarch64-pc-windows-msvc after installing the MSVC C++ ARM64 build tools component. | verified | [29] v2.tauri.app | 52 | 0.52 |
| *Tauri .msi installers can only be created on Windows because WiX only runs on Windows. | verified | [29] v2.tauri.app | 52 | 0.52 |
| *Cross-compiling Tauri Windows apps from Linux and macOS is possible only with caveats and only for NSIS installers. | verified | [29] v2.tauri.app | 52 | 0.52 |
| *Rust 1.91.0 (2025-10-30) promoted aarch64-pc-windows-msvc to Tier 1. | verified | [30] blog.rust-lang.org | 72 | 0.72 |
| *Rust Tier 2 targets are guaranteed to build but the test suite is not executed, so produced binaries might not work. | verified | [30] blog.rust-lang.org | 72 | 0.72 |

---

## Contradictions and Resolutions

1. **Flutter Windows Arm64: target vs host** (`inferred`, 0.85).
   - Conflict: Windows Arm64 is a supported deployment target [9], but the only Windows SDK assumes an AMD64 host and runs on Arm64 under emulation [12].
   - Resolution: both are true, at different scopes. A scaffold must declare "Flutter host on win-arm64 = emulated x64 tooling".
2. **Rust Tier 1 vs dependency build needs** (`inferred`, 0.85).
   - Conflict: `aarch64-pc-windows-msvc` is Tier 1 with host tools [23], yet ring additionally requires clang and the ARM64 build tools [21], and removing that requirement is "not planned" [11].
   - Resolution: the tier covers the compiler and std, not C-backed crates. Check each dependency.
3. **"Tier 2" means different things** (`inferred`, 0.9).
   - Node's Tier 2 runs the full test suite and failures block releases [17]. Rust's Tier 2 runs no tests [30].
   - Resolution: quote tier labels together with their project's definition.
4. **`shell: true` for `.cmd`** (`verified`, 0.8, by recency).
   - Conflict: the 2024 advisory offered `{ shell: true }` for sanitized input [16]. The current docs mark it not recommended (DEP0190) [18].
   - Resolution: prefer resolving real executables.
5. **Minimum Windows for Tauri 2 apps** (`inferred`, 0.65).
   - Conflict: Tauri says Windows 7+ [28]. Rust windows-msvc requires Windows 10+ for clients [23].
   - Resolution (inference): on a current toolchain, declare Windows 10+. This was not tested on Windows 7.
6. **flutter_rust_bridge on Windows ARM64** (`blocked`, unresolved).
   - The README says "Windows" [4]. No source addresses ARM64, and the Flutter host is emulated there [12].
   - Needs an actual `windows-11-arm` execution run.

Twenty further candidate pairs came from shared vocabulary (Windows/arm64/tier). The automated semantic judge was unavailable, so they were reviewed manually in-session and rejected as non-contradictory. They are listed under `rejected_candidates` in `contradictions.json`.

---

## Limitations and Gaps

- **No execution evidence.** This was a research-only run: nothing was compiled, cross-compiled or executed. Every "support" statement above is documentary.
- **Unresolved / blocked:** flutter_rust_bridge codegen and Cargokit on Windows ARM64, as host or target (contradiction 6).
- **Not retrieved (30-source cap):**
  - Axum, Vite, esbuild/rollup win32-arm64 packages, WebView2 on ARM64.
  - npm `ci` docs, Gemini CLI and other harness hook docs.
  - Whether `flutter`/`npm` Windows entry points are batch wrappers.
  - The TypeScript 7 native binary's platform matrix (no platform statement found on the announcement page).
- **Semantic contradiction judge unavailable** (no OpenAI-compatible gateway). Contradictions were judged in-session by the same agent that extracted the claims, which is not independent.
- **surreal-memory unavailable** (ECONNREFUSED). The registry, graph and citations exist only on disk.
- **Feynman gate:** passed at 0.845 (completeness 0.68, accuracy 0.85, clarity 0.85, misconceptions absent 1.0; `feynman-gate.json`). The grader was a fresh-context subagent of the same session, not a separate harness. The completeness gaps it named remain open:
  - SQ4: no create-tauri-app layout, `frb_generated` output, Axum + React/Vite setup, shared Rust workspace, or clean-architecture layer mapping from primary docs.
  - SQ3: aws-lc-rs, Axum/tokio, WebView2 on ARM64 and Vite/esbuild/rollup win32-arm64 binaries not covered.
  - SQ5: npm ci, package-lock/pnpm-lock and pubspec.lock not sourced.
  - SQ1: no statement of which Node.js LTS lines run the emitted `.mjs`.
- **Sycophancy check** covered only three narrative sources (the TS 7 announcement took a 10-point penalty for S-03). Reference tables were not submitted.
- **Credibility scores** use organizational authors and page "last updated" dates recorded in stage 05. The rubric's citation-depth dimension systematically underrates reference documentation.

---

## Conclusion and Recommendations

Order of work, as required: first-party runtime conversion, then baseline scaffold repair.

**Phase A: first-party runtime conversion**

1. **Pin the compiler.**
   - Author tools as `.mts` under `module: nodenext`, `rewriteRelativeImportExtensions`, `erasableSyntaxOnly` and `verbatimModuleSyntax`.
   - Compile with an exact `typescript@7.0.2` pin (not the announcement's `^7.0.2` range), emitting `.mjs`.
   - Where tooling needs the compiler API, add `@typescript/typescript6` for `tsc6` [22][13][14][19].
   - Ship only `.mjs`, so users need neither TypeScript nor Python.
2. **One process-runner module, no shell.**
   - `spawn`/`execFile` with `shell: false`, run on an explicitly resolved executable path.
   - Reject `.cmd`/`.bat` targets unless they are on an allowlist and run through `cmd.exe /c` with validated arguments [16][18].
   - Emit a structured error naming the unsupported input.
3. **Hooks as `node` + `.mjs`.**
   - Declare Claude hooks with `command: "node"` and `args: ["${CLAUDE_PLUGIN_ROOT}/…/hook.mjs"]`. Use exit 2 to block [2][3].
   - Use `commandWindows` where Codex needs it, and document Codex's hash-based trust re-review on every hook change [15].
   - Keep state in `${CLAUDE_PLUGIN_DATA}` [3].
4. **Two distributions.**
   - *Mini:* an Agent Skills bundle of `SKILL.md` + `scripts/*.mjs` [1]. As a plugin it would have no `bin/`, which avoids the documented claude.ai/Cowork exclusion [3]. *(Inference: other claude.ai/Cowork install constraints were not checked.)*
   - *Full:* plugin with hooks, plus per-target native Rust binaries delivered outside `bin/`, or accepting the claude.ai/Cowork exclusion.
5. **Native Rust utilities.**
   - `rust-toolchain.toml` pins the channel plus both targets [25]. Build with `cargo build --locked` [24].
   - Build x64 on `windows-latest`. Build arm64 either natively on `windows-11-arm`, or cross-compiled on x64 with the ARM64 build tools [23].
   - Install clang wherever ring is in the tree [21].
   - Execute the arm64 artifact on `windows-11-arm` before claiming support [7]. Do not cross-compile msvc from macOS/Linux [23].

**Phase B: baseline scaffold repair**

6. **Preflight each profile** (host OS/arch × target × stack) against a declared matrix and fail fast on unsupported input:
   - msvc cross-compiling from a non-Windows host;
   - `.msi` from a non-Windows host [29];
   - Windows < 10 [23];
   - Flutter host on win-arm64, marked "emulated" [12];
   - FRB on win-arm64, marked "unverified" [4].
7. **Codegen coherence.**
   - Check in `flutter_rust_bridge.yaml` [5]. Pin the codegen CLI and runtime crate/package to the same version.
   - Check that Cargokit matches the Flutter version [6]. *(Inference: version lockstep between codegen and runtime is standard FRB practice but was not stated in a retrieved source.)*
   - Commit all lockfiles.
8. **Tauri contract.** Ship explicit capability lists in `tauri.conf.json`, so that the default-enable-all behavior does not apply [27]. Declare Windows 10+.
9. **Evidence ledger per profile.** Record three separate evidence classes: host-tool ran, cross-compiled artifact produced, artifact executed on target. Only the last one justifies "supported".
10. **Independent adversarial validation.** A separate runner and separate agent re-build and re-run each claimed profile. Where bit-for-bit reproducibility is sought, use two independent build platforms [20]. Do not promise that untested optional combinations work.

---

## References

[1] Agent Skills project. (n.d.). *Specification*. Agent Skills. Retrieved September 26, 2026, from https://agentskills.io/specification

[2] Anthropic. (n.d.). *Hooks reference*. Claude Code Docs. Retrieved September 26, 2026, from https://code.claude.com/docs/en/hooks

[3] Anthropic. (n.d.). *Plugins reference*. Claude Code Docs. Retrieved September 26, 2026, from https://code.claude.com/docs/en/plugins-reference

[4] flutter_rust_bridge maintainers. (2026, September 12). *flutter_rust_bridge: Flutter/Dart <-> Rust binding generator [Computer software]*. GitHub. https://github.com/fzyzcjy/flutter_rust_bridge

[5] flutter_rust_bridge maintainers. (n.d.). *Provide parameters*. flutter_rust_bridge documentation. Retrieved September 26, 2026, from https://cjycode.com/flutter_rust_bridge/guides/custom/codegen/inputs

[6] flutter_rust_bridge maintainers. (n.d.). *Troubleshooting*. flutter_rust_bridge documentation. Retrieved September 26, 2026, from https://cjycode.com/flutter_rust_bridge/manual/troubleshooting

[7] GitHub, Inc.. (n.d.). *GitHub-hosted runners reference*. GitHub Docs. Retrieved September 26, 2026, from https://docs.github.com/en/actions/reference/runners/github-hosted-runners

[8] Google, Dart team. (2025, October 27). *Get the Dart SDK*. Dart. https://dart.dev/get-dart

[9] Google, Flutter team. (2026, September 22). *Supported deployment platforms*. Flutter Documentation. https://docs.flutter.dev/reference/supported-platforms

[10] Google, Flutter team. (n.d.). *Windows build path changed to add the target architecture*. Flutter Documentation. Retrieved September 26, 2026, from https://docs.flutter.dev/release/breaking-changes/windows-build-architecture

[11] Jasper-Bekkers. (n.d.). *`aarch64-pc-windows-msvc` requires `clang`* (Issue #2117) [GitHub issue]. briansmith/ring. Retrieved September 26, 2026, from https://github.com/briansmith/ring/issues/2117

[12] loic-sharma. (2023, October 11). *[Windows Arm64] Create Flutter SDK for Windows Arm64* (Issue #136417) [GitHub issue]. flutter/flutter. https://github.com/flutter/flutter/issues/136417

[13] Microsoft TypeScript Team. (2026, September 22). *Modules - Reference*. www.typescriptlang.org. https://www.typescriptlang.org/docs/handbook/modules/reference.html

[14] Microsoft TypeScript Team. (2026, September 22). *Modules - Theory*. www.typescriptlang.org. https://www.typescriptlang.org/docs/handbook/modules/theory.html

[15] OpenAI. (n.d.). *Hooks*. ChatGPT Learn (Codex). Retrieved September 26, 2026, from https://learn.chatgpt.com/docs/hooks

[16] OpenJS Foundation, Node.js Project. (2024, April 10). *Wednesday, April 10, 2024 security releases*. Node.js. https://nodejs.org/en/blog/vulnerability/april-2024-security-releases-2

[17] OpenJS Foundation, Node.js Project. (2026, September 24). *Building Node.js (BUILDING.md)*. GitHub. https://github.com/nodejs/node/blob/main/BUILDING.md

[18] OpenJS Foundation, Node.js Project. (n.d.). *Child process (Node.js v26.10.0 documentation)*. Node.js. Retrieved September 26, 2026, from https://nodejs.org/api/child_process.html

[19] OpenJS Foundation, Node.js Project. (n.d.). *Modules: TypeScript (Node.js v26.10.0 documentation)*. Node.js. Retrieved September 26, 2026, from https://nodejs.org/api/typescript.html

[20] OpenSSF SLSA project. (n.d.). *Frequently asked questions (SLSA v1.0)*. SLSA. Retrieved September 26, 2026, from https://slsa.dev/spec/v1.0/faq

[21] ring maintainers (B. Smith). (2026, March 16). *BUILDING.md (ring)*. GitHub. https://github.com/briansmith/ring/blob/main/BUILDING.md

[22] Rosenwasser, D.. (2026, July 8). *Announcing TypeScript 7.0*. TypeScript Blog, Microsoft. https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/

[23] Rust Project. (n.d.). **-pc-windows-msvc. In The rustc book*. Rust Documentation. Retrieved September 26, 2026, from https://doc.rust-lang.org/rustc/platform-support/windows-msvc.html

[24] Rust Project. (n.d.). *cargo build. In The Cargo book*. Rust Documentation. Retrieved September 26, 2026, from https://doc.rust-lang.org/cargo/commands/cargo-build.html

[25] Rust Project. (n.d.). *Overrides. In The rustup book*. Rust Documentation. Retrieved September 26, 2026, from https://rust-lang.github.io/rustup/overrides.html

[26] Rust Project. (n.d.). *Platform support. In The rustc book*. Rust Documentation. Retrieved September 26, 2026, from https://doc.rust-lang.org/rustc/platform-support.html

[27] Tauri Programme (Commons Conservancy). (n.d.). *Capabilities*. Tauri. Retrieved September 26, 2026, from https://v2.tauri.app/security/capabilities/

[28] Tauri Programme (Commons Conservancy). (n.d.). *Prerequisites*. Tauri. Retrieved September 26, 2026, from https://v2.tauri.app/start/prerequisites/

[29] Tauri Programme (Commons Conservancy). (n.d.). *Windows installer*. Tauri. Retrieved September 26, 2026, from https://v2.tauri.app/distribute/windows-installer/

[30] The Rust Release Team. (2025, October 30). *Announcing Rust 1.91.0*. Rust Blog. https://blog.rust-lang.org/2025/10/30/Rust-1.91.0/

---

*Generated by deep-research v1.0.0 — Job ID: job-1790401427-aa9039ab*
