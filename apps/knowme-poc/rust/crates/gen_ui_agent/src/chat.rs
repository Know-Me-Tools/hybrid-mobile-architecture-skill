// TJ-ARCH-MOB-001 compliant
//! Shared chat-send implementation. Called identically from gen_ui_ffi (mobile,
//! via frb) and tauri-plugin-gen-ui (desktop, via Tauri IPC) — the only
//! platform-specific code lives in how each leaf forwards A2uiEvents to its own
//! transport (StreamSink vs Tauri emit); this module owns everything else:
//! provider/model selection from the config DB, the liter-llm call, and
//! adapting the response stream into ContentBlocks.
use gen_ui_protocol::A2uiAdapter;
use gen_ui_types::events::StreamEvent;
use liter_llm::client::ClientBuilder;
use liter_llm::types::chat::ChatCompletionRequest;
use liter_llm::types::common::{Message, UserContent, UserMessage};
use liter_llm::LlmClient;

use crate::error::AgentError;
use crate::{secrets, state};

const SURFACE_CHAT: &str = "chat";
const LANE_CLOUD: &str = "cloud";

/// Start a chat turn. Returns the run_id whose events are published on the
/// shared A2uiEvent broadcast (see `state::subscribe`); the actual generation
/// runs on a spawned task so `send` returns as soon as the provider/model are
/// resolved, matching the frb/Tauri contract's fire-and-subscribe shape.
pub async fn send(user_message: String, history: Vec<String>) -> Result<String, AgentError> {
    let run_id = uuid::Uuid::new_v4().to_string();

    let pref = state::config()?
        .get_model_pref(SURFACE_CHAT, LANE_CLOUD)
        .await?
        .ok_or(AgentError::NoProvider)?;
    let provider_id = pref.provider_id.as_deref().ok_or(AgentError::NoProvider)?;
    let provider = state::config()?
        .get_provider(provider_id)
        .await?
        .ok_or_else(|| AgentError::DanglingProvider(provider_id.to_string()))?;
    if !provider.enabled {
        return Err(AgentError::NoProvider);
    }
    let api_key = match &provider.api_key_ref {
        Some(key_ref) => secrets::resolve_api_key(key_ref)?,
        None => return Err(AgentError::NoProvider),
    };

    let mut builder = ClientBuilder::new().api_key(api_key).provider(provider.kind.clone());
    if let Some(base_url) = &provider.base_url {
        builder = builder.base_url(base_url.clone());
    }
    let client = builder.build().map_err(|e| AgentError::Client(e.to_string()))?;

    let messages = build_messages(&history, &user_message);
    let request = ChatCompletionRequest { model: pref.model_id.clone(), messages, ..Default::default() };

    let run_id_for_task = run_id.clone();
    gen_ui_runtime::spawn(async move {
        run_stream(client, request, run_id_for_task).await;
    });

    Ok(run_id)
}

/// User + prior turns (role/text pairs, oldest first) into liter-llm Messages.
fn build_messages(history: &[String], user_message: &str) -> Vec<Message> {
    use liter_llm::types::common::{AssistantContent, AssistantMessage};

    let mut messages: Vec<Message> = history
        .chunks_exact(2)
        .filter_map(|pair| {
            let [role, text] = pair else { return None };
            match role.as_str() {
                "user" => Some(Message::User(UserMessage { content: UserContent::Text(text.clone()), name: None })),
                "assistant" => Some(Message::Assistant(AssistantMessage {
                    content: Some(AssistantContent::Text(text.clone())),
                    ..Default::default()
                })),
                _ => None,
            }
        })
        .collect();
    messages.push(Message::User(UserMessage { content: UserContent::Text(user_message.to_string()), name: None }));
    messages
}

async fn run_stream(client: impl LlmClient, request: ChatCompletionRequest, run_id: String) {
    let mut adapter = A2uiAdapter::new(run_id.clone());
    for event in adapter.ingest(&StreamEvent::MessageStart) {
        state::publish(event);
    }

    let stream = match client.chat_stream(request).await {
        Ok(s) => s,
        Err(e) => {
            for event in adapter.ingest(&StreamEvent::Error { message: e.to_string() }) {
                state::publish(event);
            }
            return;
        }
    };

    use futures::StreamExt;
    let mut stream = std::pin::pin!(stream);
    let mut index: u32 = 0;
    while let Some(chunk) = stream.next().await {
        match chunk {
            Ok(chunk) => {
                for choice in &chunk.choices {
                    if let Some(delta) = &choice.delta.content {
                        for event in
                            adapter.ingest(&StreamEvent::TextDelta { index, delta: delta.clone() })
                        {
                            state::publish(event);
                        }
                        index += 1;
                    }
                    if choice.finish_reason.is_some() {
                        for event in adapter.ingest(&StreamEvent::Done) {
                            state::publish(event);
                        }
                        return;
                    }
                }
            }
            Err(e) => {
                for event in adapter.ingest(&StreamEvent::Error { message: e.to_string() }) {
                    state::publish(event);
                }
                return;
            }
        }
    }
    // Stream ended without an explicit finish_reason (some providers omit it on
    // the final chunk) — still signal completion so the UI stops its spinner.
    for event in adapter.ingest(&StreamEvent::Done) {
        state::publish(event);
    }
}
