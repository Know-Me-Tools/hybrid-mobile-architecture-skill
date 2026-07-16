// TJ-ARCH-MOB-001 compliant
//! Desktop local-inference lane: mistral.rs (Metal on macOS).
//!
//! Fulfils `InferenceProvider` so gen_ui_agent drives a local model through the
//! exact seam it uses for the remote gateway — `generate` yields the same
//! `StreamEvent`s the liter-llm path does, so gen_ui_protocol's A2uiAdapter
//! ingests local and cloud tokens identically and the UI never branches on lane.
use std::sync::Arc;

use async_trait::async_trait;
use futures::stream::{BoxStream, StreamExt};
use gen_ui_types::error::{CoreError, CoreResult};
use gen_ui_types::events::StreamEvent;
use gen_ui_types::inference::{InferenceProvider, LocalModelSpec, SampleParams};
use mistralrs::{
    ChatCompletionChunkResponse, ChunkChoice, Delta, GgufModelBuilder, Model, RequestBuilder,
    Response, TextMessageRole,
};
use tokio::sync::RwLock;

/// Classify a rendered engine error into the shared retryable/terminal split.
///
/// mistral.rs surfaces two unrelated error types across the API we use
/// (`anyhow::Error` from the builder, `mistralrs::error::Error` from streaming),
/// and neither exposes a structured out-of-memory variant — an allocation failure
/// arrives as a boxed candle/Metal error rendered into text. So classification is
/// done on the message. Cheap and honest: a misclassification costs one retry that
/// fails the same way, never a wrong answer.
fn classify(context: &str, rendered: String) -> CoreError {
    let lower = rendered.to_lowercase();
    let retryable = lower.contains("out of memory")
        || lower.contains("oom")
        || lower.contains("insufficient memory")
        || lower.contains("timed out")
        || lower.contains("timeout")
        || lower.contains("connection")
        || lower.contains("network")
        || lower.contains("dns");
    if retryable {
        CoreError::Transient(format!("{context}: {rendered}"))
    } else {
        CoreError::Terminal(format!("{context}: {rendered}"))
    }
}

/// Tokenizer/chat-template source for the GGUF quant repos we load. GGUF repos
/// ship weights only; mistral.rs pulls `tokenizer_config.json` + the chat
/// template from this separate repo (`with_tok_model_id`), so Qwen's template is
/// never hand-authored here.
const QWEN_TOK_REPO: &str = "Qwen/Qwen2.5-1.5B-Instruct";

/// The one catalog entry C-105 ships. `LocalModelSpec.model` is either this id or
/// an absolute path (trait contract), so the catalog stays a lookup, not a type.
const CATALOG_QWEN_1_5B: &str = "qwen2.5-1.5b-instruct-q4";
const CATALOG_QWEN_1_5B_REPO: &str = "Qwen/Qwen2.5-1.5B-Instruct-GGUF";
const CATALOG_QWEN_1_5B_FILE: &str = "qwen2.5-1.5b-instruct-q4_k_m.gguf";

/// mistral.rs-backed engine. `load` is idempotent per the trait contract: loading
/// the spec that is already resident is a no-op rather than a re-download.
pub struct MistralEngine {
    /// `None` until `load`. RwLock (not Mutex) so concurrent `generate` calls
    /// share the model — mistral.rs drives its own internal batching/threading.
    state: RwLock<Option<LoadedModel>>,
}

struct LoadedModel {
    model: Arc<Model>,
    /// What's resident, so `load` can detect the idempotent case.
    spec: LocalModelSpec,
}

impl MistralEngine {
    pub fn new() -> Self {
        Self { state: RwLock::new(None) }
    }
}

impl Default for MistralEngine {
    fn default() -> Self {
        Self::new()
    }
}

/// Resolve a spec's `model` into the (quant repo, gguf filename) mistral.rs needs.
/// An absolute path loads that file directly from disk; anything else must be a
/// known catalog id — an unknown id is Terminal (retrying won't invent a model).
fn resolve(spec: &LocalModelSpec) -> CoreResult<(String, String)> {
    if spec.model.starts_with('/') {
        let path = std::path::Path::new(&spec.model);
        let dir = path
            .parent()
            .and_then(|p| p.to_str())
            .ok_or_else(|| CoreError::Terminal(format!("model path has no parent dir: {}", spec.model)))?;
        let file = path
            .file_name()
            .and_then(|f| f.to_str())
            .ok_or_else(|| CoreError::Terminal(format!("model path has no filename: {}", spec.model)))?;
        return Ok((dir.to_string(), file.to_string()));
    }
    match spec.model.as_str() {
        CATALOG_QWEN_1_5B => Ok((CATALOG_QWEN_1_5B_REPO.to_string(), CATALOG_QWEN_1_5B_FILE.to_string())),
        other => Err(CoreError::NotFound(format!(
            "unknown local model id '{other}' — known: {CATALOG_QWEN_1_5B}, or an absolute .gguf path"
        ))),
    }
}

