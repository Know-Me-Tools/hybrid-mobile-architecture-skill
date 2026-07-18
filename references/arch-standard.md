# Architecture Standard Reference
> TJ-ARCH-MOB-001 · v1.0 · March 2026
> Full document: `docs/tj-arch-mob-001.html`

## Platform selection rules

| Scenario | Platform | Authority |
|---|---|---|
| Consumer mobile (general Android audience) | Flutter + Rust FFI | **Mandatory** |
| Healthcare / regulated industry mobile | Flutter + Rust FFI | **Mandatory** |
| Enterprise desktop (Windows primary) | Tauri + React 19 | Recommended |
| New project with generative UI / artifact rendering (desktop) | Tauri + React 19 | Recommended |
| Any new mobile-first project | Flutter | Default |
| Both mobile + desktop for same product | **Hybrid** (Flutter mobile + Tauri desktop) | Default |

## The invariant: gen_ui_core

`gen_ui_core` is the shared Rust crate used by both Flutter and Tauri. It compiles to:
- `cdylib` → `.so` (Android JNI) and `staticlib` → `.a / XCFramework` (iOS) for Flutter
- Tauri plugin (cdylib / staticlib) for desktop

**What lives in gen_ui_core (never re-implement in Dart/TS):**
- Tokio runtime (one per process, N-1 worker threads + 8 blocking threads)
- Anthropic API client (reqwest HTTP/2 + rustls, SSE streaming, prompt caching)
- A2UI protocol adapter (StreamEvent → A2uiEvent, 27 variants)
- AG-UI protocol adapter (A2uiEvent → AguiEvent, bidirectional)
- Local inference engines behind the `InferenceProvider` trait (pinned llama-cpp-2/Qwen on desktop + mobile / WebLLM web; mistral.rs optional — versions.toml [inference])
- SurrealDB embedded (RocksDB, MemoryStore + ToolCache + EntityGraph)
- MCP client registry (SSE + stdio transports, JSON-RPC 2.0)
- Universal Agent Runtime (PMPO loop, max_turns guard, tool routing)

## UAR integration modes

**Embedded (default for standalone apps):**
The full PMPO loop, MCP registry, and protocol pipeline run inside gen_ui_core.
Appropriate for: KnowMe, TribeHealth mobile, standalone Prometheus AGS field tools.

**External (URL-based, for enterprise):**
UAR runs as a separate service. gen_ui_core in HTTP-client mode connects via URL.
Appropriate for: enterprise deployments where UAR is shared infrastructure.

Configure in `gen_ui_core/src/config.rs`:
```rust
pub enum UarMode {
    Embedded,
    External { url: String, api_key: Option<String> },
}
```

## ContentBlock sealed union — the UI contract

Every A2UI event maps to exactly one ContentBlock variant:

| Block | A2UI Source | Platform widget/component |
|---|---|---|
| TextBlock | TextDelta | StreamingTextWidget / StreamText (assistant-ui) |
| ThinkingBlock | ThinkingDelta | ThinkingBlockWidget / ThinkingPart |
| CodeBlock | CodeBlock | CodeBlockWidget / CodeMirror 6 |
| CitationBlock | CitationBlock | CitationBlockWidget / CitationComponent |
| MemoryBlock | MemoryWrite/Read | MemoryBlockWidget / MemoryComponent |
| ToolUseBlock | ToolCallStarted/Complete | ToolUseBlockWidget / ToolCallComponent |
| ToolResultBlock | ToolResultReceived | ToolResultBlockWidget / ToolResultComponent |
| SkillBlock | SkillActivated/Complete | SkillBlockWidget / SkillComponent |
| ArtifactBlock | ArtifactBlock | ArtifactBlockWidget / Sandpack (Tauri) |
| ImageBlock | inline image | _ImageBlock / ImageComponent |
| DividerBlock | separator | Divider / hr |

## Decision matrix summary

| Dimension | Flutter+FFI | Tauri+React | Hybrid |
|---|---|---|---|
| iOS/Android polish | ★★★★★ | ★★★ | ★★★★★ |
| macOS/Windows/Linux | ★★★★ | ★★★★★ | ★★★★★ |
| Gesture handling (mobile) | ★★★★★ | ★★★ | ★★★★★ |
| UI component richness | ★★★ | ★★★★★ | ★★★★★ |
| Streaming performance (mobile) | ★★★★★ | ★★★★ | ★★★★★ |
| Dev velocity (UI) | ★★★ | ★★★★★ | ★★★★★ |
| Artifact/generative UI | ★★★ | ★★★★★ | ★★★★★ |
| Binary/install size | ★★★ | ★★★★★ | ★★★★ |
| WebView fragmentation risk | None | Significant (mobile) | None on mobile |

## Maintenance ownership (binding for multi-product rollout)

The shared-core/two-shells pattern is a **permanent engineering function, not a
one-time scaffold**. The strongest production precedent (1Password: one Rust
core under Swift/Kotlin/TypeScript shells) maintains a dedicated squad whose
job is the bridge layer between shells and core, plus purpose-built type-sync
tooling — for a single product. Before committing a second product to this
architecture, name the owner (person, fraction of a person, or an agent-run
process with a human accountable) for:

- the frb + Tauri-plugin bridge surfaces (codegen, type sync, streaming seams)
- the embedded-engine lifecycle contracts (see `docs/pglite-oxide-tauri-hybrid.md`)
- `versions.toml` currency and the `audit.sh doc-consistency` gate

If no one owns the bridge, the two-shell strategy silently becomes two
codebases. (Source: 2026-07-16 independent assessment, rec #10.)
