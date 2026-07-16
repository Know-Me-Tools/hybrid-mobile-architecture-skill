// TJ-ARCH-MOB-001 compliant
//! gen_ui_protocol (L1) — A2UI/AG-UI adapters. Pure transformation over the L0
//! event enums; wasm-safe (no IO, no runtime dependency).
use gen_ui_types::events::{A2uiEvent, AguiEvent, StreamEvent};
use gen_ui_types::content_block::ContentBlock;

/// StreamEvent -> A2uiEvent(s). Feature-complete adapter to be filled per the
/// ContentBlock contract; C-001 lands the seam + a working text path.
pub struct A2uiAdapter { run_id: String }
impl A2uiAdapter {
    pub fn new(run_id: impl Into<String>) -> Self { Self { run_id: run_id.into() } }
    pub fn ingest(&mut self, ev: &StreamEvent) -> Vec<A2uiEvent> {
        match ev {
            StreamEvent::MessageStart => vec![A2uiEvent::RunStarted { run_id: self.run_id.clone() }],
            StreamEvent::TextDelta { delta, .. } =>
                vec![A2uiEvent::Block { block: ContentBlock::Text { text: delta.clone() } }],
            StreamEvent::Done => vec![A2uiEvent::RunFinished { run_id: self.run_id.clone() }],
            StreamEvent::Error { message } => vec![A2uiEvent::RunError { message: message.clone() }],
            _ => vec![],
        }
    }
}

/// A2uiEvent -> AguiEvent(s), bidirectional-capable.
pub struct AguiAdapter {
    thread_id: String,
    /// Retained for the bidirectional path (client→agent) filled in a later lane.
    #[allow(dead_code)]
    run_id: String,
}
impl AguiAdapter {
    pub fn new(thread_id: impl Into<String>, run_id: impl Into<String>) -> Self {
        Self { thread_id: thread_id.into(), run_id: run_id.into() }
    }
    pub fn translate(&mut self, ev: &A2uiEvent) -> Vec<AguiEvent> {
        match ev {
            A2uiEvent::RunStarted { run_id } =>
                vec![AguiEvent::RunStarted { thread_id: self.thread_id.clone(), run_id: run_id.clone() }],
            A2uiEvent::Block { block: ContentBlock::Text { text } } =>
                vec![AguiEvent::TextMessageContent { delta: text.clone() }],
            A2uiEvent::RunFinished { run_id } => vec![AguiEvent::RunFinished { run_id: run_id.clone() }],
            _ => vec![],
        }
    }
}
