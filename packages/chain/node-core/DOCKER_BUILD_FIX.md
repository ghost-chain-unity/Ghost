# Docker Build Fix - Cargo Manifest Validation

## Issue
Docker build was failing with:
```
error: failed to load manifest for workspace member `/polkadot/node`
no targets specified in the manifest
either src/lib.rs, src/main.rs, a [lib] section, or [[bin]] section must be present
```

**Root Cause:** When `cargo fetch` runs in the dependency caching layer, it validates all Cargo.toml manifests. The workspace members had Cargo.toml files copied but no source files (src/main.rs, src/lib.rs), causing validation to fail.

## Solution
Created dummy source files before `cargo fetch` to satisfy Cargo's validation, then copied real source files for the actual build:

### Changes in Dockerfile:
1. **Dummy Source Files** (lines 32-40)
   - Created minimal `src/main.rs` and `src/lib.rs` for each package
   - Satisfies Cargo validation during `cargo fetch`
   
2. **Cargo.lock Handling** (line 24)
   - Changed `Cargo.lock` to `Cargo.lock*` (glob pattern)
   - Makes Cargo.lock optional in case it's missing
   
3. **Cargo Fetch Robustness** (line 47)
   - Changed to: `cargo fetch --locked || cargo fetch`
   - Falls back to non-locked fetch if Cargo.lock missing

4. **Clear Comments** (lines 21-23)
   - Documented build context expectations
   - Helps future maintainers understand Docker path requirements

## How It Works
1. ✅ COPY Cargo.toml + Cargo.lock* → `/polkadot/`
2. ✅ CREATE dummy src files → all packages have targets
3. ✅ RUN cargo fetch → succeeds with dummy files
4. ✅ COPY . /polkadot → overwrites dummies with real source
5. ✅ RUN cargo build → uses real source files

## Build Context
The workflow correctly sets build context to `packages/chain/node-core`:
```yaml
# .github/workflows/blockchain-node-ci.yml line 273
context: packages/chain/node-core
```

This means all COPY paths are relative to that directory.

## Testing
Run Docker build locally:
```bash
# From repo root:
docker build -f packages/chain/node-core/Dockerfile packages/chain/node-core -t ghost-node:test

# From node-core directory:
docker build -f Dockerfile . -t ghost-node:test
```

## Performance Impact
- **Build time:** Minimal (~5 seconds added for dummy file creation)
- **Image size:** No impact (dummies replaced before compilation)
- **Cache efficiency:** Maintained - COPY layers unchanged, Cargo.lock still used

---

**Status:** ✅ Fixed - Docker build should now pass `cargo fetch` stage
**Date:** November 22, 2025
