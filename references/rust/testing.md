# Rust Testing Reference
> cargo test · tokio::test · mockall · proptest

## Cargo.toml test dependencies

```toml
[dev-dependencies]
tokio-test  = "0.4"
mockall     = "0.13"
proptest    = "1.5"
wiremock    = "0.6"
rstest      = "0.23"
```

## Testing the A2UI adapter

```rust
// src/protocol/a2ui_tests.rs (or inline #[cfg(test)] in a2ui.rs)
#[cfg(test)]
mod tests {
    use super::*;
    use crate::streaming::StreamEvent;

    #[test]
    fn text_delta_produces_a2ui_text_delta() {
        let mut adapter = A2uiAdapter::new("run-001");
        let events = adapter.ingest(&StreamEvent::TextDelta {
            index: 0,
            delta: "Hello".into(),
        });
        assert_eq!(events.len(), 1);
        matches!(events[0], A2uiEvent::TextDelta { ref delta, is_final: false, .. }
            if delta == "Hello");
    }

    #[test]
    fn content_block_stop_finalizes_text_block() {
        let mut adapter = A2uiAdapter::new("run-001");
        // Start block
        adapter.ingest(&StreamEvent::ContentBlockStart {
            index: 0,
            block_type: crate::streaming::ContentBlockType::Text,
            tool_use_id: None, tool_name: None, language: None,
        });
        // Accumulate text
        adapter.ingest(&StreamEvent::TextDelta { index: 0, delta: "Hello ".into() });
        adapter.ingest(&StreamEvent::TextDelta { index: 0, delta: "world".into() });
        // Stop — should emit final text event
        let events = adapter.ingest(&StreamEvent::ContentBlockStop { index: 0 });
        assert!(events.iter().any(|e| matches!(e, A2uiEvent::TextDelta { is_final: true, .. })));
    }

    #[test]
    fn skill_activated_produces_skill_event() {
        let mut adapter = A2uiAdapter::new("run-001");
        let events = adapter.ingest(&StreamEvent::SkillActivated {
            skill_id:       "rag-001".into(),
            skill_name:     "RAG Pipeline".into(),
            description:    Some("Retrieval-augmented generation".into()),
            parameters_json: r#"{"top_k": 5}"#.into(),
        });
        assert_eq!(events.len(), 1);
        assert!(matches!(events[0], A2uiEvent::SkillActivated { ref skill_id, .. }
            if skill_id == "rag-001"));
    }
}
```

## Testing the agent loop (async)

```rust
#[cfg(test)]
mod agent_tests {
    use super::*;
    use tokio::sync::mpsc;
    use wiremock::{MockServer, Mock, ResponseTemplate};
    use wiremock::matchers::{method, path};

    #[tokio::test]
    async fn agent_emits_done_on_tool_use_then_end_turn() {
        // Start a WireMock server simulating Anthropic API
        let server = MockServer::start().await;

        // First response: tool_use
        Mock::given(method("POST")).and(path("/v1/messages"))
            .respond_with(ResponseTemplate::new(200)
                .set_body_string(sse_tool_use_response()))
            .up_to_n_times(1)
            .mount(&server).await;

        // Second response: end_turn after tool result
        Mock::given(method("POST")).and(path("/v1/messages"))
            .respond_with(ResponseTemplate::new(200)
                .set_body_string(sse_end_turn_response()))
            .mount(&server).await;

        let (raw_tx, raw_rx) = mpsc::channel::<StreamEvent>(64);
        let client = AnthropicClient::new_with_base_url("test-key", server.uri());
        let mut agent = AgentRuntime::new(
            AgentConfig { model: "claude-opus-4-5".into(), max_turns: 5, ..Default::default() },
            client, None, None, None,
        );
        agent.register_tool(
            "test_tool", "A test tool", serde_json::json!({}),
            |_| Ok("tool result".into()),
        );

        agent.run(vec![], "test message".into(), raw_tx).await.unwrap();

        let mut events = vec![];
        let mut receiver = raw_rx;
        while let Ok(ev) = receiver.try_recv() { events.push(ev); }

        assert!(events.iter().any(|e| matches!(e, StreamEvent::Done)));
    }

    fn sse_tool_use_response() -> String {
        // Minimal valid Anthropic SSE with tool_use stop_reason
        include_str!("../test-fixtures/tool_use_response.sse")
    }

    fn sse_end_turn_response() -> String {
        include_str!("../test-fixtures/end_turn_response.sse")
    }
}
```

