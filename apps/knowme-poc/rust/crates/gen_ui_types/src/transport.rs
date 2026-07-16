// TJ-ARCH-MOB-001 compliant
//! EntityTransport — the entity data-access seam. Implemented per entity type in
//! gen_ui_db / gen_ui_client; exposed to Dart via gen_ui_ffi. UI never implements it.
use crate::error::CoreResult;
use crate::view::ViewDescriptor;
use async_trait::async_trait;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct EntityRecord { pub id: String, pub entity_type: String, pub data_json: String }

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ListResult { pub items: Vec<EntityRecord>, pub next_cursor: Option<String> }

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(tag = "op", rename_all = "snake_case")]
pub enum ChangeEvent {
    Upsert { record: EntityRecord },
    Delete { entity_type: String, id: String },
    Invalidate { entity_type: String, list_key: Option<String> },
}

#[async_trait]
pub trait EntityTransport: Send + Sync {
    async fn list(&self, view: &ViewDescriptor) -> CoreResult<ListResult>;
    async fn get(&self, entity_type: &str, id: &str) -> CoreResult<Option<EntityRecord>>;
    async fn create(&self, record: &EntityRecord) -> CoreResult<EntityRecord>;
    async fn update(&self, record: &EntityRecord) -> CoreResult<EntityRecord>;
    async fn delete(&self, entity_type: &str, id: &str) -> CoreResult<()>;
}
