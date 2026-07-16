// TJ-ARCH-MOB-001 compliant
//! Error taxonomy for the agent/chat layer, mapped into the shared CoreError.
use gen_ui_types::CoreError;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum AgentError {
    #[error("config store: {0}")]
    Config(String),
    #[error("no enabled provider configured for this lane")]
    NoProvider,
    #[error("provider referenced by model_pref no longer exists: {0}")]
    DanglingProvider(String),
    #[error("liter-llm client: {0}")]
    Client(String),
    #[error("agent runtime not initialised — call gen_ui_agent::state::init first")]
    NotInitialised,
}

impl From<AgentError> for CoreError {
    fn from(e: AgentError) -> Self {
        match e {
            AgentError::Config(m) => CoreError::Transient(m),
            AgentError::NoProvider => CoreError::Terminal(e.to_string()),
            AgentError::DanglingProvider(m) => CoreError::Terminal(m),
            AgentError::Client(m) => CoreError::Transient(m),
            AgentError::NotInitialised => CoreError::Terminal(e.to_string()),
        }
    }
}
