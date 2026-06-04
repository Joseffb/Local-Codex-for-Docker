# syntax=docker/dockerfile:1.7

ARG RUST_VERSION=1.95.0

FROM rust:${RUST_VERSION}-bookworm AS builder

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        clang \
        cmake \
        git \
        libsqlite3-dev \
        libssl-dev \
        pkg-config \
        protobuf-compiler \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY . .

RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/src/codex-rs/target \
    cd codex-rs \
    && cargo build --locked --release -p codex-cli --bin codex \
    && install -m 0755 target/release/codex /usr/local/bin/codex

FROM debian:bookworm-slim AS runtime

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        gnupg \
        less \
        openssh-client \
        ripgrep \
        zsh \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian bookworm stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce-cli docker-buildx-plugin docker-compose-plugin \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/bin/codex /usr/local/bin/codex

RUN useradd --create-home --uid 1000 --shell /bin/zsh codex \
    && install -d -m 0755 -o codex -g codex /workspace /codex-home

USER codex
ENV CODEX_HOME=/codex-home
WORKDIR /workspace

ENTRYPOINT ["codex"]
