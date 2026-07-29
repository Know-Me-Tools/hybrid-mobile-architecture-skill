use axum::{Json, Router, routing::post};
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug)]
pub struct VerifiedSession {
    pub actor_id: String,
    pub tenant_id: String,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AgentRequest {
    pub message: String,
    pub idempotency_id: String,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AgentEvent {
    pub event_type: &'static str,
    pub text: String,
}

pub fn router() -> Router {
    Router::new().route("/api/v1/agent/runs", post(run_agent))
}

async fn run_agent(Json(request): Json<AgentRequest>) -> Json<Vec<AgentEvent>> {
    // Production adapters must derive VerifiedSession from validated server
    // middleware and delegate to service UAR. This deterministic slice proves
    // the public event contract without embedding a competing agent loop.
    Json(vec![
        AgentEvent {
            event_type: "modelDelta",
            text: request.message,
        },
        AgentEvent {
            event_type: "completed",
            text: request.idempotency_id,
        },
    ])
}
