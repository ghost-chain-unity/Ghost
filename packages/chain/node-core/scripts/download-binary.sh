#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BINARIES_DIR="$NODE_DIR/binaries"

# Configuration
GITHUB_OWNER="Ghost-unity-chain"
GITHUB_REPO="Ghost"
OS_TYPE=$(uname -s)
ARCH_TYPE=$(uname -m)

# Determine OS and architecture
case "$OS_TYPE" in
    Linux*)
        PLATFORM="linux"
        if [ "$ARCH_TYPE" = "x86_64" ]; then
            ARTIFACT_NAME="ghost-node-linux-x86_64"
        elif [ "$ARCH_TYPE" = "aarch64" ]; then
            ARTIFACT_NAME="ghost-node-linux-aarch64"
        else
            echo "❌ Unsupported architecture: $ARCH_TYPE"
            exit 1
        fi
        ;;
    Darwin*)
        PLATFORM="macos"
        if [ "$ARCH_TYPE" = "x86_64" ]; then
            ARTIFACT_NAME="ghost-node-macos-x86_64"
        elif [ "$ARCH_TYPE" = "arm64" ]; then
            ARTIFACT_NAME="ghost-node-macos-aarch64"
        else
            echo "❌ Unsupported architecture: $ARCH_TYPE"
            exit 1
        fi
        ;;
    MINGW*)
        PLATFORM="windows"
        ARTIFACT_NAME="ghost-node-windows-x86_64.exe"
        ;;
    *)
        echo "❌ Unsupported OS: $OS_TYPE"
        exit 1
        ;;
esac

echo "========================================="
echo "Ghost Node Binary Download"
echo "========================================="
echo ""
echo "Platform: $PLATFORM ($ARCH_TYPE)"
echo "GitHub: $GITHUB_OWNER/$GITHUB_REPO"
echo ""

mkdir -p "$BINARIES_DIR"

# Get latest release tag (use v0.1.0 as default if API fails)
echo "📥 Determining release tag..."

# Try API first
RELEASE_TAG=$(curl -s "https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/releases/latest" 2>/dev/null | grep -o '"tag_name":"[^"]*' | cut -d'"' -f4 | head -1)

# Fallback to v0.1.0
if [ -z "$RELEASE_TAG" ]; then
    echo "⚠️  API fetch failed, using v0.1.0 as default"
    RELEASE_TAG="v0.1.0"
fi

echo "✅ Release tag: $RELEASE_TAG"

# Construct download URL (standard GitHub releases format)
DOWNLOAD_URL="https://github.com/$GITHUB_OWNER/$GITHUB_REPO/releases/download/$RELEASE_TAG/$ARTIFACT_NAME"

# Verify URL exists by checking with HEAD request
if ! curl -s -I -f "$DOWNLOAD_URL" > /dev/null 2>&1; then
    echo "❌ Binary not found at: $DOWNLOAD_URL"
    echo ""
    echo "Trying alternate URL patterns..."
    
    # Try without platform suffix
    ARTIFACT_ALT="ghost-node"
    DOWNLOAD_URL="https://github.com/$GITHUB_OWNER/$GITHUB_REPO/releases/download/$RELEASE_TAG/$ARTIFACT_ALT"
    
    if ! curl -s -I -f "$DOWNLOAD_URL" > /dev/null 2>&1; then
        echo "❌ Could not find binary at alternate URLs"
        echo "Visit: https://github.com/$GITHUB_OWNER/$GITHUB_REPO/releases/tag/$RELEASE_TAG"
        exit 1
    fi
    ARTIFACT_NAME=$ARTIFACT_ALT
fi

BINARY_PATH="$BINARIES_DIR/$ARTIFACT_NAME"
CHECKSUM_PATH="$BINARIES_DIR/${ARTIFACT_NAME}.sha256"

echo ""
echo "📥 Downloading binary..."
echo "URL: $DOWNLOAD_URL"
echo ""

# Download with progress
curl -L -o "$BINARY_PATH" -\# "$DOWNLOAD_URL"

# Download checksum
CHECKSUM_URL="${DOWNLOAD_URL}.sha256"
if curl -s -f -o "$CHECKSUM_PATH" "$CHECKSUM_URL"; then
    echo ""
    echo "🔐 Verifying checksum..."
    
    if command -v sha256sum &> /dev/null; then
        CHECKSUM_TOOL="sha256sum"
    elif command -v shasum &> /dev/null; then
        CHECKSUM_TOOL="shasum -a 256"
    else
        echo "⚠️  Checksum verification tool not found, skipping verification"
        CHECKSUM_TOOL=""
    fi
    
    if [ -n "$CHECKSUM_TOOL" ]; then
        cd "$BINARIES_DIR"
        if $CHECKSUM_TOOL -c "${ARTIFACT_NAME}.sha256"; then
            echo "✅ Checksum verified!"
        else
            echo "❌ Checksum verification failed!"
            rm -f "$BINARY_PATH" "$CHECKSUM_PATH"
            exit 1
        fi
    fi
else
    echo "⚠️  Could not download checksum, skipping verification"
fi

# Make executable
chmod +x "$BINARY_PATH"

# Create symlink to standard location
BINARY_LINK="$NODE_DIR/target/release/ghost-node"
mkdir -p "$(dirname "$BINARY_LINK")"
ln -sf "$BINARY_PATH" "$BINARY_LINK"

echo ""
echo "========================================="
echo "✅ Download successful!"
echo "========================================="
echo ""
echo "Binary location:"
echo "  $BINARY_PATH"
echo ""
echo "Symlink:"
echo "  $BINARY_LINK"
echo ""
echo "Version: $RELEASE_TAG"
echo ""
echo "Next steps:"
echo "  1. Generate chain spec:  ./scripts/generate-chain-spec.sh"
echo "  2. Start testnet:        ./scripts/start-testnet.sh"
echo ""
