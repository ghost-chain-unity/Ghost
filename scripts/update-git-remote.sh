#!/usr/bin/env bash
#
# Ghost Protocol - Update Git Remote Helper
# This script helps you update git remote to point to new repository
#

set -e

echo "🔧 Ghost Protocol - Git Remote Update Helper"
echo ""

# Show current remotes
echo "📌 Current Git Remotes:"
git remote -v | grep -v "gitsafe" || echo "  (no remotes configured)"
echo ""

# Ask for new repository URL
echo "📝 Please provide your new repository information:"
echo ""
read -p "Enter GitHub username/organization: " GITHUB_USER
read -p "Enter repository name (e.g., ghost-protocol): " REPO_NAME

echo ""
echo "🔄 Updating git remotes..."

# Update origin remote
NEW_SSH_URL="git@github.com:${GITHUB_USER}/${REPO_NAME}.git"
NEW_HTTPS_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}.git"

git remote set-url origin "$NEW_SSH_URL"
git remote set-url origin-https "$NEW_HTTPS_URL" 2>/dev/null || git remote add origin-https "$NEW_HTTPS_URL"
git remote set-url origin-ssh "$NEW_SSH_URL" 2>/dev/null || git remote add origin-ssh "$NEW_SSH_URL"

echo "✅ Git remotes updated!"
echo ""
echo "📌 New Git Remotes:"
git remote -v | grep -v "gitsafe"
echo ""

# Test connection
echo "🔐 Testing GitHub connection..."
if git ls-remote origin HEAD &>/dev/null; then
    echo "✅ Successfully connected to: $NEW_SSH_URL"
else
    echo "❌ Failed to connect to: $NEW_SSH_URL"
    echo ""
    echo "Possible issues:"
    echo "  1. Repository doesn't exist yet - create it on GitHub first"
    echo "  2. SSH key not configured - check your GitHub SSH keys"
    echo "  3. No access to repository - check permissions"
    echo ""
    echo "To create repository, visit: https://github.com/new"
fi

echo ""
echo "🚀 Next steps:"
echo "  1. If repository doesn't exist, create it on GitHub"
echo "  2. Push code: git push -u origin main"
echo "  3. Enable GitHub Actions in repository settings"
echo "  4. CI/CD will automatically use the new repository!"
