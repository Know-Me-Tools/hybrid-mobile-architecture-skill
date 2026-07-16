// TJ-ARCH-MOB-001 compliant
//! Chat turn orchestration (T6/T7): resolve provider/model from the config DB,
//! build a liter-llm client, stream `ChatCompletionChunk`s, translate them into
//! `StreamEvent` -> `A2uiEvent` via gen_ui_protocol, and publish onto the run
//! registry so gen_ui_ffi (frb StreamSink) and tauri-plugin-gen-ui (Tauri emit)
//! can forward the same stream to their respective UIs without duplicating any
//! business logic (constraint: logic lives once, in Rust core).

use std::sync::Arc;

use futures::StreamExt;
use gen_ui_db::relational::ConfigStore;
use gen_ui_protocol::A2uiAdapter;
use gen_ui_types::events::{A2uiEvent, StreamEvent};
use gen_ui_types::{CoreError, CoreResult};
use liter_llm::types::{ChatCompletionRequest, Message, UserMessage};
use liter_llm::{ClientBuilder, LlmClient};
use uuid::Uuid;

use crate::config_resolve::resolve_chat_model;
use crate::error::from_liter_llm;
use crate::registry::RunRegistry;
use crate::secret::SecretResolver;

/// Shared chat orchestration entry point. Both gen_ui_ffi::api::chat::chat_send
/// (mobile) and tauri-plugin-gen-ui::commands::chat_send (desktop) call this —
/// neither reimplements the liter-llm call or the StreamEvent translation.
///
/// # Design decisions (documented per the task's request to flag ambiguity)
///
/// * **Storage backend**: this takes `Arc<dyn ConfigStore>`
///   (`gen_ui_db::relational::ConfigStore`), which is the desktop/web backend.
///   Mobile's config lives in `gen_ui_db_graph::GraphStore` instead (inherent
///   methods, not a trait impl of `ConfigStore` — confirmed by inspection, no
///   shared trait exists between the two backends today). Unifying them behind
///   one trait object is out of scope for T6/T7 (gen_ui_agent's Cargo.toml was
///   not given a gen_ui_db_graph dependency for this task) — mobile callers of
///   `ChatAgent` currently need a `ConfigStore` adapter over `GraphStore` as
///   follow-up work; until that lands, gen_ui_ffi should construct
///   `ChatAgent` with a store that graceful-degrades (see `NoopConfigStore`
///   pattern implied by `resolve_chat_model`'s "no provider configured" path)
///   rather than blocking on the adapter.
/// * **run_id generation**: `chat_send` mints the run_id (UUID v4) rather than
///   accepting one from the caller — callers only need the returned id to
///   subscribe via `chat_events`/the Tauri stream bridge.
pub struct ChatAgent {
    config_store: Arc<dyn ConfigStore>,
    secret_resolver: Arc<dyn SecretResolver>,
    registry: RunRegistry,
}

impl ChatAgent {
    pub fn new(
        config_store: Arc<dyn ConfigStore>,
        secret_resolver: Arc<dyn SecretResolver>,
        registry: RunRegistry,
    ) -> Self {
        Self { config_store, secret_resolver, registry }
    }

    /// Access the run registry so `chat_events` (frb) / the Tauri stream bridge
    /// can subscribe to a run started by `send`.
    pub fn registry(&self) -> &RunRegistry {
        &self.registry
    }

