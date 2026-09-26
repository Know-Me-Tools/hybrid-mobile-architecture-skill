# Project tooling and verification

Work is isolated on `codex/hma-portable-tooling`. The original source checkout's
uncommitted work is preserved. No package publication is part of this setup.

## OpenSpec

OpenSpec 1.10.0 was initialized with `--tools all --no-copilot-cloud` against
the existing specifications. It generated 444 skills and 348 commands across
the supported adapters. Codex, Zed and agents share `.agents/skills`. The CLI
also uses the native global MiniMax skills location; Hermes requires its
documented `skills.external_dirs` registration. Generated definitions do not
prove that every harness has loaded them.

The new change is `portable-tooling-and-project-evolution`. Its unchecked tasks
are pending work, not completion receipts. Keep repo-local internal metadata
normalization after OpenSpec refreshes.

## Compass

Compass 0.3.28 initialized `.compass/config.toml` and local `compass-out/` with
structural graph and Program IR. Initial index: 446 extracted files, 16,123
nodes and 17,603 edges. Vendor and build artifacts are excluded. Refresh the
graph after code changes with `compass update`.

The refreshed graph includes TypeScript sources: 566 files, 25,401 nodes,
34,062 edges and 217 Program IR modules. Compass reports **partial** publication
with 276 omitted edges and zero identity collisions. Retain this limitation;
the graph is useful navigation evidence, not a complete dependency proof.

Claude, Codex and OpenCode project MCP configuration adds the `compass` stdio
server while preserving Dart and shadcn servers. The process must start in the
project root; its default graph is `compass-out/graph.json`. No remote service
or credentials are required. The graph output is local ignored build data.

Wire verification used MCP 2026-07-28 `server/discover`, `tools/list` and a
`search_symbols` call for `upgrade_project`; responses are saved under
`docs/assessment/evidence`. This installed server rejects legacy `initialize`.
A harness must support its protocol; project configuration alone is not proof
of an active connection. Restart/reload the harness to discover new servers.
The CLI remains available for graph navigation when a harness cannot connect.

## Maintenance team

The agent-team-creator guide, validation and export created `hma-maintainers`.
The inspectable request lives at `.agent-team/team-request.json`; export
receipts live under `.agent-team/exports`. Native project agent files were
installed for Codex, Claude, OpenCode and Kimi without overwriting prior files.

Responsibilities: portable runtime, native scaffolding/evolution, coordination
and evidence, independent review. Roles inherit the configured harness model;
no pricing or capability guarantee is inferred from its name. Exports are
source-verified definitions, not live certification of all four harnesses.
The team ledger does not replace KBD lifecycle authority.

## Windows targets and CI

Both `x86_64-pc-windows-msvc` and `aarch64-pc-windows-msvc` standard-library
targets were installed in the local Rust toolchain. This macOS host has not
thereby acquired a Windows linker, SDK, native dependencies or native execution.
Both targets are also installed for the canonical Rust 1.97.1 toolchain.

The new portable-tooling workflow runs on Linux, macOS, Windows x64 and native
Windows ARM64. It tests the Node runtime and native Builder separately from
future generated-application certification. Its first successful remote runs
are still required. GitHub documents the `windows-11-arm` hosted runner in its
[runner reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners).
Tauri additionally documents MSVC C++ ARM64 components in its
[Windows build guidance](https://v2.tauri.app/distribute/windows-installer/).

The native Builder's `doctor --native-only` skips the unrelated control-plane
checks; repeat `--target` for the two MSVC architectures. A missing prerequisite
returns a failed result. This is a diagnostic command, not a claim that it has
run a Windows application.

`knowme-builder new --mode runnable` accepts the same repeatable `--target`
preflight and `--verify-ffi`. When either is requested, missing Rust targets,
host-native Windows support, Flutter, Xcode, or Android SDK state fails before
the destination is written. Without those flags, runnable describes the emitted
source contract; native certification still comes from build and runtime gates.

## Research and review

The source audit and evolve-assess baseline are in `docs/assessment`. Read
the remediation plan with the source audits; a low demonstrated-readiness
score is an evidence checklist, not a test failure percentage.

Plan review used the adversarial-review artifact mandate. The requested
cross-model judge was unavailable because of account credits; an isolated
fresh-context native reviewer returned one compiler-identity warning, resolved
by the npm registry check for `typescript@7.0.2`. The anti-theater screen passed
with score 0.0803571417927742. This is not cross-model certification.
