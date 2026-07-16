// TJ-ARCH-MOB-001 compliant
//! Tauri 2 plugin build script: generates permission schemas + the guest-side
//! command allowlist from COMMANDS. Keep COMMANDS in sync with the invoke_handler
//! in src/lib.rs.
const COMMANDS: &[&str] = &[
    "chat_send",
    "entity_list",
    "entity_get",
    "entity_create",
    "entity_update",
    "entity_delete",
    "memory_search",
    "graph_expand",
];

fn main() {
    tauri_plugin::Builder::new(COMMANDS)
        .android_path("android")
        .ios_path("ios")
        .build();
}
