# Tasks — 2026-07-15-c108-mcp-skill-and-agent

> **Scoped at execute time (user-ratified): the MCP tool round-trip only.** The proposal
> bundles two features — (a) MCP tools surfacing toolUse/toolResult blocks in chat, and
> (b) a "Hands" agent with live step-streaming through a PMPO loop. (b) needs a PMPO loop
> built from scratch (`gen_ui_agent` has chat/memory/tools, no agent module) and is a
> change of its own. (a) is complete and verifiable on its own; that is what landed.

## Done

- [x] T1 — **MCP ↔ LLM tool bridge** (`gen_ui_agent::tools`). Two translations:
      MCP `tools/list` inventory → liter-llm `ChatCompletionTool` definitions, and an
      LLM tool call → an MCP `tools/call`.
      **Naming is the load-bearing detail.** MCP tool names are unique only *within* a
      server, but the model sees one flat list — so names are qualified `server__tool`
      and split back on the way in. `__` specifically: OpenAI-compatible providers
      constrain function names to `[A-Za-z0-9_-]`, so `/` or `.` would be silently
      mangled by the provider rather than failing loudly here. Unqualify splits on the
      FIRST separator (server names are ours; tool names come from the server and may
      themselves contain `__`).
      MCP's `inputSchema` IS a JSON Schema, which is exactly what `parameters` wants —
      no translation, just a move.
- [x] T2 — **Registry in `AgentState`** (`state::mcp()`). Not an `Option`: "no registry"
      and "no servers" are the same thing to every caller. Empty is the normal state.
- [x] T3 — **Tools attached to the chat request.** Empty registry → `tools: None`, not
      `Some([])` — some providers reject an empty array, and "no tools configured" should
      send the byte-identical request shape that existed before tools did.
      Definitions come from each server's *cached* inventory rather than re-listing:
      `refresh_tools` is a network round-trip, and doing one per server on every turn
      would put MCP latency on the critical path of requests that call no tool.
- [x] T4 — **`A2uiAdapter` emits `ToolUse` blocks.** It previously dropped all three
      tool `StreamEvent`s on a `_ => vec![]` arm, so tool calls went nowhere.
      **Tool arguments arrive as a stream of fragments** — the model emits `{"pa`,
      `th":"/t`, `mp"}` across chunks, each individually invalid JSON. The adapter
      accumulates per call id and emits exactly ONE block at completion. Four tests
      cover it: fragment reassembly, two concurrent calls not sharing a buffer, orphan
      deltas dropped rather than guessed into a call whose name is unknown, and the text
      path still working.
- [x] T5 — **`run_stream` translates the wire shape.** liter-llm's `StreamToolCall`
      carries the id + name only in a call's opening chunk; argument fragments carry only
      the stream index. `run_stream` records index → id so the fragments can be routed.
      A `finish_reason` closes every open call before the run ends — otherwise the
      transcript shows a turn that called nothing.

Verified: `cargo clippy --workspace --all-targets -D warnings` clean; 3 `tools` unit
tests + 4 adapter tests pass.

## Not done — stated plainly

- [ ] **The follow-up turn.** The model's tool call is executed and rendered, but its
      result is not yet fed back for a second completion — so the model cannot *use* what
      a tool returned. `tools::call_tool` exists and is tested at the naming boundary;
      the multi-turn loop in `run_stream` is the missing piece. This is the difference
      between "tools are wired" and "tools are useful", and it is not claimed.
- [ ] **`ToolResult` blocks.** Follows directly from the above — there is no result to
      render until the call is executed in the loop.
- [ ] **No MCP server is registered by default.** The registry is empty on every install,
      so no tool definitions are sent and chat behaves exactly as before. Registering
      flint-forge's `/mcp/v1/a2ui` needs a live endpoint (a private cross-org service),
      which is the same reason C-106's sync is opt-in and absent-by-default.
- [ ] **Not exercised against a real MCP server.** Every layer is unit-tested and the
      fragment reassembly is proven, but no actual `tools/list` → `tools/call` round-trip
      has run. Given this session's history — three changes marked "verified" that were
      broken in production — that distinction stays explicit.
- [ ] **The Hands agent + PMPO loop** (the proposal's other half). Needs an agent module
      that does not exist. Its own change.
