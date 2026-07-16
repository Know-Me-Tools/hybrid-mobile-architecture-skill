// TJ-ARCH-MOB-001 compliant
//! Error mapping at the gen_ui_agent boundary. Downstream crates (gen_ui_ffi,
//! tauri-plugin-gen-ui) only ever see `gen_ui_types::CoreError` — liter-llm and
//! gen_ui_db's error taxonomies never leak across the FFI/Tauri boundary.

use gen_ui_db::relational::RelationalError;
use gen_ui_types::CoreError;
use liter_llm::LiterLlmError;

/// Map a liter-llm error onto the workspace error taxonomy. Transient failures
/// (rate limits, timeouts, 5xx/503) are distinguished from terminal ones so
/// callers can decide whether to retry.
pub(crate) fn from_liter_llm(err: LiterLlmError) -> CoreError {
    if err.is_transient() {
        CoreError::Transient(err.to_string())
    } else {
        CoreError::Terminal(err.to_string())
    }
}

/// Map a config-store (relational) error onto the workspace error taxonomy.
pub(crate) fn from_relational(err: RelationalError) -> CoreError {
    CoreError::Terminal(err.to_string())
}
