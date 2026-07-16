// TJ-ARCH-MOB-001 compliant
// Tauri application entry point. Intent commands (chat, entity CRUD, memory,
// startup) are registered by tauri-plugin-gen-ui, NOT here — this file owns
// only app-shell concerns (menu, window chrome, other Tauri plugins).

use tauri::menu::{AboutMetadata, Menu, MenuItem, PredefinedMenuItem, Submenu};
use tauri::Manager;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        // Must be registered first: a second launch attempt is redirected here
        // instead of racing the first instance for the config-db PGlite lock.
        .plugin(tauri_plugin_single_instance::init(|app, _args, _cwd| {
            if let Some(window) = app.get_webview_window("main") {
                let _ = window.set_focus();
                let _ = window.unminimize();
            }
        }))
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_store::Builder::new().build())
        .plugin(tauri_plugin_os::init())
        .plugin(tauri_plugin_gen_ui::init())
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
