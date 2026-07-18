# Research Brief: Agentic UI Protocols, Agent-Harness Extensibility, and Hybrid Client/Cloud Agent Patterns

**Slug:** `agentic-ui-agent-harness-patterns`
**Author role:** KNOWME_RESEARCHER (deep-research swarm)
**Date:** 2026-07-18
**Scope:** Web research on (a) agentic UI protocols (AG-UI, A2UI, MCP-UI/MCP Apps, A2A, Vercel AI SDK UI, HTMX, the owner's `gen_ui` category), (b) Agent Skills / SKILL.md harness extensibility + WASM "native skills", (c) client-side vs cloud-hosted agents and hybrid orchestration, (d) settings-schema + synced storage precedents.
**Master-goal lens:** everything below is analyzed for the local-first + realtime KnowMe architecture — pglite/pglite-oxide clients syncing via flint-realtime-fabric to flint-forge postgres, cooperating local/cloud agents, WASM component model for native skills + A2UI/AG-UI/HTMX UI modules + settings schemas, CRDT over WebRTC, decentralized packaging.

---

## 1. Agentic UI protocols — what exists, how they work, maturity 2025–2026

### 1.1 The 2026 protocol stack in one picture

The ecosystem has converged on a four-layer split (this exact framing appears in Oracle's Mar 2026 blog aligning Open Agent Spec + AG-UI + A2UI, and in CopilotKit's FAQ):

| Layer | Protocol | Owner / steward | Job |
|---|---|---|---|
| Agent ↔ tools/data | **MCP** (+ MCP Apps for UI) | Anthropic → Linux Foundation (Agentic AI Foundation) | Tool/resource access; MCP Apps renders tool-linked UI |
| Agent ↔ agent | **A2A** | Google → Linux Foundation (Jun 23, 2025) | Opaque agent collaboration, agent cards, tasks |
| Agent ↔ user (runtime connection) | **AG-UI** | CopilotKit (open protocol, May 2025) | Bi-directional event stream: messages, tool calls, shared state |
| Agent → UI (presentation format) | **A2UI** | Google (open-sourced Jan 2026; v0.9 Apr 17, 2026) | Declarative JSON UI descriptions rendered with native components |

Oracle's one-liner worth stealing for the architecture doc: "**Agent Spec defines what runs, AG-UI carries the interaction, and A2UI defines what the user touches.**" [Source: Oracle AI & Data Science blog, "Reusable Agents Meet Generative UIs", 2026-03-12, https://blogs.oracle.com/ai-and-datascience/announcing-agent-spec-for-a2ui-copilotkit-ag-ui]

### 1.2 AG-UI (CopilotKit) — Agent-User Interaction Protocol

**What exists (facts):**

- Open, lightweight, **event-based** protocol standardizing how agent backends connect to user-facing apps. Announced May 12, 2025; docs at `docs.ag-ui.com`, reference repo `ag-ui-protocol/ag-ui` (GitHub). [Sources: https://webflow.copilotkit.ai/blog/introducing-ag-ui-the-protocol-where-agents-meet-users (2025-05-12); https://github.com/ag-ui-protocol/ag-ui (accessed 2026-07-18)]
- ~16 event types in five categories (text streaming, tool orchestration, state sync, run lifecycle, custom), each with `type` + minimal payload: `TEXT_MESSAGE_CONTENT`, `TOOL_CALL_START`, `STATE_DELTA`, etc. Runs over plain HTTP+SSE or WebSocket, with an optional binary serializer. [Source: Codecademy, "AG-UI: How the Agent-User Interaction Protocol Works", 2026-01-23, https://www.codecademy.com/article/ag-ui-agent-user-interaction-protocol]
- Feature set: real-time agentic chat w/ streaming, **bi-directional state synchronization**, generative UI & structured messages, real-time context enrichment, frontend tool integration, human-in-the-loop. [Source: github.com/ag-ui-protocol/ag-ui, accessed 2026-07-18]
- Maturity (Jul 2026): 1st-party integrations with Microsoft Agent Framework, Google ADK, AWS Strands, Mastra, Pydantic AI, Agno, LlamaIndex, AG2; partnerships w/ LangGraph + CrewAI; **community SDKs in Kotlin, Go, Dart, Java, Rust, Ruby, C++** (Dart + Rust SDKs matter directly for this workspace); A2A supported as an agent-interaction protocol; MCP Apps listed under "Generative UI". React Native client marked "Help Wanted". CopilotKit ships first-party React/Angular clients + hosted Copilot Cloud (guardrails; analytics "Cockpit" and RLiHF "Learning" both marked Coming Soon). [Source: github.com/ag-ui-protocol/ag-ui README, accessed 2026-07-18]

**How it works:** client POSTs once to the agent endpoint, then consumes a single unified JSON event stream; agents emit events as work happens; the frontend renders partial text, tool UIs, and state diffs as they arrive. Shared mutable state is diffed via `STATE_DELTA` events rather than resent.

**Implications for the master goal:**

- AG-UI is the strongest existing candidate for the **agent↔UI runtime wire** between `gen_ui_core` (Rust) and Flutter/Tauri frontends. The owner's existing design already anticipated this: `docs/gen_ui_spec.html` (TJ-SPEC-GENUI-001, v1.0.0, Mar 2026) defines an internal `AguiClient` with "state tree · pending confirmations · render slots · bidirectional events" and a Dart `AguiEvent` sealed class (12 variants) — aligning these with the actual AG-UI event vocabulary would buy interoperability with LangGraph/CrewAI/Microsoft AF backends "for free".
- The community **Rust AG-UI SDK** could live inside `gen_ui_core` as a module (ag-ui client/server), preserving the "all agent logic in Rust" invariant while speaking a public protocol.
- `STATE_DELTA` is a natural seam to back with CRDT sync over flint-realtime-fabric: shared agent state becomes a synced document, giving offline + multi-device agent sessions.

**Gaps/risks:** spec is CopilotKit-governed (no foundation stewardship like A2A/MCP); hosted guardrails/analytics are paywalled in Copilot Cloud; mobile clients (React Native, Flutter) are community/"help wanted" quality — the owner would own the Flutter client story (already does, via gen_ui).

### 1.3 A2UI (Google) — declarative generative UI spec

**What exists (facts):**

- Google's open protocol for Generative UI. Open-sourced as a public project in **January 2026**; **v0.9 released April 17, 2026** with CopilotKit as design partner. Docs/spec at `a2ui.org`, repo `google/A2UI` on GitHub. [Sources: https://hia2ui.com/blog/a2ui-official-public-release/ (2026-01-04); https://www.copilotkit.ai/blog/a2ui-whats-new-in-google-generative-ui-spec (2026-04-17)]
- Core message verbs (JSON, streamed over JSONL + other transports): **`createSurface`, `updateComponents`, `updateDataModel`, `deleteSurface`** (+ streaming signals like `begin-rendering`). Surfaces are bound to a **catalog** identified by URL (e.g. `https://a2ui.org/specification/v0_9/basic_catalog.json`). [Source: Mete Atamel, "Agent to UI Protocol (A2UI) with Agent Development Kit (ADK)", 2026-03-30, https://atamel.dev/posts/2026/03-30_a2ui_with_adk/]
- v0.9 changes vs v0.8: schema moved into the system prompt (prompt-generate-validate loop replaces structured-output constraints), flat standard JSON, **bidirectional messaging** (client reports UI state/actions back to the agent), modular schema split into four files, **catalog negotiation handshake**, new Python Agent SDK (Go + Kotlin in development). [Source: CopilotKit A2UI v0.9 post, 2026-04-17]
- Renderers: official React renderer; production Flutter, Angular, Lit renderers (Flutter/Angular used internally at Google); shared web core library. Ecosystem: AG2, A2A 1.0, Vercel json-renderer, Oracle Agent Spec. Sample apps include a Personal Health Companion (Rebel App Studio) and Life Goal Simulator (Very Good Ventures). [Sources: gentic.news, 2026-04-19, https://gentic.news/article/google-launches-a2ui-0-9-a; hia2ui.com, 2026-01-04]
- Security model: "Trusted Catalog" — the agent sends **declarative JSON intent only, never executable code**; the client renders with its own native components. This is explicitly positioned as the enterprise-safe alternative to raw HTML/iframe generative UI. [Source: nxcode.io, "A2UI v0.9 and Agent-Driven UI", 2026-07-04]

**How it works:** handshake negotiates a catalog (client declares which widgets it can render + their prop schemas) → agent streams component-tree descriptions + data-model updates → client renders with native widgets and reports user actions/data-model changes back. Agent decides *structure*; client owns *implementation, styling, allow-list*.

**Implications for the master goal:**

- A2UI's **catalog + data-model split is almost exactly the owner's `ContentBlock` protocol generalized**. The owner's `gen_ui` spec already defines an internal "A2UI" (`A2uiEvent` sealed class, 27 variants, parsed from Anthropic SSE in Rust, mapped 1:1 to ContentBlock mutations). Decision for the architecture doc: either (i) converge on Google A2UI v0.9 as the cross-surface wire format and express ContentBlocks as an A2UI **custom catalog**, or (ii) keep the internal 27-variant protocol but add an A2UI adapter. Option (i) maximizes interop with AG-UI clients, CopilotKit A2UI Composer, and Google GenUI; option (ii) keeps exhaustive-sealed-union compile-time safety in Rust/Dart. A middle path: ContentBlock stays the internal canonical type; A2UI JSONL becomes the **external serialization** — one serde mapping in `gen_ui_core`.
- **Catalog negotiation** is the distribution hook: a WASM component/extension from the flint-forge registry can ship an A2UI catalog fragment (widget schemas + renderer bindings), giving the "A2UI/AG-UI/HTMX UI modules" in the master goal an industry-standard manifest shape.
- `updateDataModel` (JSON Pointer paths into a client-side data model) is a per-surface mini-state-sync channel — a clean place to bind pglite-backed reactive state.

**Gaps/risks:** pre-1.0 (v0.9; "v1.0 candidate" language in Jan 2026), schemas still moving; prompt-based generation means validation/fallback UX is the app's problem; Rust SDK absent (Python/Go/Kotlin first) — owner would write the Rust (de)serializer (fits the gen_ui_core invariant anyway).

### 1.4 Google GenUI SDK for Flutter — the owner's category, validated

**What exists (facts):**

- **GenUI SDK for Flutter** is now official Flutter documentation (`docs.flutter.dev/ai/genui`, page updated 2026-05-27, reflecting Flutter 3.44; showcased at **Google I/O 2026** in "Flutter + A2UI = GenUI"). Packages: `genui` (^0.8.x), `genui_dartantic`, `genui_a2a`, `json_schema_builder` in `github.com/flutter/genui`. [Sources: https://docs.flutter.dev/ai/genui (2026-05-27); https://stackademic.com/blog/generative-ui-in-flutter-genui-and-the-a2ui-protocol (2026-06-26)]
- Architecture: **Catalog** (widget vocabulary: name + JSON Schema data schema + builder fn), **ContentGenerator** (AI-provider abstraction), **A2uiTransportAdapter**, **SurfaceController/GenUiManager**, **DataModel** (centralized client state), **GenUiSurface** (render widgets), **GenUiConversation** (facade). [Source: stackademic.com GenUI/A2UI article, 2026-06-26]
- The team is **splitting the library into a pure-Dart `genui_core`** (A2UI message parsing, JSON Pointer state management, expression evaluation) + Flutter-only renderer, explicitly "to make the core logic fully portable to non-Flutter environments" — milestone ~40% complete as of Apr 2026. [Source: Very Good Ventures, "Getting Started with Flutter GenUI SDK", 2026-04-16, https://verygood.ventures/blog/getting-started-with-genui/]
- Status: alpha/experimental; hallucination guardrails + fallback UIs are the app's responsibility. [Source: freeCodeCamp, "How to Use GenUI in Flutter", 2025-12-23]

**Implications:** The owner's `gen_ui` concept (Rust protocol layer → ContentBlock sealed union → compiler-enforced exhaustive rendering in Flutter) is **the same category Google is now standardizing** — this de-risks the concept and raises the bar: KnowMe's differentiators must be (1) Rust-side protocol enforcement (Google's is Dart-only), (2) local-first sync + offline, (3) WASM-component catalogs from a decentralized registry. Watch `genui_core`: if its A2UI parser matures, the Tauri/desktop side could consume the same A2UI stream in TypeScript via the web-core library while Flutter consumes via genui — one stream, two surfaces, which is precisely the hybrid mobile+desktop story of TJ-ARCH-MOB-001.

### 1.5 MCP-UI and MCP Apps — UI as MCP resources

**What exists (facts):**

- **MCP-UI** (`MCP-UI-Org/mcp-ui`, by Ido Salomon + Liad Yosef): community SDKs (`@mcp-ui/server`, `@mcp-ui/client`, Python `mcp-ui-server`/`mcp-ui`, Ruby `mcp_ui_server`) for shipping `UIResource` payloads from MCP servers. Three content types: **externalUrl** (iframe), **rawHtml** (string), **remoteDom** (Shopify remote-dom scripts; mime `application/vnd.mcp-ui.remote-dom`). Rendered in sandboxed iframes; UI actions postMessage back to host (tool call / intent / prompt / link / notify). [Sources: https://github.com/MCP-UI-Org/mcp-ui (accessed 2026-07-18); https://pypi.org/project/mcp-ui/ (2025-09-11)]
- **MCP Apps** — the standardized path: an official MCP extension (`@modelcontextprotocol/ext-apps`) linking tools to UIs via `_meta.ui.resourceUri`; hosts fetch via `resources/read` and render with `AppRenderer`; `text/html;profile=mcp-app` mime type. Released **January 2026**; hosts supporting it include Claude, VS Code, Postman, Goose, MCPJam, LibreChat, mcp-use, Smithery; ChatGPT requires an Apps SDK adapter. Tool visibility can be scoped (`ui.visibility: ["app"]`) so fragment-fetch tools aren't exposed to the LLM. [Sources: github.com/MCP-UI-Org/mcp-ui README (accessed 2026-07-18); htmx.org essay below]
- The MCP-UI repo explicitly lists roadmap items: declarative UI content type, "Support generative UI?" — i.e., even the MCP-UI camp expects convergence with A2UI-style declarative specs. [Source: github.com/MCP-UI-Org/mcp-ui, Roadmap section]

**Implications:** MCP Apps is the **server-driven UI module** channel: a KnowMe extension can expose both tools and their UI iframes over the same MCP-style connection — directly relevant to flint-forge's extension registry. Remote-DOM is the interesting middle ground between raw HTML (unsafe, unstyled) and A2UI (fully declarative): DOM-mutation scripts replayed against a **host component mapping** — architecturally close to the owner's ContentBlock→widget mapping and worth supporting as a third module type alongside A2UI catalogs and HTMX fragments.

**Gaps/risks:** iframe sandboxing isolates state — sync must cross the postMessage bridge (this is a feature for security, a cost for reactivity); no Rust server SDK (TS/Python/Ruby only).

### 1.6 A2A (Agent2Agent) — agent↔agent

**Facts:** Google announced A2A at Cloud Next, **April 9, 2025**, with 50+ partners; donated to the **Linux Foundation June 23, 2025** (Agent2Agent Protocol Project w/ AWS, Cisco, Google, Microsoft, Salesforce, SAP, ServiceNow); spec at **v1.0** (some sources cite v0.3.0 as the current working version — the spec versioned quickly through 2025–26), Apache 2.0, SDKs in Python/JS/Java/C#/Go. Discovery via **Agent Card** at `/.well-known/agent-card.json` (name, `protocolVersion`, `capabilities` {streaming, pushNotifications, stateTransitionHistory, extensions}, auth schemes, `skills[]` with input/output MIME modes). Transport: JSON-RPC 2.0 (+gRPC, HTTP+JSON bindings), `message/send`, `message/stream` over SSE, `tasks/get`; task states submitted→working→completed/canceled/rejected/failed; artifacts stream via `TaskArtifactUpdateEvent`. Opaque-to-opaque: no shared memory, no shared tools — only the contract crosses the wire. [Sources: https://neurals.ca/tech/gemini/a2a-protocol/ (2026-05-27); https://agenticcommerceprotocol.info/standards/a2a (2025-04-09); https://a2aproject.github.io/A2A/dev/specification/; https://google.github.io/A2A/specification/sample-messages/]

**Implications:** A2A is the right protocol for **client-side agent ↔ cloud agent cooperation across trust boundaries** — the local agent in KnowMe can expose an agent card (even on localhost/LAN) and delegate heavyweight tasks to flint-forge-hosted agents, while keeping its internals opaque. A2A's `extensions` capability + the AP2/x402 precedent show the extension mechanism for domain payloads. Note AG-UI already supports A2A as a transport-level integration, so the three can compose: A2A (delegation) → AG-UI (run stream) → A2UI (surfaces).

**Gaps/risks:** streaming is SSE (server→client); long-lived offline-then-reconcile task semantics are out of scope — CRDT sync of task artifacts would be KnowMe's own addition.

### 1.7 Vercel AI SDK UI / generative UI

**Facts:** AI SDK 5/6 centers on the **`UIMessage` + `UIMessageStream`** model: messages contain typed **parts** (text, reasoning, sources, tool calls/results, data parts); `streamText()` → `toUIMessageStream()` / `createUIMessageStreamResponse()`; client consumes via `useChat` / `useCompletion` (`@ai-sdk/react`) or `readUIMessageStream()` for non-React consumers. Generative UI two ways: (1) typed tool parts rendered client-side (`InferUITools<typeof tools>` derives UI-facing types — strong TS end-to-end), (2) **`streamUI` from `@ai-sdk/rsc`** streaming actual React Server Components from server actions — still flagged **experimental** by Vercel; production recommendation is AI SDK UI (useChat). Vercel also integrated with Google's A2UI via `json-renderer`, and ships AI Elements (prebuilt gen-ui component library). [Sources: https://www.aihero.dev/workshops/ai-sdk-v6-crash-course/ui-message-streams~yhlcn (2025-09-09); https://insurge.io/blog/generative-ui-chatbot-ai-elements-vercel-ai-sdk-openrouter (2026-07-06); generativeui.ru AI SDK guide (2026-02-28); https://writerdock.in/blog/building-generative-ui-how-to-stream-components-with-vercel-ai-sdk-and-next-js (2026-01-02)]

**Implications:** For the **Tauri + React 19 desktop surface**, AI SDK UI's typed-parts model is the pragmatic baseline — but it is a library, not a protocol: it doesn't solve cross-language wire interop (Flutter can't consume a UIMessageStream natively). Recommended posture: treat AI SDK message parts as the React-side rendering input, fed by the same AG-UI/A2UI stream the Flutter side consumes; don't make UIMessageStream the canonical wire format across the fabric.

### 1.8 HTMX / hypermedia as server-driven agent UI

**Facts:**

- HTMX 2.x gives AJAX/WS/SSE via HTML attributes; **htmx v4 in beta, target release Summer 2026** (`four.htmx.org`). [Source: https://htmx.org (accessed 2026-07-18)]
- The authoritative agentic-hypermedia pattern is the htmx.org essay **"Hypermedia Friendly Model Context Protocol App Architecture" (2026-03-18)**: an MCP App whose iframe UI uses **Fixi** (Carson Gross's minimal hypermedia library) with a custom `fx:config` that routes `fx-action="tool:*"` through `app.callServerTool` instead of HTTP; server returns rendered **HTML fragments** in `structuredContent`; LLM never sees fragment tools (`ui.visibility: ["app"]`). Key quote for the spec: *"The less state and logic you pack into the client, the less surface area you have for things to go wrong across that boundary."* [Source: https://htmx.org/essays/mcp-apps-hypermedia/ (2026-03-18)]
- Robust SSE pattern for hypermedia apps: **event-as-invalidation** — SSE carries only what-changed signals; HTMX re-fetches the HTML fragment (`hx-trigger="sse:order.updated"` → `hx-get` fragment → swap). Keeps the server authoritative for rendering. [Source: cursa.app HTMX+Alpine course chapter (accessed 2026-07-18)]
- Hypermedia is natively agent-legible: agents can read HTML, follow links, submit forms — they cannot execute React components. [Source: freetheweb manifesto, https://github.com/stukennedy/freetheweb (2026-02-08)]

**Implications:** HTMX/Fixi fragments are the third UI-module type in the master goal. For KnowMe: server-driven fragments fit **flint-forge-hosted surfaces** (settings panels, admin UIs, extension config forms) where rendering authority should stay server-side and the iframe/App-Bridge boundary is acceptable. Event-as-invalidation over SSE maps cleanly onto postgres CDC events from flint-realtime-fabric (CDC event → fragment refresh trigger). HTMX is not the right choice for the high-frequency generative chat surface (that's A2UI/ContentBlock territory).

### 1.9 The owner's `gen_ui` category — positioning

From local docs (`docs/gen_ui_spec.html`, TJ-SPEC-GENUI-001 v1.0.0, Mar 2026): "The ContentBlock sealed union is not just a data type — it is the protocol between the agent runtime and the UI. Semantic annotation happens once, at the stream boundary." Rust parses Anthropic SSE → `A2uiEvent` (27 variants) / `AguiEvent` (12 variants) → ContentBlock mutations (11 block types: Text, Thinking, Code, ToolUse, ToolResult, Skill, Artifact, Memory, Citation, Image, Divider) → exhaustive Dart rendering. New block types follow the mandatory 7-step process in `references/rust/new-block-type.md`.

**Verdict:** the owner's design is a **typed, single-vendor-stream precursor of the AG-UI + A2UI pair**. The 2026 landscape validates the architecture while commoditizing the vocabulary. The architecture doc should map: ContentBlock ↔ A2UI catalog (external format), internal `A2uiEvent`/`AguiEvent` hierarchies ↔ AG-UI's ~16 standard events (rename/align to avoid collision with Google's A2UI trademark namespace — note the owner's "A2UI" predates public A2UI but the namespace is now occupied), SkillBlock ↔ SKILL.md skills (§2), MemoryBlock ↔ synced memory store in pglite/postgres.

---

## 2. Agent-harness skill systems — SKILL.md convention + WASM native skills

### 2.1 What exists (facts + dates)

- **Anthropic launched Agent Skills 2025-10-16** (engineering post "Equipping agents for the real world with Agent Skills"); **published as an open standard at agentskills.io on 2025-12-18**, spec repo `github.com/agentskills/agentskills`. [Sources: https://agentman.ai/blog/agent-skills-ecosystem-report-2026 (2026-06-25); corpus-skills sources.md citing agentskills.io/specification and anthropic.com/engineering (accessed 2026-07-18)]
- **Format**: a folder containing `SKILL.md` — YAML frontmatter (`name`, `description` required; `description` capped at 1024 chars; name: lowercase-hyphen, ≤64 chars) + Markdown body (Anthropic best-practice: ≤500 lines / ~5k tokens), plus optional bundled `scripts/`, `references/`, `assets/`. [Sources: https://geodocs.dev/ai-agents/agent-skill-manifest-specification (2026-04-28); agentskills.io/skill-creation/optimizing-descriptions]
- **Progressive disclosure (3 tiers)**: name+description load at startup (~30–100 tokens/skill; ~1,500 tokens for 40 skills) → full SKILL.md body on activation → reference files on demand. Independent estimate: ~40% token savings vs single-prompt equivalent. [Sources: agentman.ai SKILL.md anatomy (2026-06-09); thevccorner.com playbook (2026-05-18)]
- **Adoption speed**: OpenAI added skills to ChatGPT (found `/home/oai/skills` in the code-interpreter env) and Codex CLI (`--enable skills`, `~/.codex/skills`) in Dec 2025 (documented by Simon Willison); Cursor + Vercel's **skills.sh** marketplace Jan 2026 (34,000+ skills at launch); Microsoft (VS 2026, Copilot Cowork, .NET AI Skills Executor Feb 2026); Spring AI skills module Jan 2026; Gemini CLI, Windsurf, Cognition, Factory, Goose, Cline, Lovable through H1 2026; ~40 compatible products on the agentskills.io showcase by Jun 2026. `anthropics/skills` repo passed 117k GitHub stars. [Sources: inference.sh skills overview (2026-07-10); thevccorner.com (2026-05-18); zylos.ai research (2026-04-08)]
- **Discovery/install**: `npx skills add <owner/repo>` (skills.sh, Vercel) installs across Claude Code/Cursor/Copilot/Goose/Codex/Windsurf/Gemini CLI/etc.; publisher-side convention: expose skills at stable URLs (commonly `/.well-known/skills/<name>/SKILL.md`) and list in `llms.txt`; SemVer `version` frontmatter; versioned immutable URLs (`/skills/<name>/<version>/SKILL.md`). [Sources: inference.sh (2026-07-10); geodocs.dev manifest spec (2026-04-28)]
- **Security reality check**: a 2026 audit found prompt injection in **36% of tested public skills**; SkillsBench found average public skill quality 6.2/12, with only top-quartile skills improving agent performance; curated skills raise pass rates +16.2 points. Skills can execute bundled scripts — treat like untrusted dependencies. [Source: agentman.ai ecosystem report (2026-06-25)]

### 2.2 How packaging/discovery/install works (mechanics)

A harness scans skill directories (conventions: `~/.agents/skills/`, `~/.claude/skills/`, `~/.codex/skills/`, project `.agents/skills/` / `.claude/skills/` — mirrored in this very repo's AGENTS.md), parses frontmatter, injects name+description into the system prompt, and on match loads the body (and later referenced files/scripts). Platform extensions are additive and namespaced (e.g. Claude's `context: fork`, Codex's `openai.yaml`); a spec-conformant skill MUST run on any standard platform. Plugins/bundles: skills increasingly ship inside plugin bundles (harness-specific plugin manifests + skills + MCP servers + hooks).

### 2.3 WASM components as "native skills" for agent harnesses

**What exists:**

- **WebAssembly Component Model + WIT** is the 2026-standard for sandboxed, polyglot plugins: Rust (`cargo component`, `wasm32-wasip1`/`wasip2` targets), TinyGo, Python (`componentize-py`), JS/TS (`jco`). Wasmtime is the reference runtime. [Source: devstarsj.github.io WebAssembly 2026 guide (2026-02-02)]
- **Extism** — the plugin framework purpose-built for "call WASM from any host language" (Host SDKs for Rust/Go/Python/JS/etc., PDKs for guests); positioned exactly at the untrusted-plugin use case. **wasmCloud** (CNCF) — distributed component platform with capability-based security, hosts on anything from laptops to K8s; Q2 2026 roadmap explicitly lists "AI/agentic workload patterns", WASI P3 support, secrets plugins, supply-chain/SBOM integration. **Spin** (Fermyon) — HTTP-triggered component functions. [Sources: srvrlss.io wasmCloud review (accessed 2026-07-18); github.com/wasmCloud/wasmCloud discussion #5026 (2026-04-03)]
- Precedent pattern inside the skills world itself: SKILL.md folders already bundle **executable scripts** (Python/bash) that the harness runs unsandboxed or in a harness-specific sandbox (Claude's code-execution VM). A WASM component is the strict upgrade: same "skill ships code" idea, but with a **capability sandbox, typed WIT interface, and deterministic resource limits**.

**How a WASM native skill would work for KnowMe:** the extension package = `SKILL.md` (procedural knowledge, progressive disclosure) + `component.wasm` (WIT-typed native capability: tools, transformers, encoders) + `catalog.json` (A2UI catalog fragment, §1.3) + `settings.schema.json` (§4). Host = `gen_ui_core` embedding wasmtime (and/or Extism's Rust SDK); capabilities (fs/net/kv) granted per-extension from the manifest; the same component runs in flint-forge server-side (flint-forge already has a WIT component model + extension registry with IPFS/OCI/S3 stores + signing — direct synergy).

**Implications:** This gives the master goal its four-way unification: **SKILL.md = how to think, WIT component = how to act natively, A2UI catalog = how to show, settings schema = how to configure** — one signed package, distributed via flint-forge's IPFS/OCI registry, installed into both client harnesses (Flutter/Tauri via Rust) and server harnesses.

**Gaps/risks:** WASI P3/async still landing (wasmCloud Q2 2026 roadmap); wasm↔host chatty interfaces cost serialization — design WIT interfaces coarse-grained; skill-supply-chain attacks are the #1 ecosystem problem (36% injection stat) → signing + capability manifests are non-negotiable (flint-forge already has signing).

---

## 3. Client-side agents vs cloud-hosted agents — hybrid orchestration

### 3.1 In-browser / in-app inference (what exists)

- **WebLLM (MLC AI)** — Apache 2.0, OpenAI-compatible API in-page, WebGPU-accelerated (Llama 3.2, Phi-3.5, Mistral 7B, Gemma); ~70–80% of native speed; as of mid-2026 WebGPU ships by default in Chrome/Edge 113+, Firefox 141+/145+, Safari macOS Tahoe/iOS 26 — but feature-detection + fallback remains mandatory. [Source: localaimaster.com, "Run an LLM in Your Browser (2026)", 2026-06-21]
- **Transformers.js** (Hugging Face, ONNX Runtime Web) — broad model zoo, WebGPU via ORT; its WebGL path is the consistent **Firefox fallback** (Firefox WebGPU compute dispatch measured ~30× slower). [Source: deciphertech.io browser-inference benchmarks (2026-06-29)]
- **LlamaWeb** (2026 production-grade llama.cpp WebGPU backend) — single HTML + GGUF on a CDN, static memory arena, streaming weight loading; 15–40 tok/s desktop, ~4–17 tok/s mobile; guidance: browser inference for ≤3B single-user workloads, route everything bigger or batched to server GPUs. [Source: deciphertech.io (2026-06-29); arXiv 2605.20706 "Llamas on the Web"]
- **wllama** — llama.cpp compiled to WASM (in-page GGUF). **llama.cpp** itself: GGUF single-file format, Q2_K–Q8_0 + IQ quants, speculative decoding, OpenAI-compatible `llama-server`; the de facto local engine (~120k stars). [Sources: everylocalai.com llama.cpp guide (2026-07-16); arXiv 2605.20706]
- **Mobile/on-device**: **ExecuTorch** (Meta) hit 1.0 GA Oct 2025 (v1.1.0 Jan 2026) — 50 KB runtime, CoreML/QNN/XNNPACK backends, .pte export, LoRA + 4-bit HQQ; powers Instagram/WhatsApp/Quest/Ray-Ban on-device AI. **MNN-LLM** (Alibaba) — fastest measured mobile inference (8.6× prefill vs llama.cpp CPU on Xiaomi 14), DRAM-Flash KV-cache spilling for long context. **MLC LLM** — GPU-first mobile, but weak non-Apple GPU utilization (5–20% ALU on Mali/Adreno). [Source: docs.octomil.com, "On-Device LLM Inference: The Definitive 2025-2026 Guide", 2026-02-18]

### 3.2 Hybrid orchestration patterns (local + cloud agents sharing state)

- **Two-stage router** (Microsoft's reference pattern, May 2026): a small local model (phi-4-mini via Foundry Local) classifies every request first; simple/sensitive → local task model; complex → cloud (Responses API / model-router). Hard-won rules: **deterministic privacy gates beat probabilistic ones** (code the rules; let the LLM judge only the remainder); **fallback must respect privacy class** (a RESTRICTED prompt that fails locally must never fall back to cloud — fail closed); same response schema from every path with honest fallback labels; correlation IDs everywhere; non-reasoning model for the router; cache the local model at process start. [Source: Microsoft Tech Community, "Hybrid AI Agents in Python: Routing Between Foundry Local and Microsoft Foundry", 2026-05-27]
- **Three-pillar routing** (LiteLLM gateway pattern): sensitivity → complexity → availability, implemented with LangChain `RunnableBranch` + LiteLLM fallback chains/failure budgets; GPU saturation overflows to cloud, cloud outage falls back local, **sensitive requests never fall back to cloud**. [Source: SitePoint, "Hybrid Cloud-Local LLM: The Complete Architecture Guide (2026)", 2026-04-22]
- **Compliance-driven routing**: privacy-by-isolation (PII/health/finance data never leaves device), DPA + training-opt-out review for cloud tiers, shared guardrail layer upstream of the router to avoid double cost. [Source: unimon.co.th hybrid design guide (2026-04-30)]
- **Shared state across local/cloud agents**: there is no off-the-shelf standard; the composable pieces are (i) AG-UI `STATE_DELTA` bi-directional state sync agent↔app, (ii) A2A task delegation with artifact streaming, (iii) the sync engine itself (CRDT over flint-realtime-fabric) as the memory/state substrate both agents read/write. The KnowMe-specific pattern to specify: **one synced conversation/state document (CRDT), two writers** — local agent writes cheap/fast/private turns, cloud agent writes heavyweight turns; routing metadata (path, model, privacy class, correlation ID) stored as first-class fields on each turn so the UI can render provenance per ContentBlock.

**Implications:** gen_ui_core's `inference/` layer (candle GGUF on-device) + `api_http.rs` (Anthropic client) already is the two-tier engine; what's missing per these patterns is the **router module** (deterministic privacy gate → complexity heuristic → availability circuit breaker) and **per-turn provenance** in the protocol layer. On web/pglite surfaces, WebLLM/LlamaWeb-class ≤3B models are the local tier; on mobile, GGUF via the existing Rust candle/llama path (ExecuTorch is the alternative if NPU offload becomes a requirement).

**Gaps/risks:** browser inference is single-user ≤3B only; Firefox WebGPU immature; local model cold-start 30–60s (cache at startup); routing quality depends on the classifier — test routing decisions, not just model outputs.

---

## 4. Settings model patterns — extension-exposed schema + synced client/server storage

### 4.1 Concrete precedents (facts)

- **VS Code configuration contribution point** — the canonical "extension exposes JSON settings schema, container provides storage + sync" system: extensions declare `contributes.configuration` in `package.json` with full **JSON Schema** per property (type, default, enum, markdownDescription, deprecation); **scopes** `application`/`machine`/`machine-overridable`/`window`/`resource`/`language-overridable` control where a setting may be overridden; **`ignoreSync: true`** excludes a setting from Settings Sync (machine-scoped settings never sync). Storage tiers for extension data: `workspaceState` (per-workspace KV), `globalState` (global KV) with **`setKeysForSync`** to opt specific keys into cross-machine Settings Sync, `storageUri`/`globalStorageUri` for files, and **`secrets`** (encrypted, never synced; Electron safeStorage on desktop, DKE on web). Reads via `workspace.getConfiguration`; change events via `onDidChangeConfiguration`. [Sources: https://code.visualstudio.com/api/references/contribution-points (2026-06-01); https://code.visualstudio.com/api/extension-capabilities/common-capabilities (2026-06-01)]
- **Chrome/Firefox extension storage** — `chrome.storage.sync` (account-synced KV, per-item ~8 KB / total ~100 KB quotas), `chrome.storage.local`, `chrome.storage.managed` (admin policy — schema-declared via `storage.managed_schema` manifest pointing at a JSON Schema file); Firefox mirrors with `browser.storage.sync`. Caveat: extension settings sync **only if the developer opts into the sync storage API** and the user enables the sync category — sync is an explicit design decision, not a default. [Source: alibaba.com product insights, "Chrome Vs Firefox Sync: Which Saves Extension Settings?" (2026-02-21)]
- **MCP elicitation** — MCP servers can request structured input from the user mid-tool-call with a JSON Schema; the host owns rendering + consent. Adjacent precedent: schema provided by extension, storage/consent owned by container. [Source: modelcontextprotocol spec, elicitation (referenced via atamel.dev protocols overview, 2026-03-17)]
- **A2UI `updateDataModel`** — a generative-UI surface's data model is JSON-Pointer-addressed state that both agent and client mutate; demonstrates the "settings as a shared, path-addressed document" pattern at per-surface granularity (§1.3).
- **VS Code Settings Sync service** (built-in, Microsoft/GitHub account) vs **Settings Sync extension** (Shan Khan, GitHub Gist-backed JSON, 2M+ installs) vs git-backed community extensions — shows both hosted-service and user-owned-git approaches to the same sync problem. [Sources: freecodecamp.org settings sync guide; github.com/YoraiLevi/sync-settings-with-github (2024-12-29)]

### 4.2 The distilled pattern

1. **Schema in the package manifest** (JSON Schema; VS Code's `contributes.configuration` is the mature model; Chrome's `managed_schema` adds admin-override).
2. **Scope/ownership annotations per key** (user vs machine vs workspace; sync opt-in/opt-out per key: `ignoreSync`, `setKeysForSync`).
3. **Secrets are a separate storage class** (encrypted, never synced).
4. **Container provides storage + change events + sync transport**; the extension never implements its own sync.
5. **Server-side mirror** for admin/policy defaults (Chrome managed storage; flint-forge postgres can hold org defaults + audit).

**Implications for KnowMe:** the WASM/extension package (§2.3) ships `settings.schema.json`; `gen_ui_core` exposes a `settings` WIT interface to components; values live in pglite (web) / pglite-oxide (Tauri) as a synced table keyed by `(extension_id, scope, key)` with per-key sync flags; flint-realtime-fabric CRDT-syncs them to flint-forge postgres, which additionally serves org-managed defaults (Chrome-managed precedent). JSON Schema doubles as (a) the settings-UI generator input (JSON Forms-style rendering — or an A2UI catalog mapping schema→widgets), and (b) the validation gate for both client and server writes. VS Code's scope enum is the direct model for "client-local vs user-synced vs org-managed".

**Gaps/risks:** CRDT merge of settings needs last-writer-wins per key + schema-version migrations (VS Code punts on this — flat KV; KnowMe must version schemas); secrets must bypass sync entirely (separate storage class, encrypted at rest); schema-driven UI generation must respect the Flat 2.0 design constraints in this repo.

---

## 5. Synthesis for the master goal (recommendations to the spec author)

1. **Adopt the 2026 protocol vocabulary explicitly**: AG-UI (event stream) + A2UI (declarative surfaces) + MCP/MCP Apps (tools + iframe modules) + A2A (local↔cloud delegation). Keep ContentBlock as the internal canonical Rust type; make A2UI JSONL the external serialization; align/alias the internal `A2uiEvent`/`AguiEvent` naming to avoid collision with Google's now-standard A2UI.
2. **Extension package = SKILL.md + component.wasm (WIT) + A2UI catalog fragment + settings.schema.json**, signed and distributed via flint-forge's IPFS/OCI/S3 registry. This is the master goal's "native skills + UI modules + settings schemas" as one artifact.
3. **Two-tier agents with a deterministic router** in gen_ui_core: privacy gate (fail-closed) → complexity → availability; per-turn provenance fields; shared state = CRDT-synced documents over flint-realtime-fabric (AG-UI `STATE_DELTA` semantics on top of CRDT).
4. **Settings**: VS Code's `contributes.configuration` model (JSON Schema + scopes + per-key sync flags) over a synced `(extension_id, scope, key)` table; secrets as a separate never-synced class; org-managed defaults server-side (Chrome managed storage precedent).
5. **HTMX/Fixi fragments** for server-driven extension/admin UIs via MCP Apps pattern; event-as-invalidation fed by postgres CDC.
6. **Security posture**: skill supply chain is compromised in the wild (36% injection rate in 2026 audit) — signing + capability manifests + curated registry are launch requirements, not enhancements.

## 6. Key links (with dates)

- AG-UI docs — https://docs.ag-ui.com/introduction (accessed 2026-07-16/18)
- AG-UI repo — https://github.com/ag-ui-protocol/ag-ui (accessed 2026-07-18)
- AG-UI announcement — https://webflow.copilotkit.ai/blog/introducing-ag-ui-the-protocol-where-agents-meet-users (2025-05-12)
- Oracle: Agent Spec + AG-UI + A2UI alignment — https://blogs.oracle.com/ai-and-datascience/announcing-agent-spec-for-a2ui-copilotkit-ag-ui (2026-03-12)
- A2UI v0.9 (CopilotKit design-partner post) — https://www.copilotkit.ai/blog/a2ui-whats-new-in-google-generative-ui-spec (2026-04-17)
- A2UI open-source release — https://hia2ui.com/blog/a2ui-official-public-release/ (2026-01-04); spec site https://a2ui.org
- A2UI message types walkthrough — https://atamel.dev/posts/2026/03-30_a2ui_with_adk/ (2026-03-30)
- Protocols overview (MCP/A2A/AG-UI/A2UI) — https://atamel.dev/posts/2026/03-17_agent_protocols_mcp_a2a_a2ui_agui/ (2026-03-17)
- GenUI SDK for Flutter — https://docs.flutter.dev/ai/genui (2026-05-27); https://verygood.ventures/blog/getting-started-with-genui/ (2026-04-16); https://stackademic.com/blog/generative-ui-in-flutter-genui-and-the-a2ui-protocol (2026-06-26)
- MCP-UI — https://github.com/MCP-UI-Org/mcp-ui (accessed 2026-07-18); https://pypi.org/project/mcp-ui/ (2025-09-11)
- HTMX MCP Apps hypermedia essay — https://htmx.org/essays/mcp-apps-hypermedia/ (2026-03-18); htmx v4 beta — https://htmx.org (Summer 2026 target)
- A2A spec/SDK — https://a2aproject.github.io/A2A/dev/specification/; https://neurals.ca/tech/gemini/a2a-protocol/ (2026-05-27); Linux Foundation donation 2025-06-23
- Vercel AI SDK UI — https://www.aihero.dev/workshops/ai-sdk-v6-crash-course/ui-message-streams~yhlcn (2025-09-09); https://insurge.io/blog/generative-ui-chatbot-ai-elements-vercel-ai-sdk-openrouter (2026-07-06)
- Agent Skills standard — https://agentskills.io/specification (published 2025-12-18); https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills (2025-10-16); ecosystem report https://agentman.ai/blog/agent-skills-ecosystem-report-2026 (2026-06-25); skills.sh (`npx skills add`) Jan 2026; manifest/publishing spec https://geodocs.dev/ai-agents/agent-skill-manifest-specification (2026-04-28)
- WASM component/plugin ecosystems — wasmCloud Q2 2026 roadmap https://github.com/wasmCloud/wasmCloud/discussions/5026 (2026-04-03); Extism https://extism.org; WebAssembly 2026 guide https://devstarsj.github.io/webdev/2026/02/02/WebAssembly-Wasm-2026-Guide/ (2026-02-02)
- In-browser/on-device inference — localaimaster.com (2026-06-21); deciphertech.io benchmarks (2026-06-29); arXiv 2605.20706 "Llamas on the Web"; octomil on-device guide (2026-02-18); everylocalai llama.cpp (2026-07-16)
- Hybrid routing — Microsoft Foundry Local pattern (2026-05-27) https://techcommunity.microsoft.com/blog/educatordeveloperblog/hybrid-ai-agents-in-python-routing-between-foundry-local-and-microsoft-foundry/4522979; SitePoint hybrid guide (2026-04-22) https://www.sitepoint.com/hybrid-cloudlocal-llm-the-complete-architecture-guide-2026/
- Settings precedents — VS Code contribution points https://code.visualstudio.com/api/references/contribution-points (2026-06-01); VS Code data storage https://code.visualstudio.com/api/extension-capabilities/common-capabilities (2026-06-01); Chrome storage.sync analysis (2026-02-21)
- Owner's internal spec — `docs/gen_ui_spec.html` (TJ-SPEC-GENUI-001 v1.0.0, Mar 2026); `references/rust/new-block-type.md`