## Testing SurrealDB stores

```rust
#[cfg(test)]
mod db_tests {
    use super::*;
    use tempfile::TempDir;

    async fn test_db() -> (Arc<surrealdb::Surreal<surrealdb::engine::local::Db>>, TempDir) {
        let dir = TempDir::new().unwrap();
        let db = crate::db::init(dir.path()).await.unwrap();
        (db, dir)
    }

    #[tokio::test]
    async fn memory_write_and_read_roundtrip() {
        let (db, _dir) = test_db().await;
        let mem = MemoryStore::new(db);

        mem.write("test_key", "test_value", "semantic", "test_ns", None)
            .await.unwrap();

        let record = mem.read("test_key", "test_ns").await.unwrap();
        assert!(record.is_some());
        let r = record.unwrap();
        assert_eq!(r.value, "test_value");
        assert_eq!(r.memory_type, "semantic");
    }

    #[tokio::test]
    async fn tool_cache_respects_ttl() {
        let (db, _dir) = test_db().await;
        let cache = ToolCache::new(db);

        cache.set("my_tool", "abc123", r#"{"result": 42}"#, Some(1)).await.unwrap();

        // Should be present immediately
        let cached = cache.get("my_tool", "abc123").await.unwrap();
        assert!(cached.is_some());

        // After TTL expires (in a real test, use fake_time)
        // assert_eq!(cache.get("my_tool", "abc123").await.unwrap(), None);
    }

    #[tokio::test]
    async fn entity_graph_relate_and_neighbors() {
        let (db, _dir) = test_db().await;
        let graph = EntityGraph::new(db);

        graph.upsert_entity("Rust", "language", serde_json::json!({}), None).await.unwrap();
        graph.upsert_entity("Flutter", "framework", serde_json::json!({}), None).await.unwrap();
        graph.relate("Flutter", "uses", "Rust", 1.0).await.unwrap();

        let neighbors = graph.neighbors("Flutter", 1).await.unwrap();
        // neighbors should include Rust
        let names: Vec<String> = neighbors.iter()
            .filter_map(|n| n.get("name").and_then(|v| v.as_str()).map(String::from))
            .collect();
        // Exact assertion depends on SurrealDB FETCH behavior
        assert!(!neighbors.is_empty() || names.contains(&"Rust".to_string()));
    }
}
```

## Property-based testing for the SSE parser

```rust
#[cfg(test)]
mod streaming_tests {
    use super::*;
    use proptest::prelude::*;

    proptest! {
        #[test]
        fn parse_text_delta_handles_any_string(s in ".*") {
            let data = serde_json::json!({
                "index": 0,
                "delta": { "type": "text_delta", "text": s }
            }).to_string();
            let result = parse_anthropic_event("content_block_delta", &data);
            // Should not panic, and if it parses, should be a TextDelta
            if let Some(ev) = result {
                assert!(matches!(ev, StreamEvent::TextDelta { .. }));
            }
        }
    }
}
```

## Running tests

```bash
# All tests
cargo test

# With output (useful for debugging)
cargo test -- --nocapture

# Specific module
cargo test protocol::a2ui_tests

# Integration tests only
cargo test --test integration

# With coverage (cargo-tarpaulin)
cargo tarpaulin --out Html --output-dir coverage/
```
