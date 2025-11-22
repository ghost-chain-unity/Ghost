#!/bin/bash
# Ghost Protocol - One-Click Build & Download
# Triggers GitHub Actions workflow and auto-downloads binary when ready

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 Ghost Chain - Auto Build & Download${NC}"
echo ""

# Check gh CLI
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI not found${NC}"
    echo ""
    echo "GitHub CLI is required to trigger builds and download artifacts."
    echo ""
    echo "Installation options:"
    echo "  • Replit: Already installed (if you see this, there's an issue)"
    echo "  • macOS: brew install gh"
    echo "  • Linux: sudo apt install gh"
    echo "  • Windows: winget install --id GitHub.cli"
    echo ""
    echo "See docs/scripts-usage-guide.md for detailed instructions"
    exit 1
fi

# Check authentication
echo -e "${BLUE}🔐 Checking GitHub authentication...${NC}"
if ! gh auth status &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI not authenticated${NC}"
    echo ""
    echo "Please authenticate with GitHub first:"
    echo "  gh auth login"
    echo ""
    echo "Follow the interactive prompts to complete authentication."
    echo "See docs/scripts-usage-guide.md for step-by-step guide"
    exit 1
fi

echo -e "${GREEN}✅ GitHub authentication verified${NC}"
echo ""

# Trigger workflow
echo -e "${BLUE}📤 Triggering blockchain build workflow...${NC}"
if gh workflow run blockchain-node-ci.yml 2>&1; then
    echo -e "${GREEN}✅ Workflow triggered successfully!${NC}"
else
    echo -e "${RED}❌ Failed to trigger workflow${NC}"
    echo ""
    echo "Possible issues:"
    echo "  • No write access to repository"
    echo "  • Repository not found"
    echo "  • Network connectivity issues"
    echo ""
    echo "Try manually:"
    echo "  1. Go to GitHub repository"
    echo "  2. Click 'Actions' tab"
    echo "  3. Select 'Blockchain Node CI' workflow"
    echo "  4. Click 'Run workflow'"
    exit 1
fi

echo ""
echo -e "${BLUE}⏳ Waiting for workflow to start (60 seconds)...${NC}"
sleep 60

# Download binary (script handles waiting)
echo ""
echo -e "${BLUE}📥 Starting download (will wait if build still in progress)...${NC}"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [[ -f "$SCRIPT_DIR/download-chain-binary.sh" ]]; then
    "$SCRIPT_DIR/download-chain-binary.sh"
else
    echo -e "${RED}❌ download-chain-binary.sh not found${NC}"
    echo "Expected location: $SCRIPT_DIR/download-chain-binary.sh"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 Complete! Node ready to use.${NC}"
echo ""
echo "Start testnet:"
echo "  ./bin/ghost-node --dev --tmp"
echo ""
echo "For more commands, see: docs/scripts-usage-guide.md"
