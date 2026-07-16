### 2026-07-15 — kbd-analyze (bootstrap pillars) verdicts
- ADOPT: prometheus-skill-system (public; full install flow documented; verify via pk doctor
  + mcp-health + required binaries), @fission-ai/openspec 1.6.0 (bare 'openspec' npm is
  squatted — scoped name mandatory; channel-aware upgrade), Flutter beta 3.47.0 (releases-JSON
  currency check; dart mcp-server gate; our install-flutter.sh must be fixed — shallow stable
  clone), node@24 pinned (NOT --lts) + bun + pnpm + typescript@latest.
- USER REVISION: TypeScript pillar 6.0+ → 7.0.2 (latest). Scaffold pins updated ^5.x→^7.0.0
  (stale pins = live Rule-22 violation in our own generators, fixed).
- USER DIRECTIVE: 40 Prometheus Base Rules → canonical AGENT_BASE_RULES.md, wired into
  CLAUDE/AGENTS/dispatch-preamble/scaffold-emission/skill-templates. Provenance: user.
- BUILD (extend own): check-env.sh → 4-pillar bootstrap with operational gates; 7-item delta.
- Open: remediation aggressiveness default (recommend check-only default, --install, --full
  for long ops); skill-system clone location; staleness warn-vs-fail (recommend warn).

### 2026-07-15 — Inference architecture revision (user-directed, post-C-102)
- USER DIRECTIVE: replace bespoke Anthropic SSE with **liter-llm gateway**
  (git@github.com:GQAdonis/liter-llm.git fork — 142+ providers, streaming, tool calling;
  crates verified: liter-llm core with native-http feature, liter-llm-ffi, liter-llm-wasm
  → one dependency covers desktop/mobile/web). Requires a **config DB** for provider/model
  settings + administration: pglite-oxide (Tauri/mobile, Rust core) + PGlite (web).
  Folded into C-103 (schema+gateway) and C-109 (admin UI). Provenance: user.
- USER DIRECTIVE: local model inference + download via **mistral.rs fork**
  (git@github.com:GQAdonis/mistral.rs.git — mistralrs library crate: HF download,
  GGUF/ISQ load, Metal/CPU, candle-based; crates verified). Replaces candle-direct in
  C-105 native + C-109 mobile. Fork extras (audio/vision/mcp crates) noted, out of scope.
- RESEARCH (firecrawl, 2026-07): web local-model lane → **WebLLM (MLC)** on WebGPU —
  consensus in-browser chat engine (OpenAI-compatible streaming, curated MLC models incl.
  Qwen2.5-1.5B-Instruct-q4f16_1 matching the native model family, browser-cached).
  wllama (llama.cpp WASM) rejected as primary (CPU speeds don't demo well);
  transformers.js reserved for embeddings/whisper-class web tasks. Documented exception
  to the Rust-core invariant: TS adapter in the web surface behind the same intent seam.
  Sources: webllm.mlc.ai; lofttools.com/blog/browser-llms-2026-webllm-transformers-js;
  localmode.dev/blog/compare/webllm-vs-wllama.
- Memory plan (C-104) explicitly unchanged ("memory is good"). Cargo git deps pinned to
  SHAs at C-103/C-105 implementation time (Rule 22/23).
