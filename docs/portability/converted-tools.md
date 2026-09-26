# Portable tool runtime

First-party hooks and orchestration are authored under `runtime/src` in strict
TypeScript 7.0.2 and emitted as Node `.mjs`. Consumer invocation requires Node
22 or newer, without a compiler, Bash, Python, jq or a full Prometheus checkout.
The development toolchain remains pinned in `versions.toml`; the runtime's
lockfile pins compiler and bundle dependencies.

```text
npm ci --prefix runtime
npm run build --prefix runtime
npm test --prefix runtime
node scripts/check-portable-runtime.mjs
node scripts/sync-harness-skills.mjs --check
```

The language gate detects both `.sh`/`.py` files and extensionless shell/Python
shebangs. The migration ledger inventories 79 original files, including three
extensionless test fixtures. Historical prose remains historical evidence.

Portable process orchestration uses argument arrays and propagates child exit
codes. Node package CLI shims resolve to their JavaScript entrypoints. The
Flutter SDK's own Windows batch launchers have a narrowly scoped vendor adapter;
unknown batch-only tools receive a diagnostic. Vendor SDK/native build internals
are dependencies, not first-party runtime scripts.

## Native utilities

Use `knowme-builder` for generation, adoption, ownership and upgrades. Use the
Rust `knowme-platform-native` helper for APK archive/ELF inspection; it checks
actual ELF class/machine bytes as well as native dynamic dependency metadata.

```text
cargo install --locked --path tools/knowme-builder
cargo install --locked --path tools/platform-native
rustup target add --toolchain 1.97.1 x86_64-pc-windows-msvc aarch64-pc-windows-msvc
knowme-builder doctor --native-only --target x86_64-pc-windows-msvc --target aarch64-pc-windows-msvc
```

Windows compilation does not establish linking or native execution. MSVC, the
Windows SDK, native libraries and appropriate runners remain requirements.
Android native tests use LLVM to compile real ELF fixtures. iOS/Xcode and device
checks must run on their supported hosts; unavailable tools never become passes.

## Distribution

`stage-skill-package.mjs --variant full|mini --output <new-directory>` stages
identical package contents and per-file hashes. The variant changes only the
receipt. Outputs must be outside the source tree and must not already exist.
The staging gate rejects path collisions, Windows-incompatible names, symlinks
and first-party shell/Python payloads. The source-only dispatch command is
excluded because it requires this repository's Git/OpenSpec execution state.

Staging is separate from publishing into either skill-pack repository. The
consumer payload includes native Rust source and resources; installation of
native binaries or a suitable Rust toolchain is still required for native work.
Runtime tests exercise install/uninstall from both copied distributions and
preservation of existing skills. Committed-ref consumer proof is a separate gate.

## Intentional behavior changes

- Scaffold wrappers reject ignored legacy options; use the typed native CLI.
- Refiner replay takes JSON argument arrays; shell replay strings are rejected.
  A ticket without successful replay cannot be verified or shipped.
- Installers track exact file ownership and preserve pre-existing/edited skills
  and MCP entries. Unsupported source/ref combinations fail before mutation.
- `check-env` reports missing/mismatched prerequisites with a failing exit;
  full Prometheus service checks require explicit `--with-prometheus`.
- Old shell-only Prometheus bootstrap remains unavailable through the portable
  installer rather than silently reintroducing a Bash dependency.
- Extension cleanup defaults to dry-run; applying its retention policy needs
  an explicit `--apply`. Dispatch preserves native harness permission settings.

Generated application certification and versioned semantic migrations remain
tracked in the OpenSpec change and assessment plan. Managed-file recovery is
implemented, but it does not establish those broader guarantees.
