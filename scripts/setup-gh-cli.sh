#!/usr/bin/env bash
#
# Ghost Protocol - GitHub CLI Auto-Setup Script
# This script configures GitHub CLI using GH_TOKEN from Replit Secrets
#

set -e

echo "🔧 Setting up GitHub CLI..."

if [ -z "$GH_TOKEN" ]; then
    echo "❌ ERROR: GH_TOKEN environment variable is not set"
    echo "   Please add GH_TOKEN to Replit Secrets"
    echo "   Instructions: https://github.com/settings/tokens/new"
    exit 1
fi

# Export GITHUB_TOKEN for gh CLI
export GITHUB_TOKEN="$GH_TOKEN"

# Test authentication
echo "🔐 Testing GitHub authentication..."
if gh auth status 2>&1 | grep -q "Logged in to github.com"; then
    echo "✅ GitHub CLI authenticated successfully"
    gh auth status 2>&1 | grep -E "✓|account" | head -5
    exit 0
else
    echo "❌ GitHub authentication failed"
    echo ""
    echo "📝 Your GH_TOKEN appears to be invalid. Please create a new token:"
    echo ""
    echo "1. Go to: https://github.com/settings/tokens/new"
    echo "2. Set token name: 'Replit Ghost Protocol'"
    echo "3. Set expiration: 90 days (or No expiration)"
    echo "4. Select these scopes:"
    echo "   ✅ repo (Full control of private repositories)"
    echo "   ✅ workflow (Update GitHub Action workflows)"
    echo "   ✅ write:packages (Upload packages to GitHub Package Registry)"
    echo "   ✅ read:org (Read org and team membership)"
    echo "5. Click 'Generate token'"
    echo "6. COPY the token (starts with 'ghp_')"
    echo "7. Update GH_TOKEN in Replit Secrets with the NEW token"
    echo ""
    exit 1
fi
