// TJ-ARCH-MOB-001 compliant
//! Scribe (voice-to-memory) intent surface: record -> on-device transcribe ->
//! hand text back for the caller to fold into `chat::memory_ingest`. Delegates
//! entirely to `gen_ui_audio` (shared with tauri-plugin-gen-ui desktop) — no
//! duplicated business logic between mobile/desktop.
//!
//! One recording in flight at a time per process, mirroring gen_ui_agent's
//! single-chat-turn precedent: `scribe_start` errors if a recording is already
//! live rather than silently discarding it.
use gen_ui_types::CoreResult;
use once_cell::sync::OnceCell;
use std::sync::Mutex;

static RECORDING: OnceCell<Mutex<Option<gen_ui_audio::Recorder>>> = OnceCell::new();

fn slot() -> &'static Mutex<Option<gen_ui_audio::Recorder>> {
    RECORDING.get_or_init(|| Mutex::new(None))
}

/// Start a microphone recording. Errors if one is already in progress.
pub fn scribe_start() -> CoreResult<()> {
    let mut guard = slot().lock().expect("scribe recording mutex poisoned");
    if guard.is_some() {
        return Err(gen_ui_types::CoreError::Terminal(
            "a recording is already in progress".to_string(),
        ));
    }
    let recorder = gen_ui_audio::Scribe::new()
        .start_recording()
        .map_err(Into::<gen_ui_types::CoreError>::into)?;
    *guard = Some(recorder);
    Ok(())
}

/// Stop the in-flight recording and transcribe it on-device. Returns the
/// transcript; the caller (Dart UI) decides whether/how to save it to memory.
pub async fn scribe_stop() -> CoreResult<String> {
    let recorder = slot()
        .lock()
        .expect("scribe recording mutex poisoned")
        .take()
        .ok_or_else(|| gen_ui_types::CoreError::Terminal("no recording in progress".to_string()))?;
    gen_ui_audio::Scribe::new()
        .stop_and_transcribe(recorder)
        .await
        .map_err(Into::<gen_ui_types::CoreError>::into)
}
