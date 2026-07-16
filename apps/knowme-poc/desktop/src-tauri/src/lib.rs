// TJ-ARCH-MOB-001 compliant
// Tauri application entry point
// gen_ui_core commands are registered here

mod commands;

use tauri::menu::{AboutMetadata, Menu, MenuItem, PredefinedMenuItem, Submenu};
use tauri::Manager;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_store::Builder::new().build())
        .plugin(tauri_plugin_os::init())
        // .manage(AppState::new())          // Uncomment when gen_ui_core is wired
        .invoke_handler(tauri::generate_handler![
            commands::run_migrations,
            commands::load_seeds,
            commands::attach_sync_shapes,
            commands::memory_ingest,
            commands::memory_search,
            commands::entity_runtime_start,
            commands::entity_runtime_stop,
        ])
        .setup(|app| {
            let exit = MenuItem::with_id(app, "exit", "Exit", true, Some("CmdOrCtrl+Q"))?;
            let file_menu = Submenu::with_items(app, "File", true, &[&exit])?;

            let toggle_devtools = MenuItem::with_id(
                app,
                "toggle_devtools",
                "Toggle Developer Tools",
                true,
                Some("CmdOrCtrl+Alt+I"),
            )?;
            // Toggle Developer Tools is the LAST item in View, per design.
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

            let about = PredefinedMenuItem::about(
                app,
                Some("About KnowMe"),
                Some(AboutMetadata::default()),
            )?;
            let help_menu = Submenu::with_items(app, "Help", true, &[&about])?;

            let menu = Menu::with_items(app, &[&file_menu, &view_menu, &help_menu])?;
            app.set_menu(menu)?;

            app.on_menu_event(move |app_handle, event| match event.id().as_ref() {
                "toggle_devtools" => {
                    if let Some(window) = app_handle.get_webview_window("main") {
                        if window.is_devtools_open() {
                            window.close_devtools();
                        } else {
                            window.open_devtools();
                        }
                    }
                }
                "exit" => app_handle.exit(0),
                _ => {}
            });

            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
