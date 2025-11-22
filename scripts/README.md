# Ghost Protocol - Scripts Directory

Automation scripts for blockchain node builds, downloads, and maintenance.

## 📋 Quick Reference

| Script | Purpose | Prerequisites |
|--------|---------|---------------|
| `download-chain-binary.sh` | Download built node binary from GitHub Actions | `gh` CLI + auth |
| `trigger-and-download.sh` | Trigger build + auto-download when ready | `gh` CLI + auth + write access |
| `clean-terraform-history.sh` | Remove Terraform files from Git history | Git repo + careful consideration |

## 🚀 Quick Start

### First-Time Setup

```bash
# 1. GitHub CLI is already installed in Replit
gh --version

# 2. Authenticate with GitHub
gh auth login
# Follow prompts: GitHub.com → HTTPS → Login with browser → Paste code

# 3. Verify authentication
gh auth status
```

### Download Latest Binary

```bash
# Download latest successful build
./scripts/download-chain-binary.sh

# Binary will be saved to: bin/ghost-node
```

### Trigger New Build

```bash
# Trigger build and auto-download when ready
./scripts/trigger-and-download.sh

# This will:
# 1. Trigger GitHub Actions workflow
# 2. Wait for build to complete (~10-15 minutes)
# 3. Auto-download binary
# 4. Create symlink at bin/ghost-node
```

## 📚 Detailed Documentation

See **[docs/scripts-usage-guide.md](../docs/scripts-usage-guide.md)** for:
- Complete usage examples
- Troubleshooting guide
- Error solutions
- Manual alternatives
- Security notes

## ⚠️ Common Issues

### "GitHub CLI not authenticated"
```bash
gh auth login
```

### "Failed to download artifact"
Build might still be running. Check status:
```bash
gh run list --workflow=blockchain-node-ci.yml
```

### "Binary might not be functional"
This is usually a false warning. Check:
```bash
file bin/ghost-node  # Should show "ELF 64-bit"
./bin/ghost-node --version
```

## 🔧 Environment Notes

### Replit
- ✅ GitHub CLI pre-installed
- ❌ Authentication required (run `gh auth login` once)
- 💡 Tip: Use manual download from GitHub Actions UI as alternative

### Local Development
- Install `gh` CLI first
- Authenticate once per machine
- Scripts work seamlessly after setup

## 🆘 Need Help?

1. **Quick fixes**: See common issues above
2. **Detailed guide**: Read `docs/scripts-usage-guide.md`
3. **Manual download**: Use GitHub Actions UI → Artifacts
4. **Build guide**: See `docs/blockchain-node-build-guide.md`

## 📝 Script Details

### download-chain-binary.sh

**What it does:**
- Finds latest successful CI run (or uses specific run ID)
- Downloads Linux AMD64 binary artifact
- Verifies binary integrity (optional)
- Creates symlink for easy access
- Shows usage examples

**Options:**
```bash
./scripts/download-chain-binary.sh               # Latest build
./scripts/download-chain-binary.sh 12345678      # Specific run
./scripts/download-chain-binary.sh --verify      # With checksum
./scripts/download-chain-binary.sh 12345678 --verify
```

### trigger-and-download.sh

**What it does:**
- Triggers `blockchain-node-ci.yml` workflow
- Waits for workflow to start
- Automatically downloads binary when build completes
- Handles in-progress builds gracefully

**Usage:**
```bash
./scripts/trigger-and-download.sh
```

### clean-terraform-history.sh

**⚠️ DANGEROUS - Rewrites Git history!**

Only use if you accidentally committed large `.terraform` folders.

**What it does:**
- Removes `.terraform/` directories from all Git history
- Removes `.tfstate` files from history
- Reduces repository size
- **Requires force-push and team coordination**

**Usage:**
```bash
./scripts/clean-terraform-history.sh
# Type 'yes' to confirm
```

## 🔐 Security

- Scripts never expose credentials
- GitHub CLI handles authentication securely
- Artifacts downloaded over HTTPS
- Optional SHA256 verification available
- No arbitrary code execution

## 🤝 Contributing

When modifying scripts:
1. Test syntax: `bash -n script.sh`
2. Test execution in safe environment
3. Update this README
4. Update `docs/scripts-usage-guide.md`
5. Add error handling for edge cases
