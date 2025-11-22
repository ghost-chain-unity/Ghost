#!/bin/bash
set -e

echo "🔧 Setting up Smart Contracts Development Environment..."

# Enable corepack and setup pnpm
echo "📦 Setting up pnpm..."
corepack enable
corepack prepare pnpm@8.15.0 --activate

# Add local bin to PATH if not already added
if ! grep -q "/.local/bin" "$HOME/.bashrc"; then
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$HOME/.bashrc"
fi
export PATH="$HOME/.local/bin:$PATH"

# Install Slither (Solidity static analyzer) - skip if already installed
if ! command -v slither &> /dev/null; then
    echo "🔍 Installing Slither..."
    # Set timeout for pip install (max 300 seconds = 5 minutes)
    timeout 300 pip3 install --user slither-analyzer || {
        echo "⚠️  Failed to install Slither (timeout or error)"
        echo "   Install manually later: pip3 install --user slither-analyzer"
    }
else
    echo "✅ Slither already installed"
fi

# Install solc-select for managing Solidity compiler versions - skip if already installed
if ! command -v solc-select &> /dev/null; then
    echo "⚙️ Installing solc-select..."
    # Set timeout for pip install (max 180 seconds = 3 minutes)
    if timeout 180 pip3 install --user solc-select; then
        timeout 300 solc-select install 0.8.20 || echo "⚠️  Failed to install solc 0.8.20"
        solc-select use 0.8.20 2>/dev/null || true
    else
        echo "⚠️  Failed to install solc-select (timeout or error)"
        echo "   Install manually later: pip3 install --user solc-select"
    fi
else
    echo "✅ solc-select already installed"
    # Ensure 0.8.20 is installed and active
    timeout 300 solc-select install 0.8.20 2>/dev/null || true
    solc-select use 0.8.20 2>/dev/null || true
fi

# Foundry installation - SECURE automated installation with SHA256 verification
echo "🔨 Foundry Setup..."

# Function to compute SHA256 hash
compute_sha256() {
    if command -v sha256sum &> /dev/null; then
        sha256sum "$1" | awk '{print $1}'
    elif command -v shasum &> /dev/null; then
        shasum -a 256 "$1" | awk '{print $1}'
    else
        echo ""
    fi
}

# Check if Foundry is already installed and working
if command -v forge &> /dev/null && command -v cast &> /dev/null && \
   command -v anvil &> /dev/null && command -v chisel &> /dev/null; then
    echo "✅ Foundry already installed"
    forge --version
