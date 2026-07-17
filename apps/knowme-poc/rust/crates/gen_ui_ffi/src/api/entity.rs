// TJ-ARCH-MOB-001 compliant
//! Entity CRUD intent surface. Mirrors the `EntityTransport` seam 1:1 so the Dart
//! `prometheus_entity_management` package (C-010) can drive it. ViewDescriptor /
//! EntityRecord cross the bridge as their gen_ui_types shapes (mirrored to freezed
//! unions on the Dart side). Wave-1 (C-003) supplies the backing store.
// `pub use` (not `use`) — frb_generated.rs re-exports this module's types via
// `use crate::api::entity::*`, which only sees items visible through a public path.
//
// frb's Result<T,E> detection only matches a literal `Result<...>` return
// type — it does NOT resolve through a generic type alias (see chat.rs's
// note). Every frb-exposed fn below spells out `Result<T, CoreError>`.
pub use gen_ui_types::transport::{EntityRecord, ListResult};
pub use gen_ui_types::view::ViewDescriptor;
pub use gen_ui_types::CoreError;

/// List entities matching a view (filters/sorts/pagination compiled to SQL in Rust).
pub async fn entity_list(view: ViewDescriptor) -> Result<ListResult, CoreError> {
    // C-003 backs this with the relational store; C-007 lands the signature.
    let _ = view;
    Ok(ListResult {
        items: Vec::new(),
        next_cursor: None,
    })
}

/// Fetch one entity by type + id.
pub async fn entity_get(
    entity_type: String,
    id: String,
) -> Result<Option<EntityRecord>, CoreError> {
    let _ = (entity_type, id);
    Ok(None)
}

/// Create an entity. Emits a ChangeEvent::Upsert on the entity_changes stream.
pub async fn entity_create(record: EntityRecord) -> Result<EntityRecord, CoreError> {
    Ok(record)
}

/// Update an entity. Emits a ChangeEvent::Upsert.
pub async fn entity_update(record: EntityRecord) -> Result<EntityRecord, CoreError> {
    Ok(record)
}

/// Delete an entity. Emits a ChangeEvent::Delete.
pub async fn entity_delete(entity_type: String, id: String) -> Result<(), CoreError> {
    let _ = (entity_type, id);
    Ok(())
}