#[async_trait]
impl InferenceProvider for MistralEngine {
    async fn load(&self, spec: &LocalModelSpec) -> CoreResult<()> {
        // Idempotent per the trait contract — re-loading what's resident must not
        // re-download several GB.
        if self.state.read().await.as_ref().is_some_and(|l| &l.spec == spec) {
            return Ok(());
        }

        let (repo, file) = resolve(spec)?;

        // NOTE: mistral.rs's builder is already `async fn` and drives its own
        // internal threading, so this is deliberately NOT wrapped in
        // spawn_blocking — doing so would park a blocking-pool thread on a future
        // that yields anyway. It IS long-running (multi-GB download on first call),
        // which is why `load` is a separate trait method callers invoke off the
        // latency-sensitive path rather than lazily inside `generate`.
        //
        // `spec.context_len` is intentionally unused here: GgufModelBuilder exposes
        // no sequence-length override (verified against the API at our pinned rev) —
        // a GGUF's context length is baked into the file's own metadata. The field
        // stays in the trait for the llama-cpp-2 mobile lane, which does accept one.
        let model = GgufModelBuilder::new(repo, vec![file])
            .with_tok_model_id(QWEN_TOK_REPO)
            .build()
            .await
            // The builder returns anyhow::Error (NOT mistralrs::error::Error — the
            // two halves of this API disagree); `{e:#}` renders the full cause chain,
            // which is where the real reason (404, corrupt GGUF, OOM) actually lives.
            .map_err(|e| classify("model load", format!("{e:#}")))?;

        *self.state.write().await = Some(LoadedModel { model: Arc::new(model), spec: spec.clone() });
        tracing::info!(model = %spec.model, "local model loaded");
        Ok(())
    }

    async fn generate(
        &self,
        prompt: &str,
        params: &SampleParams,
    ) -> CoreResult<BoxStream<'static, StreamEvent>> {
        let model = {
            let guard = self.state.read().await;
            let loaded = guard.as_ref().ok_or_else(|| {
                CoreError::Terminal("no local model loaded — call load() first".to_string())
            })?;
            Arc::clone(&loaded.model)
        };

        let request = RequestBuilder::new()
            .add_message(TextMessageRole::User, prompt)
            .set_sampler_temperature(params.temperature as f64)
            .set_sampler_topp(params.top_p as f64)
            .set_sampler_max_len(params.max_tokens as usize);

        // mistral.rs's `Stream<'a>` borrows the `Model` it came from, but the trait
        // contract returns a `BoxStream<'static, _>`. Rather than fight that, drive
        // the borrowed stream inside a task that owns the `Arc<Model>` keeping it
        // alive, and hand the caller the receiving end. The task also outlives this
        // function, so generation continues even if the caller is slow to poll.
        let (tx, rx) = tokio::sync::mpsc::unbounded_channel::<StreamEvent>();

        gen_ui_runtime::spawn(async move {
            let mut stream = match model.stream_chat_request(request).await {
                Ok(s) => s,
                Err(e) => {
                    // Terminal for this run — report and end the stream rather than
                    // leaving the UI spinning.
                    let _ = tx.send(StreamEvent::Error { message: e.to_string() });
                    return;
                }
            };

            // Adapt mistral.rs's OpenAI-shaped chunks into StreamEvent. `index`
            // counts deltas within this run, matching the cloud lane's numbering.
            let mut index: u32 = 0;
            while let Some(response) = stream.next().await {
                let event = match response {
                    Response::Chunk(ChatCompletionChunkResponse { choices, .. }) => {
                        match choices.first() {
                            Some(ChunkChoice {
                                delta: Delta { content: Some(content), .. },
                                ..
                            }) if !content.is_empty() => {
                                let e = StreamEvent::TextDelta { index, delta: content.clone() };
                                index += 1;
                                Some(e)
                            }
                            // Empty/role-only/keep-alive chunk: nothing to render.
                            _ => None,
                        }
                    }
                    // ModelError carries a String + the partial response; the other
                    // two carry a boxed error. All three end the run.
                    Response::ModelError(message, _) => Some(StreamEvent::Error { message }),
                    Response::ValidationError(e) | Response::InternalError(e) => {
                        Some(StreamEvent::Error { message: e.to_string() })
                    }
                    // Completion/image/speech/embedding/agentic variants cannot occur
                    // on a chat stream_chat_request.
                    _ => None,
                };
                if let Some(event) = event {
                    let is_error = matches!(event, StreamEvent::Error { .. });
                    // Receiver dropped (caller stopped listening) — stop generating.
                    if tx.send(event).is_err() || is_error {
                        return;
                    }
                }
            }

            // Signal completion on clean exhaustion. Mirrors the cloud lane, which
            // also emits Done when a provider omits a final finish_reason.
            let _ = tx.send(StreamEvent::Done);
        });

        Ok(tokio_stream::wrappers::UnboundedReceiverStream::new(rx).boxed())
    }

    async fn unload(&self) -> CoreResult<()> {
        // Safe when nothing is loaded, per the trait contract. Dropping the Arc
        // frees the weights once in-flight generations release their clones.
        *self.state.write().await = None;
        tracing::info!("local model unloaded");
        Ok(())
    }
}
