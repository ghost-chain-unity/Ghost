#!/bin/bash
set -e

echo "🦀 Setting up Blockchain Node Development Environment..."

# Add wasm32 target for smart contracts - skip if already added
if ! rustup target list --installed | grep -q wasm32-unknown-unknown; then
    echo "📦 Adding wasm32-unknown-unknown target..."
    rustup target add wasm32-unknown-unknown
else
    echo "✅ wasm32-unknown-unknown target already installed"
fi

# Install additional Rust tools - check if already installed
echo "🔧 Installing Rust development tools..."
rustup component add rustfmt clippy 2>/dev/null || echo "✅ rustfmt and clippy already installed"

# Install cargo tools only if not already installed
# NOTE: These tools are optional and can take 10-20 minutes to compile
# Skip installation by setting SKIP_CARGO_TOOLS=true
if [[ "$SKIP_CARGO_TOOLS" != "true" ]]; then
    echo "🔧 Installing optional cargo tools (can take 10-20 minutes)..."
    echo "   To skip: export SKIP_CARGO_TOOLS=true"
    
    for tool in cargo-watch cargo-expand cargo-edit; do
        if ! command -v $tool &> /dev/null; then
            echo "Installing $tool..."
            # Set timeout for cargo install (max 600 seconds = 10 minutes per tool)
            timeout 600 cargo install $tool || echo "⚠️  Failed to install $tool (timeout or error - not critical)"
        else
            echo "✅ $tool already installed"
        fi
    done
else
    echo "⚠️  Skipping cargo tools installation (SKIP_CARGO_TOOLS=true)"
    echo "   Install manually later: cargo install cargo-watch cargo-expand cargo-edit"
fi

# Install protoc (Protocol Buffers compiler)
echo "⚙️ Installing protoc..."
if ! command -v protoc &> /dev/null; then
    PROTOC_VERSION="25.1"
    PROTOC_ZIP="protoc-${PROTOC_VERSION}-linux-x86_64.zip"
    echo "Downloading protoc v${PROTOC_VERSION}..."
    
    # Try primary download with retries
    DOWNLOAD_SUCCESS=false
    for attempt in 1 2 3; do
        echo "   Attempt $attempt/3..."
        if curl -fsSL --connect-timeout 30 --max-time 120 -LO "https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/${PROTOC_ZIP}"; then
            DOWNLOAD_SUCCESS=true
            break
        else
            if [[ $attempt -lt 3 ]]; then
                echo "   ⚠️  Download failed, retrying in 5 seconds..."
                sleep 5
            fi
        fi
    done
    
    if [[ "$DOWNLOAD_SUCCESS" == true ]]; then
        unzip -o $PROTOC_ZIP -d $HOME/.local
        rm -f $PROTOC_ZIP
        
        # Add to PATH permanently via .bashrc
        if ! grep -q "/.local/bin" "$HOME/.bashrc"; then
            echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$HOME/.bashrc"
        fi
        export PATH="$HOME/.local/bin:$PATH"
        echo "✅ protoc installed successfully"
    else
        echo "⚠️  Failed to download protoc after 3 attempts"
        echo "   Install manually: https://github.com/protocolbuffers/protobuf/releases"
        echo "   Or using package manager: sudo apt-get install protobuf-compiler"
    fi
else
    echo "✅ protoc already installed"
fi

# Install substrate development tools (optional)
echo "🔨 Installing substrate tools..."
echo "⚠️  Subkey installation requires heavy compilation and is optional"
echo "   If needed, install manually: cargo install --git https://github.com/paritytech/substrate subkey"
echo "   Skipping for faster DevContainer setup..."

# Verify installations
echo "✅ Verification:"
rustc --version
cargo --version
rustup show
rustup target list --installed | grep wasm32 || echo "⚠️  wasm32 target missing"
protoc --version || echo "⚠️  protoc not in PATH - add: export PATH=\"\$HOME/.local/bin:\$PATH\""

echo ""
echo "✅ Blockchain Node DevContainer setup complete!"
echo ""
echo "📝 Next steps:"
echo "   cd packages/chain/node-core"
echo "   cargo build --release"
echo "   cargo test"
echo "   cargo clippy"
echo ""
