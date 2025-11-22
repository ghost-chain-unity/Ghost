# DevContainer Testing Guide

This guide helps you test the DevContainers in GitHub Codespaces to ensure no rebuild loops occur.

## 🎯 Testing Objectives

- Verify containers start without errors
- Ensure setup scripts run idempotently (no re-downloads on rebuild)
- Confirm all tools are available after setup
- Validate cache volumes work correctly

## 📋 Prerequisites

- Access to GitHub Codespaces
- Repository pushed to GitHub
- DevContainer configurations in place

## 🧪 Testing Procedure

### 1. Test Root Development Container

1. Open repository in GitHub Codespaces
2. Select **"Ghost Protocol Development"** configuration
3. Wait for container to build and start
4. Verify setup:
   ```bash
   node --version
   pnpm --version
   rustc --version
   docker --version
   ```

5. **Rebuild Container Test:**
   - Press `Cmd/Ctrl + Shift + P`
   - Select "Codespaces: Rebuild Container"
   - ✅ **Expected:** Should rebuild quickly (~30-60s) without re-downloading Node/Rust
   - ❌ **Issue:** If takes >5 minutes, DevContainer features are being reinstalled

### 2. Test Smart Contracts Container

1. Open repository in GitHub Codespaces
2. Select **"Ghost Protocol - Smart Contracts"** configuration
3. Wait for container to build and setup script to complete
4. Verify setup:
   ```bash
   node --version
   pnpm --version
   python3 --version
   slither --version
   solc --version
   forge --version
   cast --version
   anvil --version
   ```

5. **Foundry Cache Test:**
   ```bash
   # Check Foundry is mounted in volume
   ls -la ~/.foundry/bin/
   
   # Should show: forge, cast, anvil, chisel
   ```

6. **Rebuild Container Test:**
   - Press `Cmd/Ctrl + Shift + P`
   - Select "Codespaces: Rebuild Container"
   - ✅ **Expected:** Foundry should NOT be re-downloaded (cached in volume)
   - ❌ **Issue:** If Foundry downloads again (~5-10 minutes), volume mount failed

### 3. Test Blockchain Node Container

1. Open repository in GitHub Codespaces
2. Select **"Ghost Protocol - Blockchain Node"** configuration
3. Wait for container to build and setup script to complete
4. Verify setup:
   ```bash
   rustc --version
   cargo --version
   rustup target list --installed | grep wasm32
   protoc --version
   ```

5. **Cargo Cache Test:**
   ```bash
   # Check cargo registry is mounted
   ls -la /usr/local/cargo/registry/
   ls -la /usr/local/cargo/git/
   
   # Build a small test (should use cache)
   cd packages/chain/node-core
   cargo check
   ```

6. **Rebuild Container Test:**
   - Press `Cmd/Ctrl + Shift + P`
   - Select "Codespaces: Rebuild Container"
   - ✅ **Expected:** Cargo dependencies should be cached, rebuild fast
   - ❌ **Issue:** If cargo re-downloads dependencies, cache mount failed

## 🐛 Common Issues & Solutions

### Issue: Container Rebuilds Take >10 Minutes

**Cause:** DevContainer features are being reinstalled on every rebuild

**Solution:**
- Verify `docker-compose.devcontainer.yml` is being used
- Check service name matches in `devcontainer.json`
- Ensure volumes are mounted correctly

### Issue: Foundry Not Found After Rebuild

**Cause:** Foundry installation failed or volume mount incorrect

**Solution:**
1. Check logs: `cat ~/.foundry-install.log` (if exists)
2. Manually install: `curl -L https://foundry.paradigm.xyz | bash && foundryup`
3. Verify volume mount: `docker volume ls | grep foundry`

### Issue: Cargo Keeps Re-downloading Dependencies

**Cause:** Cargo cache volume not mounted correctly

**Solution:**
1. Check `CARGO_HOME` environment variable: `echo $CARGO_HOME`
2. Should be `/usr/local/cargo`
3. Verify volume: `docker volume ls | grep cargo`

### Issue: Setup Script Hangs on Network Download

**Cause:** Network timeout in GitHub Codespaces

**Solution:**
- Setup scripts have retry logic with extended timeouts
- Wait up to 15 minutes for first build
- If still hangs, check GitHub Codespaces network status
- Try manual installation as fallback

## ✅ Success Criteria

All three containers should:
1. ✅ Build successfully on first startup
2. ✅ Complete setup scripts without errors
3. ✅ All tools available and functional
4. ✅ Rebuild in <2 minutes (using cached volumes)
5. ✅ No re-downloads on rebuild

## 📊 Rebuild Time Benchmarks

| Container | First Build | Rebuild (Cached) |
|-----------|-------------|------------------|
| Development | 3-5 min | 30-60 sec |
| Smart Contracts | 10-15 min | 30-90 sec |
| Blockchain Node | 5-8 min | 30-60 sec |

**Note:** First build times include downloading Node.js, Rust, Python, Foundry, etc.
Rebuild times should be fast because tools are cached in Docker volumes.

## 🔍 Debugging Commands

```bash
# Check Docker volumes
docker volume ls

# Inspect volume
docker volume inspect ghost-foundry-bin
docker volume inspect ghost-cargo-registry

# Check service status
docker-compose -f .devcontainer/docker-compose.devcontainer.yml ps

# View service logs
docker-compose -f .devcontainer/docker-compose.devcontainer.yml logs

# Check mounted volumes in running container
df -h | grep workspace
mount | grep volume
```

## 📝 Reporting Issues

If you encounter rebuild loops or issues:

1. Document the issue:
   - Which container (Development/Contracts/Blockchain)
   - Error messages (screenshot or copy-paste)
   - Rebuild time observed
   - Output of `docker volume ls`

2. Check logs:
   ```bash
   # Setup script logs
   cat ~/.foundry-install.log
   cat ~/.protoc-install.log
   
   # Container logs
   docker-compose logs
   ```

3. Create issue with:
   - Issue description
   - Logs and error messages
   - Steps to reproduce
   - DevContainer configuration used

## 🚀 Next Steps After Successful Testing

Once all containers pass testing:
1. ✅ Mark FIX-5 as completed in task list
2. ✅ Document any issues found
3. ✅ Update this guide with new findings
4. ✅ Proceed with development workflow
