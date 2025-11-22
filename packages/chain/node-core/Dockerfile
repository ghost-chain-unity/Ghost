# =========================
# Stage 1 — Builder
# =========================
FROM rust:1.80 AS builder

# Install dependencies required by Substrate/Polkadot builds
RUN apt-get update && apt-get install -y \
    clang \
    protobuf-compiler \
    cmake \
    pkg-config \
    libssl-dev \
    build-essential

WORKDIR /polkadot

# =======================================
# Dependency caching layer (very important)
# =======================================
# Copy workspace manifests (needed for cargo fetch)
COPY Cargo.toml Cargo.lock ./
COPY runtime/Cargo.toml ./runtime/
COPY node/Cargo.toml ./node/
COPY pallets/chainghost/Cargo.toml ./pallets/chainghost/
COPY pallets/g3mail/Cargo.toml ./pallets/g3mail/
COPY pallets/ghonity/Cargo.toml ./pallets/ghonity/
COPY pallets/template/Cargo.toml ./pallets/template/

# Prevent temp directory issues in Docker
ENV RUST_TMPDIR=/polkadot/tmp
RUN mkdir -p /polkadot/tmp

# Prefetch dependencies for caching
RUN cargo fetch

# =======================================
# Real source build
# =======================================
COPY . /polkadot

RUN cargo build --locked --release

# =========================
# Stage 2 — Runtime Image
# =========================
FROM docker.io/parity/base-bin:latest

COPY --from=builder /polkadot/target/release/ghost-node /usr/local/bin

USER root
RUN useradd -m -u 1001 -U -s /bin/sh -d /polkadot polkadot && \
        mkdir -p /data /polkadot/.local/share && \
        chown -R polkadot:polkadot /data && \
        ln -s /data /polkadot/.local/share/polkadot && \
        rm -rf /usr/bin /usr/sbin && \
        /usr/local/bin/ghost-node --version

USER polkadot

EXPOSE 30333 9933 9944 9615
VOLUME ["/data"]

ENTRYPOINT ["/usr/local/bin/ghost-node"]
