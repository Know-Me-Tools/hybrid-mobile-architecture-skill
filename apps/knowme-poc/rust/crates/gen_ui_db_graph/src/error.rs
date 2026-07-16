// TJ-ARCH-MOB-001 compliant
//! Error taxonomy for the graph store, with a lossless map into the shared
//! `gen_ui_types::CoreError` so the FFI boundary sees one error type.
use gen_ui_types::CoreError;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum GraphError {
    #[error("surreal: {0}")]
    Surreal(String),
    #[error("embedding: {0}")]
    Embedding(String),
    #[error("serialize: {0}")]
    Serialize(String),
    #[error("invalid input: {0}")]
    Invalid(String),
    #[error("not found: {0}")]
    NotFound(String),
}

impl From<surrealdb::Error> for GraphError {
    fn from(e: surrealdb::Error) -> Self {
        GraphError::Surreal(e.to_string())
    }
}

impl From<serde_json::Error> for GraphError {
    fn from(e: serde_json::Error) -> Self {
        GraphError::Serialize(e.to_string())
    }
}

impl From<GraphError> for CoreError {
    fn from(e: GraphError) -> Self {
        match e {
            // A dead embedded DB / locked file is worth a retry; a bad query is not.
            GraphError::Surreal(m) => CoreError::Transient(m),
            GraphError::Embedding(m) => CoreError::Transient(m),
            GraphError::Serialize(m) => CoreError::Serde(m),
            GraphError::Invalid(m) => CoreError::Terminal(m),
            GraphError::NotFound(m) => CoreError::NotFound(m),
        }
    }
}
