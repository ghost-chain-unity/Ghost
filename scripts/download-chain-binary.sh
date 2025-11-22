#!/bin/bash
set -e

# Ghost Protocol - Chain Binary Downloader
# Downloads blockchain node binary from GitHub Actions artifacts
# Usage: ./scripts/download-chain-binary.sh [run-id] [--verify]

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BIN_DIR="$PROJECT_ROOT/bin"
WORKFLOW_NAME="blockchain-node-ci.yml"
ARTIFACT_NAME="ghost-node-linux-amd64"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    print_error "GitHub CLI (gh) is not installed"
    print_info "Install: https://cli.github.com/"
    print_info "Alternative: Download manually from GitHub Actions UI"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    print_error "GitHub CLI is not authenticated"
    print_info "Run: gh auth login"
    exit 1
fi

# Parse arguments
RUN_ID=""
VERIFY_CHECKSUM=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --verify)
            VERIFY_CHECKSUM=true
            shift
            ;;
        *)
            if [[ -z "$RUN_ID" ]]; then
                RUN_ID="$1"
            fi
            shift
            ;;
    esac
done

# Get latest successful run if RUN_ID not provided
if [[ -z "$RUN_ID" ]]; then
    print_info "Finding latest successful workflow run..."
    
    RUN_ID=$(gh run list \
        --workflow="$WORKFLOW_NAME" \
        --status=success \
        --limit=1 \
        --json databaseId \
        --jq '.[0].databaseId')
    
    if [[ -z "$RUN_ID" ]]; then
        print_error "No successful workflow runs found"
        print_info "Trigger a new build: gh workflow run $WORKFLOW_NAME"
        exit 1
    fi
    
    print_success "Found latest successful run: $RUN_ID"
fi

# Get run details
print_info "Fetching workflow run details..."
RUN_STATUS=$(gh run view "$RUN_ID" --json status --jq '.status')
RUN_CONCLUSION=$(gh run view "$RUN_ID" --json conclusion --jq '.conclusion')
RUN_BRANCH=$(gh run view "$RUN_ID" --json headBranch --jq '.headBranch')
RUN_COMMIT=$(gh run view "$RUN_ID" --json headSha --jq '.headSha' | cut -c1-7)

echo ""
print_info "Workflow Run Details:"
echo "   Run ID:     $RUN_ID"
echo "   Status:     $RUN_STATUS"
echo "   Conclusion: $RUN_CONCLUSION"
echo "   Branch:     $RUN_BRANCH"
echo "   Commit:     $RUN_COMMIT"
echo ""

# Check if run is complete
if [[ "$RUN_STATUS" != "completed" ]]; then
    print_warning "Workflow is still running. Waiting for completion..."
    print_info "You can watch progress with: gh run watch $RUN_ID"
    print_info "Or wait here (this script will wait)..."
    
    # Wait for completion
    gh run watch "$RUN_ID" --exit-status || {
        print_error "Workflow run failed"
        exit 1
    }
    
    # Refresh status and conclusion after watch completes
    print_info "Refreshing workflow status..."
    RUN_STATUS=$(gh run view "$RUN_ID" --json status --jq '.status')
    RUN_CONCLUSION=$(gh run view "$RUN_ID" --json conclusion --jq '.conclusion')
    echo "   Status:     $RUN_STATUS"
    echo "   Conclusion: $RUN_CONCLUSION"
fi

# Check if run was successful
if [[ "$RUN_CONCLUSION" != "success" ]]; then
    print_error "Workflow run was not successful: $RUN_CONCLUSION"
    print_info "View logs: gh run view $RUN_ID --log"
    exit 1
fi

# Create bin directory
mkdir -p "$BIN_DIR"

# Download artifact
print_info "Downloading artifact: $ARTIFACT_NAME..."
cd "$BIN_DIR"

# Clean up old downloads
rm -f "$ARTIFACT_NAME" "$ARTIFACT_NAME.zip"

# Download using gh CLI
if gh run download "$RUN_ID" --name "$ARTIFACT_NAME" 2>/dev/null; then
    print_success "Artifact downloaded successfully"
else
    print_error "Failed to download artifact"
    print_info "Artifact might not exist in this run"
    print_info "Available artifacts:"
    gh run view "$RUN_ID" --json artifacts --jq '.artifacts[].name'
    exit 1
fi

# Make binary executable
chmod +x "$ARTIFACT_NAME"

# Verify binary
print_info "Verifying binary..."
BINARY_PATH="$BIN_DIR/$ARTIFACT_NAME"

if [[ ! -f "$BINARY_PATH" ]]; then
    print_error "Binary file not found: $BINARY_PATH"
    exit 1
fi

# Check file type
FILE_TYPE=$(file "$BINARY_PATH")
echo "   File type: $FILE_TYPE"

if [[ ! "$FILE_TYPE" =~ "ELF 64-bit" ]]; then
    print_warning "Binary might not be a valid Linux executable"
fi

# Try to get version
print_info "Testing binary..."
if "$BINARY_PATH" --version 2>/dev/null; then
    print_success "Binary is functional"
else
    print_warning "Binary might not be functional (or --version not implemented)"
fi

# Create symlink for easier access
SYMLINK_PATH="$BIN_DIR/ghost-node"
rm -f "$SYMLINK_PATH"
ln -s "$ARTIFACT_NAME" "$SYMLINK_PATH"
print_success "Symlink created: bin/ghost-node -> $ARTIFACT_NAME"

# Verify checksum if requested
if [[ "$VERIFY_CHECKSUM" == true ]]; then
    print_info "Downloading SHA256 checksum..."
    
    CHECKSUM_ARTIFACT="$ARTIFACT_NAME.sha256"
    if gh run download "$RUN_ID" --name "$CHECKSUM_ARTIFACT" 2>/dev/null; then
        EXPECTED_HASH=$(cat "$CHECKSUM_ARTIFACT" | awk '{print $1}')
        
        if command -v sha256sum &> /dev/null; then
            ACTUAL_HASH=$(sha256sum "$ARTIFACT_NAME" | awk '{print $1}')
        elif command -v shasum &> /dev/null; then
            ACTUAL_HASH=$(shasum -a 256 "$ARTIFACT_NAME" | awk '{print $1}')
        else
            print_warning "No SHA256 tool found (sha256sum or shasum)"
            ACTUAL_HASH=""
        fi
        
        if [[ -n "$ACTUAL_HASH" ]]; then
            echo "   Expected: $EXPECTED_HASH"
            echo "   Actual:   $ACTUAL_HASH"
            
            if [[ "$ACTUAL_HASH" == "$EXPECTED_HASH" ]]; then
                print_success "Checksum verification passed"
            else
                print_error "Checksum verification FAILED"
                exit 1
            fi
        fi
    else
        print_warning "Checksum file not found in artifacts"
    fi
fi

# Print summary
echo ""
print_success "Download complete!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Binary Location: $BINARY_PATH"
echo "   Symlink:         $SYMLINK_PATH"
echo "   Run ID:          $RUN_ID"
echo "   Branch:          $RUN_BRANCH"
echo "   Commit:          $RUN_COMMIT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🚀 Next Steps:"
echo ""
echo "   # Test the binary"
echo "   ./bin/ghost-node --version"
echo ""
echo "   # Run development node"
echo "   ./bin/ghost-node --dev --tmp"
echo ""
echo "   # Run with persistent data"
echo "   ./bin/ghost-node --dev --base-path ./testnet-data"
echo ""
echo "   # See full guide"
echo "   cat docs/blockchain-node-build-guide.md"
echo ""
