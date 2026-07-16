// TJ-ARCH-MOB-001 compliant
// Tauri application entry point
// gen_ui_core commands are registered here

use tauri::menu::{Menu, MenuItem, PredefinedMenuItem, Submenu};
use tauri::Manager;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_store::Builder::new().build())
        // .manage(AppState::new())          // Uncomment when gen_ui_core is wired
        // .invoke_handler(tauri::generate_handler![  // Register commands
        //     commands::stream_agent_a2ui,
        //     commands::entity_list, commands::entity_get,
        //     commands::entity_create, commands::entity_update, commands::entity_delete,
        //     commands::entity_runtime_start, commands::entity_runtime_stop,
        //     commands::memory_ingest, commands::memory_search, commands::graph_expand,
        //     commands::run_migrations, commands::load_seeds, commands::attach_sync_shapes,
        //     commands::mcp_call_tool,
        // ])
        .setup(|app| {
            let toggle_devtools = MenuItem::with_id(
                app,
                "toggle_devtools",
                "Toggle Developer Tools",
                true,
                Some("CmdOrCtrl+Alt+I"),
            )?;
            let view_menu = Submenu::with_items(
                app,
                "View",
                true,
                &[
                    &PredefinedMenuItem::fullscreen(app, None)?,
                    &PredefinedMenuItem::separator(app)?,
                    &toggle_devtools,
                ],
            )?;
            let menu = Menu::with_items(app, &[&view_menu])?;
            app.set_menu(menu)?;

            app.on_menu_event(move |app_handle, event| {
                if event.id() == "toggle_devtools" {
                    if let Some(window) = app_handle.get_webview_window("main") {
                        if window.is_devtools_open() {
                            window.close_devtools();
                        } else {
                            window.open_devtools();
                        }
                    }
                }
            });

            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
