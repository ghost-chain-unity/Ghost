# Ghost Protocol - Scripts Usage Guide

## Overview

This guide explains how to use the automation scripts in the `scripts/` directory.

## Available Scripts

### 1. `download-chain-binary.sh`
Downloads the latest blockchain node binary from GitHub Actions artifacts.

**Prerequisites:**
- GitHub CLI (`gh`) installed ✅ (already installed)
- GitHub authentication configured
- Access to the repository

**Usage:**
```bash
# Download latest successful build
./scripts/download-chain-binary.sh

# Download specific run by ID
./scripts/download-chain-binary.sh 12345678

# Download with checksum verification
./scripts/download-chain-binary.sh --verify
./scripts/download-chain-binary.sh 12345678 --verify
```

**First-time Setup:**
```bash
# Authenticate with GitHub
gh auth login

# Follow the prompts:
# 1. Select "GitHub.com"
# 2. Select "HTTPS"
# 3. Select "Login with a web browser"
# 4. Copy the one-time code
# 5. Press Enter to open browser
# 6. Paste the code and authorize
```

### 2. `trigger-and-download.sh`
One-click script that triggers a new build and automatically downloads it when ready.

**Prerequisites:**
- Same as `download-chain-binary.sh`
- Write access to trigger GitHub Actions

**Usage:**
```bash
./scripts/trigger-and-download.sh
```

**What it does:**
1. Triggers the `blockchain-node-ci.yml` workflow
2. Waits 60 seconds for workflow to start
3. Automatically downloads binary when build completes
4. Creates symlink at `bin/ghost-node`

### 3. `clean-terraform-history.sh`
Removes Terraform files from Git history (advanced use only).

**⚠️ WARNING:** This rewrites Git history! Only use if you accidentally committed large `.terraform` folders.

**Usage:**
```bash
./scripts/clean-terraform-history.sh
```

## Common Issues & Solutions

### Issue: "GitHub CLI is not authenticated"
**Solution:**
```bash
gh auth login
```
Follow the interactive prompts to authenticate.

### Issue: "GitHub CLI is not installed"
**Solution:**
Already installed in this environment. If running locally:
```bash
# macOS
brew install gh

# Linux (Debian/Ubuntu)
sudo apt install gh

# Windows
winget install --id GitHub.cli
```

### Issue: "Failed to download artifact"
**Possible causes:**
1. Build hasn't completed yet - wait a few minutes
2. Build failed - check GitHub Actions logs
3. Artifact name mismatch - check available artifacts

**Debug:**
```bash
# Check latest workflow runs
gh run list --workflow=blockchain-node-ci.yml --limit=5

# View specific run
gh run view RUN_ID

# Watch a running workflow
gh run watch RUN_ID
```

### Issue: "Binary might not be functional"
This warning appears when testing the binary. It's usually safe to ignore if:
- File type shows "ELF 64-bit LSB executable"
- You're on a compatible Linux x86_64 system

## Manual Alternative

If scripts don't work, you can download binaries manually:

1. Go to GitHub Actions tab in repository
2. Click on latest successful "Blockchain Node CI" run
3. Scroll to "Artifacts" section
4. Download `ghost-node-linux-amd64` (or your platform)
5. Extract and make executable:
   ```bash
   mkdir -p bin
   mv ghost-node-linux-amd64 bin/ghost-node
   chmod +x bin/ghost-node
   ```

## Environment-Specific Notes

### Replit Environment
- GitHub CLI is pre-installed
- Authentication persists across sessions
- Binary artifacts are cached in `bin/` directory
- Recommended: Use manual download from GitHub Actions UI

### Local Development
- Install GitHub CLI first
- Authenticate once per machine
- Scripts work seamlessly after setup

## Next Steps

After downloading binary successfully:

```bash
# Test the binary
./bin/ghost-node --version

# Run development node
./bin/ghost-node --dev --tmp

# Run with persistent data
./bin/ghost-node --dev --base-path ./testnet-data

# See full blockchain guide
cat docs/blockchain-node-build-guide.md
```

## Troubleshooting

### Check GitHub CLI Status
```bash
gh auth status
```

### Check Workflow Status
```bash
gh run list --workflow=blockchain-node-ci.yml
```

### View Workflow Logs
```bash
gh run view RUN_ID --log
```

### Re-authenticate
```bash
gh auth logout
gh auth login
```

## Security Notes

- Scripts never expose sensitive credentials
- Authentication token is stored securely by GitHub CLI
- Artifacts are downloaded over HTTPS
- Optional SHA256 checksum verification available

## Support

For issues with:
- **Scripts**: Check this guide and GitHub CLI docs
- **Builds**: Check GitHub Actions workflow logs
- **Binary**: See `docs/blockchain-node-build-guide.md`
