#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Ghost Protocol - Git History Cleanup Script                  ║"
echo "║  Remove .terraform folders from git history                    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Not in a git repository${NC}"
    exit 1
fi

# Check if there are uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo -e "${RED}❌ Error: You have uncommitted changes${NC}"
    echo "Please commit or stash your changes before running this script."
    git status --short
    exit 1
fi

# Display current repository size
echo -e "${YELLOW}📊 Current repository statistics:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
du -sh .git 2>/dev/null || echo "Unable to calculate .git size"
echo ""
echo "Files to be removed from history:"
git log --all --pretty=format: --name-only --diff-filter=A | grep '\.terraform' | sort -u | head -20
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Warning
echo -e "${RED}⚠️  WARNING: This operation will rewrite git history!${NC}"
echo ""
echo "This will:"
echo "  • Remove all .terraform folders from git history"
echo "  • Remove all .tfstate files from git history"
echo "  • Rewrite all commit SHAs"
echo "  • Require force-push to remote repository"
echo ""
echo "After running this script:"
echo "  1. All collaborators MUST re-clone the repository"
echo "  2. Open pull requests will need to be recreated"
echo "  3. You cannot undo this operation easily"
echo ""
echo -e "${YELLOW}Recommended steps BEFORE running:${NC}"
echo "  1. Notify all team members"
echo "  2. Create a backup: git clone --mirror <repo-url> backup-repo"
echo "  3. Ensure .gitignore is updated (should already be done)"
echo ""

# Confirmation prompt
read -p "Do you want to proceed? (type 'yes' to continue): " confirm
if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}Operation cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${GREEN}🚀 Starting cleanup process...${NC}"
echo ""

# Method 1: Using git filter-repo (recommended, faster and safer)
if command -v git-filter-repo &> /dev/null; then
    echo "Using git-filter-repo (recommended method)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Create filter file
    cat > /tmp/terraform-filter.txt << 'EOF'
# Remove .terraform directories
glob:.terraform/**
regex:.*\.terraform/.*

# Remove tfstate files
glob:*.tfstate
glob:*.tfstate.*
glob:*.tfstate.backup

# Remove tfvars that might contain secrets
glob:*.tfvars
glob:*.tfvars.json

# Remove Terraform crash logs
glob:crash.log
glob:crash.*.log
EOF
    
    echo "Filter rules created in /tmp/terraform-filter.txt"
    echo ""
    
    # Run git-filter-repo
    git filter-repo --invert-paths --paths-from-file /tmp/terraform-filter.txt --force
    
    # Cleanup
    rm /tmp/terraform-filter.txt
    
elif command -v java &> /dev/null; then
    # Method 2: Using BFG Repo-Cleaner (fallback)
    echo "Using BFG Repo-Cleaner (Java required)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Download BFG if not exists
    BFG_JAR="$HOME/.local/bin/bfg.jar"
    if [ ! -f "$BFG_JAR" ]; then
        echo "Downloading BFG Repo-Cleaner..."
        mkdir -p "$HOME/.local/bin"
        curl -fsSL -o "$BFG_JAR" "https://repo1.maven.org/maven2/com/madgag/bfg/1.14.0/bfg-1.14.0.jar"
        echo "✅ BFG downloaded to $BFG_JAR"
    fi
    
    # Run BFG
    echo "Running BFG to remove .terraform folders..."
    java -jar "$BFG_JAR" --delete-folders .terraform --no-blob-protection
    
    echo "Running BFG to remove .tfstate files..."
    java -jar "$BFG_JAR" --delete-files '*.tfstate' --no-blob-protection
    java -jar "$BFG_JAR" --delete-files '*.tfstate.*' --no-blob-protection
    
    # Clean up
    echo "Cleaning up repository..."
    git reflog expire --expire=now --all
    git gc --prune=now --aggressive
    
else
    # Method 3: Using git filter-branch (slowest, but always available)
    echo -e "${YELLOW}Warning: Using git filter-branch (slower method)${NC}"
    echo "Consider installing git-filter-repo for better performance:"
    echo "  pip3 install git-filter-repo"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Use filter-branch as last resort
    git filter-branch --force --index-filter \
        'git rm -r --cached --ignore-unmatch **/.terraform/ *.tfstate *.tfstate.* *.tfvars *.tfvars.json crash.log crash.*.log' \
        --prune-empty --tag-name-filter cat -- --all
    
    # Clean up
    echo "Cleaning up repository..."
    git reflog expire --expire=now --all
    git gc --prune=now --aggressive
fi

echo ""
echo -e "${GREEN}✅ Git history cleanup complete!${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${YELLOW}📊 New repository statistics:${NC}"
du -sh .git 2>/dev/null || echo "Unable to calculate .git size"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${GREEN}📝 Next steps:${NC}"
echo ""
echo "1. Verify the changes:"
echo "   git log --all --oneline --graph | head -20"
echo ""
echo "2. Push to remote (FORCE PUSH - be careful!):"
echo "   git push origin --force --all"
echo "   git push origin --force --tags"
echo ""
echo "3. Notify all team members to:"
echo "   • Delete their local repository"
echo "   • Re-clone from remote"
echo "   • DO NOT merge old branches"
echo ""
echo -e "${RED}⚠️  Remember: All collaborators MUST re-clone!${NC}"
echo ""
