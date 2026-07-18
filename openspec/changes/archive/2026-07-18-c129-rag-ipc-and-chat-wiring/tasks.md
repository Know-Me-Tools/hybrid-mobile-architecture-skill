# Tasks — c129-rag-ipc-and-chat-wiring

- [ ] 1.1 rag_retrieve Tauri command (desktop): RagEngine over PgVectorStore (pglite-oxide messages/agent_memory) + FastEmbedder, typed request/response
- [ ] 1.2 rag_retrieve gen_ui_ffi fn (mobile): RagEngine over GraphVectorStore/GraphRagEmbedder (the memory table, c128's adapter)
- [ ] 1.3 Desktop chat wiring: chatStore gains retrieveContext() (the only invoke() point), a hook composes it, composer surfaces recalled chunks with provenance
- [x] 1.4 Behavior tests + tsc/clippy clean; spec delta; validate
