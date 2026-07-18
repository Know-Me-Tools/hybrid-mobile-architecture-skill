# syntax=docker/dockerfile:1.7@sha256:a57df69d0ea827fb7266491f2813635de6f17269be881f696fbfdf2d83dda33e

FROM node:24-bookworm-slim@sha256:6f7b03f7c2c8e2e784dcf9295400527b9b1270fd37b7e9a7285cf83b6951452d AS web
WORKDIR /workspace
RUN corepack enable && corepack prepare pnpm@11.11.0 --activate
COPY packages ./packages
COPY rust/crates/tauri-plugin-gen-ui/guest-js ./rust/crates/tauri-plugin-gen-ui/guest-js
COPY desktop/package.json desktop/pnpm-lock.yaml desktop/pnpm-workspace.yaml ./desktop/
WORKDIR /workspace/desktop
RUN pnpm install --frozen-lockfile
COPY desktop ./
RUN pnpm build

FROM rust:1.96-bookworm@sha256:a339861ae23e9abb272cea45dfafde21760d2ce6577a70f8a926153677902663 AS rust-builder
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        clang cmake git libclang-dev pkg-config protobuf-compiler \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /workspace/rust
COPY rust ./
COPY --from=web /workspace/desktop/dist /web-dist
ENV KNOWME_WEB_DIST_DIR=/web-dist
RUN cargo build --locked --release -p knowme-web-server

FROM debian:bookworm-slim@sha256:7b140f374b289a7c2befc338f42ebe6441b7ea838a042bbd5acbfca6ec875818 AS runtime
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 10001 knowme \
    && useradd --uid 10001 --gid knowme --create-home --shell /usr/sbin/nologin knowme \
    && install -d -o knowme -g knowme /var/lib/knowme
COPY --from=rust-builder /workspace/rust/target/release/knowme-web-server /usr/local/bin/knowme-web-server
USER 10001:10001
ENV KNOWME_BIND=0.0.0.0:8080 \
    KNOWME_DATA_DIR=/var/lib/knowme \
    RUST_LOG=info
VOLUME ["/var/lib/knowme"]
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=3s --start-period=30s --retries=5 \
    CMD ["curl", "--fail", "--silent", "http://127.0.0.1:8080/api/v1/ready"]
ENTRYPOINT ["/usr/local/bin/knowme-web-server"]