    /// Start a chat turn. Resolves provider/model, registers the run, and
    /// spawns the streaming producer task on the shared Tokio runtime (never a
    /// second runtime — see gen_ui_runtime::spawn). Returns the run_id
    /// immediately; the caller subscribes to `registry()` for the event stream.
    ///
    /// Graceful degrade: if no provider is enabled/configured, or the secret
    /// can't be resolved, returns `Err` synchronously (before spawning) rather
    /// than starting a run that immediately errors — the caller never receives
    /// a run_id for a turn that cannot proceed. No hardcoded API keys or env
    /// vars are ever used as a fallback.
    pub async fn send(&self, thread_id: String, message: String) -> CoreResult<String> {
        let resolved = resolve_chat_model(self.config_store.as_ref()).await?;

        let api_key_ref = resolved.provider.api_key_ref.clone().ok_or_else(|| {
            CoreError::Terminal(format!(
                "no provider configured: provider '{}' has no api_key_ref set",
                resolved.provider.id
            ))
        })?;
        let api_key = self.secret_resolver.resolve(&api_key_ref).await?;

        let client = ClientBuilder::new()
            .api_key(api_key)
            .provider(resolved.provider.kind.clone())
            .build()
            .map_err(from_liter_llm)?;

        let run_id = Uuid::new_v4().to_string();
        let tx = self.registry.register(&run_id);
        let registry = self.registry.clone();

        let request = ChatCompletionRequest {
            model: resolved.model_pref.model_id.clone(),
            messages: vec![Message::User(UserMessage { content: message.into(), name: None })],
            ..Default::default()
        };

        let run_id_for_task = run_id.clone();
        let thread_id_for_task = thread_id;
        gen_ui_runtime::spawn(async move {
            drive_stream(client, request, run_id_for_task, thread_id_for_task, tx, registry).await;
        });

        Ok(run_id)
    }
}

/// Drive one liter-llm streaming call to completion, translating each chunk
/// into `StreamEvent`s and publishing the resulting `A2uiEvent`s onto the run's
/// broadcast channel. Runs entirely inside the spawned task — errors here
/// become `A2uiEvent::RunError` on the stream rather than propagating to the
/// caller of `send`, which already returned its run_id.
async fn drive_stream(
    client: impl LlmClient,
    request: ChatCompletionRequest,
    run_id: String,
    thread_id: String,
    tx: tokio::sync::broadcast::Sender<A2uiEvent>,
    registry: RunRegistry,
) {
    let _ = &thread_id; // thread_id is not yet part of the A2UI event surface (RunStarted only carries run_id).
    let mut adapter = A2uiAdapter::new(run_id.clone());

    // MessageStart opens the run on the UI side before any content arrives.
    publish_all(&tx, adapter.ingest(&StreamEvent::MessageStart));

    let stream_result = client.chat_stream(request).await;
    let mut stream = match stream_result {
        Ok(stream) => stream,
        Err(err) => {
            let message = from_liter_llm(err).to_string();
            publish_all(&tx, adapter.ingest(&StreamEvent::Error { message }));
            registry.remove(&run_id);
            return;
        }
    };

    while let Some(item) = stream.next().await {
        match item {
            Ok(chunk) => {
                for event in stream_events_from_chunk(&chunk) {
                    publish_all(&tx, adapter.ingest(&event));
                }
            }
            Err(err) => {
                let message = from_liter_llm(err).to_string();
                publish_all(&tx, adapter.ingest(&StreamEvent::Error { message }));
                registry.remove(&run_id);
                return;
            }
        }
    }

    publish_all(&tx, adapter.ingest(&StreamEvent::Done));
    registry.remove(&run_id);
}

/// Translate one `ChatCompletionChunk` into zero or more `StreamEvent`s.
/// A chunk carries one delta per choice; this workspace's ContentBlock/A2UI
/// contract is single-choice (index 0) for the chat surface, matching
/// `gen_ui_protocol::A2uiAdapter`'s current text-only path.
fn stream_events_from_chunk(chunk: &liter_llm::types::ChatCompletionChunk) -> Vec<StreamEvent> {
    let mut events = Vec::new();
    for choice in &chunk.choices {
        if let Some(content) = &choice.delta.content {
            if !content.is_empty() {
                events.push(StreamEvent::TextDelta { index: choice.index, delta: content.clone() });
            }
        }
    }
    events
}

fn publish_all(tx: &tokio::sync::broadcast::Sender<A2uiEvent>, events: Vec<A2uiEvent>) {
    for event in events {
        // A `send` error only means there are currently no subscribers (e.g.
        // the run started before chat_events/the Tauri bridge attached, or the
        // UI already navigated away) — not a failure of the run itself, so it
        // is intentionally ignored rather than surfaced as an error.
        let _ = tx.send(event);
    }
}
