// TJ-ARCH-MOB-001 compliant
//! T10 live smoke test: proves ChatAgent::send drives a real liter-llm chat
//! completion against a local Ollama instance end-to-end (chat_send's
//! provider resolution -> liter-llm ClientBuilder -> streamed A2uiEvents),
//! the same code path both gen_ui_ffi (mobile) and tauri-plugin-gen-ui
//! (desktop) call. Ignored by default — requires Ollama running locally with
//! `OLLAMA_MODEL` (or the deepseek-v4-flash:cloud default) pulled.
//!
//! Run with: OLLAMA_MODEL=deepseek-v4-flash:cloud cargo test -p gen_ui_agent
//! --test ollama_live -- --ignored --nocapture

use std::sync::Arc;

use async_trait::async_trait;
use gen_ui_agent::{ChatAgent, RunRegistry, SecretResolver};
use gen_ui_db::relational::{ConfigStore, ModelPref, Provider, RelationalError, RelationalResult};
use gen_ui_types::events::A2uiEvent;
use gen_ui_types::CoreResult;

const PROVIDER_ID: &str = "test-ollama";
const API_KEY_REF: &str = "test-ollama-noop";

struct OllamaConfigStore {
    model_hint: String,
}

#[async_trait]
impl ConfigStore for OllamaConfigStore {
    async fn list_providers(&self) -> RelationalResult<Vec<Provider>> {
        Ok(vec![Provider {
            id: PROVIDER_ID.into(),
            kind: format!("ollama/{}", self.model_hint),
            base_url: std::env::var("OLLAMA_BASE_URL").ok(),
            api_key_ref: Some(API_KEY_REF.into()),
            enabled: true,
        }])
    }
    async fn upsert_provider(&self, _: &Provider) -> RelationalResult<()> {
        Err(RelationalError::Sync("read-only test store".into()))
    }
    async fn delete_provider(&self, _: &str) -> RelationalResult<()> {
        Err(RelationalError::Sync("read-only test store".into()))
    }
    async fn get_model_pref(&self, surface: &str, lane: &str) -> RelationalResult<Option<ModelPref>> {
        if surface != "chat" || lane != "default" {
            return Ok(None);
        }
        Ok(Some(ModelPref {
            surface: surface.into(),
            lane: lane.into(),
            provider_id: Some(PROVIDER_ID.into()),
            model_id: format!("ollama/{}", self.model_hint),
            params: serde_json::Value::Null,
        }))
    }
    async fn upsert_model_pref(&self, _: &ModelPref) -> RelationalResult<()> {
        Err(RelationalError::Sync("read-only test store".into()))
    }
    async fn get_setting(&self, _: &str) -> RelationalResult<Option<serde_json::Value>> {
        Ok(None)
    }
    async fn set_setting(&self, _: &str, _: serde_json::Value) -> RelationalResult<()> {
        Err(RelationalError::Sync("read-only test store".into()))
    }
}

#[derive(Default)]
struct NoopOllamaSecretResolver;

#[async_trait]
impl SecretResolver for NoopOllamaSecretResolver {
    async fn resolve(&self, _api_key_ref: &str) -> CoreResult<String> {
        Ok(String::new())
    }
}

#[tokio::test]
#[ignore]
async fn chat_agent_streams_a_real_ollama_response() {
    gen_ui_runtime::init(None);

    let model_hint = std::env::var("OLLAMA_MODEL").unwrap_or_else(|_| "deepseek-v4-flash:cloud".into());
    let agent = ChatAgent::new(
        Arc::new(OllamaConfigStore { model_hint }),
        Arc::new(NoopOllamaSecretResolver),
        RunRegistry::new(),
    );

    let run_id = agent
        .send("test-thread".into(), "Say hello in exactly one word.".into())
        .await
        .expect("chat_send should succeed against a running Ollama instance");

    let mut rx = agent.registry().subscribe(&run_id).expect("run should still be registered");

    let mut saw_run_started = false;
    let mut saw_text = false;
    let mut saw_terminal = false;
    let mut collected_text = String::new();

    while let Ok(event) = tokio::time::timeout(std::time::Duration::from_secs(30), rx.recv())
        .await
        .expect("timed out waiting for Ollama response")
    {
        match event {
            A2uiEvent::RunStarted { .. } => saw_run_started = true,
            A2uiEvent::Block { block } => {
                if let gen_ui_types::content_block::ContentBlock::Text { text } = block {
                    saw_text = true;
                    collected_text.push_str(&text);
                }
            }
            A2uiEvent::RunFinished { .. } => {
                saw_terminal = true;
                break;
            }
            A2uiEvent::RunError { message } => {
                panic!("chat run errored: {message}");
            }
        }
    }

    assert!(saw_run_started, "expected a RunStarted event");
    assert!(saw_text, "expected at least one text Block event");
    assert!(saw_terminal, "expected a terminal RunFinished event");
    assert!(!collected_text.trim().is_empty(), "collected response text should be non-empty");
    println!("Ollama response: {collected_text:?}");
}
