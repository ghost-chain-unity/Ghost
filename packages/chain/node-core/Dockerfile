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
# Note: COPY paths are relative to build context - adjust based on where Docker is built from
# If building from repo root: use packages/chain/node-core/...
# If building from node-core: use ./, runtime/, etc.
COPY Cargo.toml Cargo.lock* ./
COPY runtime/Cargo.toml ./runtime/
COPY node/Cargo.toml ./node/
COPY pallets/chainghost/Cargo.toml ./pallets/chainghost/
COPY pallets/g3mail/Cargo.toml ./pallets/g3mail/
COPY pallets/ghonity/Cargo.toml ./pallets/ghonity/
COPY pallets/template/Cargo.toml ./pallets/template/

# Copy dummy source files to satisfy Cargo manifest checks
# Cargo will use these during fetch, then replace with real source on next COPY
RUN mkdir -p runtime/src node/src pallets/chainghost/src pallets/g3mail/src pallets/ghonity/src pallets/template/src
RUN echo 'fn main() {}' > node/src/main.rs
RUN echo 'fn main() {}' > runtime/src/lib.rs
RUN echo 'pub fn lib() {}' > pallets/chainghost/src/lib.rs
RUN echo 'pub fn lib() {}' > pallets/g3mail/src/lib.rs
RUN echo 'pub fn lib() {}' > pallets/ghonity/src/lib.rs
RUN echo 'pub fn lib() {}' > pallets/template/src/lib.rs

# Prevent temp directory issues in Docker
ENV RUST_TMPDIR=/polkadot/tmp
RUN mkdir -p /polkadot/tmp

# Prefetch dependencies for caching (with --locked if Cargo.lock exists)
RUN cargo fetch --locked || cargo fetch

# =======================================
# Real source build
# =======================================
# Copy full source code (overwrites dummy files)
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