else
    echo "📥 Installing Foundry with SHA256 verification..."
    
    # Detect architecture
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        FOUNDRY_ARCH="amd64"
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        FOUNDRY_ARCH="arm64"
    else
        echo "❌ Unsupported architecture: $ARCH"
        echo "   Foundry supports: x86_64 (amd64), aarch64/arm64"
        exit 1
    fi
    
    # Use nightly release (most stable for automated installations)
    FOUNDRY_VERSION="nightly"
    FOUNDRY_PLATFORM="linux"
    FOUNDRY_DIR="$HOME/.foundry"
    FOUNDRY_BIN_DIR="$FOUNDRY_DIR/bin"
    
    # GitHub release URLs
    RELEASE_URL="https://github.com/foundry-rs/foundry/releases/download/${FOUNDRY_VERSION}/"
    BINARY_URL="${RELEASE_URL}foundry_${FOUNDRY_VERSION}_${FOUNDRY_PLATFORM}_${FOUNDRY_ARCH}.tar.gz"
    
    # Create temporary directory
    TMP_DIR=$(mktemp -d)
    trap "rm -rf $TMP_DIR" EXIT
    
    echo "📋 Downloading SHA256 checksum for verification..."
    TARBALL_NAME="foundry_${FOUNDRY_VERSION}_${FOUNDRY_PLATFORM}_${FOUNDRY_ARCH}.tar.gz"
    SHA256_URL="${RELEASE_URL}${TARBALL_NAME}.sha256"
    
    # Retry checksum download with exponential backoff
    CHECKSUM_SUCCESS=false
    for attempt in 1 2 3; do
        echo "   Downloading checksum (attempt $attempt/3)..."
        TIMEOUT=$((30 * attempt))  # 30s, 60s, 90s
        if curl -fsSL --connect-timeout $TIMEOUT --max-time $((TIMEOUT * 4)) "$SHA256_URL" -o "$TMP_DIR/checksum.txt"; then
            CHECKSUM_SUCCESS=true
            break
        else
            if [[ $attempt -lt 3 ]]; then
                WAIT_TIME=$((5 * attempt))  # 5s, 10s
                echo "   ⚠️  Download failed, retrying in ${WAIT_TIME}s..."
                sleep $WAIT_TIME
            fi
        fi
    done
    
    if [[ "$CHECKSUM_SUCCESS" != true ]]; then
        echo "❌ Failed to download checksum after 3 attempts"
        echo "   URL: $SHA256_URL"
        echo "   Install Foundry manually: curl -L https://foundry.paradigm.xyz | bash"
        exit 1
    fi
    
    # Extract expected hash (checksum file format: "hash  filename" or just "hash")
    EXPECTED_HASH=$(awk '{print $1}' "$TMP_DIR/checksum.txt")
    
    if [ -z "$EXPECTED_HASH" ]; then
        echo "❌ Failed to extract SHA256 hash from checksum file"
        exit 1
    fi
    
    echo "📝 Expected SHA256: ${EXPECTED_HASH:0:16}..."
    
    echo "📦 Downloading Foundry binaries (this may take a few minutes)..."
    
    # Retry binary download with exponential backoff
    BINARY_SUCCESS=false
    for attempt in 1 2 3; do
        echo "   Downloading binaries (attempt $attempt/3)..."
        TIMEOUT=$((60 * attempt))  # 60s, 120s, 180s
        MAX_TIME=$((600 + (300 * (attempt - 1))))  # 10min, 15min, 20min
        
        if curl -fsSL --connect-timeout $TIMEOUT --max-time $MAX_TIME "$BINARY_URL" -o "$TMP_DIR/foundry.tar.gz"; then
            BINARY_SUCCESS=true
            break
        else
            if [[ $attempt -lt 3 ]]; then
                WAIT_TIME=$((10 * attempt))  # 10s, 20s
                echo "   ⚠️  Download failed, retrying in ${WAIT_TIME}s..."
                sleep $WAIT_TIME
            fi
        fi
    done
    
    if [[ "$BINARY_SUCCESS" != true ]]; then
        echo "❌ Failed to download binaries after 3 attempts"
        echo "   URL: $BINARY_URL"
        echo "   Try manual installation: curl -L https://foundry.paradigm.xyz | bash && foundryup"
        exit 1
    fi
    
    echo "🔍 Verifying tarball SHA256 checksum..."
    ACTUAL_HASH=$(compute_sha256 "$TMP_DIR/foundry.tar.gz")
    
    if [ "$ACTUAL_HASH" = "$EXPECTED_HASH" ]; then
        echo "   ✅ Tarball verified: ${ACTUAL_HASH:0:16}..."
    else
        echo "   ❌ Tarball verification FAILED"
        echo "      Expected: $EXPECTED_HASH"
        echo "      Got:      $ACTUAL_HASH"
        echo ""
        echo "❌ SHA256 verification failed - installation aborted for security"
        exit 1
    fi
    
    echo "📂 Extracting binaries..."
    if ! tar -xzf "$TMP_DIR/foundry.tar.gz" -C "$TMP_DIR"; then
        echo "❌ Failed to extract tarball"
        exit 1
    fi
    
    # Verify all expected binaries are present
    BINARIES=(forge cast anvil chisel)
    for bin in "${BINARIES[@]}"; do
        if [ ! -f "$TMP_DIR/foundry/bin/$bin" ]; then
            echo "❌ Binary not found in tarball: $bin"
            exit 1
        fi
    done
    
    echo "✅ All binaries extracted successfully!"
    
    # Install binaries
    echo "📥 Installing to $FOUNDRY_BIN_DIR..."
    mkdir -p "$FOUNDRY_BIN_DIR"
    
    for bin in "${BINARIES[@]}"; do
        mv "$TMP_DIR/foundry/bin/$bin" "$FOUNDRY_BIN_DIR/"
        chmod +x "$FOUNDRY_BIN_DIR/$bin"
    done
    
    # Add to PATH permanently via .bashrc
    if ! grep -q "/.foundry/bin" "$HOME/.bashrc"; then
        echo "" >> "$HOME/.bashrc"
        echo "# Foundry binaries" >> "$HOME/.bashrc"
        echo "export PATH=\"\$HOME/.foundry/bin:\$PATH\"" >> "$HOME/.bashrc"
        echo "📝 Added Foundry to PATH in ~/.bashrc"
    fi
    
    # Add to current session PATH
    export PATH="$HOME/.foundry/bin:$PATH"
    
    echo "✅ Foundry installed successfully!"
    forge --version
fi

# Verify installations
echo ""
echo "✅ Installation Verification:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
node --version
pnpm --version
python3 --version
slither --version || echo "⚠️  Slither not in PATH - run: export PATH=\"\$HOME/.local/bin:\$PATH\""
solc --version || echo "⚠️  solc not in PATH"
echo ""
echo "Foundry Tools:"
forge --version 2>/dev/null || echo "⚠️  forge not found"
cast --version 2>/dev/null || echo "⚠️  cast not found"
anvil --version 2>/dev/null || echo "⚠️  anvil not found"
chisel --version 2>/dev/null || echo "⚠️  chisel not found"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "✅ Smart Contracts DevContainer setup complete!"
echo ""
echo "📝 Next steps:"
echo "   cd packages/contracts/chaing-token"
echo "   pnpm install"
echo "   pnpm hardhat compile"
echo "   pnpm hardhat test"
echo ""
