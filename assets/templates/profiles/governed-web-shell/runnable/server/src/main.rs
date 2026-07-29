#[tokio::main]
async fn main() {
    let listener = tokio::net::TcpListener::bind("127.0.0.1:3000")
        .await
        .expect("bind loopback");
    axum::serve(listener, __APP_CRATE___server::router())
        .await
        .expect("serve");
}
