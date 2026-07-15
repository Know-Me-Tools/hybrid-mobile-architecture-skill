// TJ-ARCH-MOB-001 compliant
//! c002 spike module — probes the two remaining wasm32 unknowns for C-007:
//!   1. a `fetch` + `EventSource` transport stub over web_sys (the wasm side of
//!      the Transport seam whose native side is reqwest / reqwest-eventsource);
//!   2. a wasm-bindgen `extern` binding to ElectricSQL PGlite (JS-side dep), to
//!      prove Rust↔PGlite interop is expressible from `gen_ui_wasm`.
//!
//! This is a COMPILE probe. It never runs here (needs a browser + a bundled
//! `@electric-sql/pglite`); it proves the FFI surface type-checks on wasm32 so
//! C-007 can build the real leaf against a known-good shape.
#![cfg(target_arch = "wasm32")]

use wasm_bindgen::prelude::*;
use wasm_bindgen::JsCast;
use wasm_bindgen_futures::JsFuture;
use web_sys::{EventSource, MessageEvent, Request, RequestInit, Response};

// ── 1. fetch transport stub ──────────────────────────────────────────────────
// Native gen_ui_client uses reqwest; on web the browser owns TLS/HTTP, so the
// Transport impl calls `fetch`. This proves the request→await→text path compiles.

/// GET `url` via the browser `fetch` API and return the response body text.
pub async fn fetch_text(url: &str) -> Result<String, JsValue> {
    let opts = RequestInit::new();
    opts.set_method("GET");
    let request = Request::new_with_str_and_init(url, &opts)?;

    let window = web_sys::window().ok_or_else(|| JsValue::from_str("no window"))?;
    let resp_value = JsFuture::from(window.fetch_with_request(&request)).await?;
    let resp: Response = resp_value.dyn_into()?;
    let text_value = JsFuture::from(resp.text()?).await?;
    text_value
        .as_string()
        .ok_or_else(|| JsValue::from_str("response body was not a string"))
}

// ── EventSource (SSE) stub ────────────────────────────────────────────────────
// The A2UI/AG-UI stream lane on web. reqwest-eventsource has no wasm backend, so
// the browser `EventSource` is the wasm equivalent. Proves callback wiring + the
// `onmessage` closure type-check on wasm32.

/// Open an SSE stream and forward each message payload to `on_message`.
/// Returns the live `EventSource` (caller keeps it alive; drop = close).
pub fn open_sse(
    url: &str,
    on_message: impl Fn(String) + 'static,
) -> Result<EventSource, JsValue> {
    let source = EventSource::new(url)?;
    let cb = Closure::<dyn FnMut(MessageEvent)>::new(move |ev: MessageEvent| {
        if let Some(text) = ev.data().as_string() {
            on_message(text);
        }
    });
    source.set_onmessage(Some(cb.as_ref().unchecked_ref()));
    // Leak the closure into the JS event loop for the life of the stream. C-007
    // will hold it in a struct field instead; here we only prove it compiles.
    cb.forget();
    Ok(source)
}

// ── 2. PGlite interop probe ───────────────────────────────────────────────────
// PGlite ships as a JS/WASM package (`@electric-sql/pglite`). From Rust we reach
// it through wasm-bindgen `extern` bindings — the module is resolved by the JS
// bundler at build time, NOT by cargo. This proves the binding shape type-checks.

#[wasm_bindgen(module = "/js/pglite_shim.js")]
extern "C" {
    /// Mirrors `new PGlite('idb://<name>')` behind a small JS shim so the Rust
    /// side sees a stable async surface. The shim is a C-007 deliverable; the
    /// path here is a placeholder proving the `extern` block compiles.
    #[wasm_bindgen(js_name = "createPglite", catch)]
    async fn create_pglite(data_dir: &str) -> Result<JsValue, JsValue>;

    /// Mirrors `db.query(sql)` → returns rows as a JS value (JSON-serializable).
    #[wasm_bindgen(js_name = "pgliteQuery", catch)]
    async fn pglite_query(db: &JsValue, sql: &str) -> Result<JsValue, JsValue>;
}

/// End-to-end interop shape: open a PGlite IndexedDB instance and run one query.
/// FINDING: PGlite is JS-owned; the ONLY sound Rust boundary is a wasm-bindgen
/// `extern` over a thin JS shim (C-007 ships `js/pglite_shim.js`). There is no
/// native-Rust PGlite client — do not attempt an sqlx/tokio-postgres path on web.
pub async fn pglite_roundtrip(name: &str, sql: &str) -> Result<JsValue, JsValue> {
    let db = create_pglite(name).await?;
    pglite_query(&db, sql).await
}
