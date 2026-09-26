// TJ-ARCH-MOB-001 compliant
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]
use std::path::PathBuf;
use tauri::Manager;
struct NotesState {
    database: PathBuf,
}
#[tauri::command]
async fn list_notes(
    state: tauri::State<'_, NotesState>,
) -> Result<Vec<gen_ui_notes::Note>, String> {
    let path = state.database.clone();
    tauri::async_runtime::spawn_blocking(move || gen_ui_notes::open(&path)?.list())
        .await
        .map_err(|e| e.to_string())?
        .map_err(|e| e.to_string())
}
#[tauri::command]
async fn create_note(
    title: String,
    state: tauri::State<'_, NotesState>,
) -> Result<gen_ui_notes::Note, String> {
    let path = state.database.clone();
    tauri::async_runtime::spawn_blocking(move || gen_ui_notes::open(&path)?.create(&title))
        .await
        .map_err(|e| e.to_string())?
        .map_err(|e| e.to_string())
}
#[tauri::command]
fn list_capabilities() -> Result<Vec<gen_ui_notes::Capability>, String> {
    gen_ui_notes::capabilities().map_err(|e| e.to_string())
}
fn main() {
    tauri::Builder::default()
        .setup(|app| {
            let data = std::env::var_os("APP_DATA_DIR")
                .map(PathBuf::from)
                .map(Ok)
                .unwrap_or_else(|| app.path().app_data_dir())?;
            let database = data.join("notes.sqlite3");
            gen_ui_notes::open(&database)?;
            app.manage(NotesState { database });
            let main_window = tauri::WebviewWindowBuilder::from_config(
                app.handle(),
                &app.config().app.windows[0],
            )?;
            #[cfg(target_os = "windows")]
            let main_window = if let Ok(arguments) = std::env::var("TAURI_WEBVIEW_BROWSER_ARGS") {
                main_window.additional_browser_args(&arguments)
            } else {
                main_window
            };
            #[cfg(target_os = "windows")]
            let main_window =
                if let Some(directory) = std::env::var_os("TAURI_WEBVIEW_DATA_DIRECTORY") {
                    main_window.data_directory(PathBuf::from(directory))
                } else {
                    main_window
                };
            main_window.build()?;
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            list_notes,
            create_note,
            list_capabilities
        ])
        .run(tauri::generate_context!())
        .expect("application runtime failed");
}
