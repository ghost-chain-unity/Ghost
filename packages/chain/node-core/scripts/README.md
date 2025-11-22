# Ghost Chain Node Core - Build Scripts

This directory contains helper scripts for building and testing the Ghost Chain blockchain node. These scripts are designed to be used both locally and in CI/CD environments (GitHub Actions).

## Available Scripts

### Individual Check Scripts

- **`cargo-check.sh`** - Run `cargo check` to verify compilation
- **`cargo-fmt.sh`** - Run `cargo fmt --check` to verify code formatting
- **`cargo-clippy.sh`** - Run `cargo clippy` to catch common mistakes and improve code
- **`cargo-build.sh`** - Build the blockchain node (debug mode locally, release in CI)
- **`cargo-test.sh`** - Run all unit and integration tests

### Combined Script

- **`all-checks.sh`** - Run all checks in sequence (fmt → clippy → check → test)

## Usage

### Running Individual Checks

```bash
# From project root
bash packages/chain/node-core/scripts/cargo-check.sh

# From node-core directory
cd packages/chain/node-core
bash scripts/cargo-check.sh
```

### Running All Checks

```bash
bash packages/chain/node-core/scripts/all-checks.sh
```

## Output Logs

All scripts save their output to `/tmp/` for easy review:

- `/tmp/cargo-check.log`
- `/tmp/cargo-fmt.log`
- `/tmp/cargo-clippy.log`
- `/tmp/cargo-build.log`
- `/tmp/cargo-test.log`

## GitHub Actions Integration

These scripts are used in the blockchain-node CI workflow (`.github/workflows/blockchain-node-ci.yml`):

### Check Job
```yaml
- name: Run cargo check
  run: bash packages/chain/node-core/scripts/cargo-check.sh

- name: Run cargo fmt
  run: bash packages/chain/node-core/scripts/cargo-fmt.sh

- name: Run cargo clippy
  run: bash packages/chain/node-core/scripts/cargo-clippy.sh
```

### Test Job
```yaml
- name: Run all tests
  run: bash packages/chain/node-core/scripts/cargo-test.sh

- name: Run custom pallet tests
  run: bash packages/chain/node-core/scripts/test-pallets.sh
```

### Build Job
The build job uses `cargo-build.sh` internally for artifact generation.

## Notes

- **Replit Environment:** Due to resource constraints, it's recommended to use GitHub Actions for full builds. These scripts can still be run locally but may take considerable time.
- **CI Environment Detection:** The build script automatically uses release mode when `CI=true` is set.
- **Exit Codes:** All scripts use `set -e` to exit on first error, making them suitable for CI pipelines.

## Troubleshooting

If you encounter build errors:

1. Check the log files in `/tmp/`
2. Ensure Rust toolchain is up to date: `rustup update stable`
3. Ensure wasm32 target is installed: `rustup target add wasm32-unknown-unknown`
4. Clean build artifacts: `cargo clean`
5. Review error messages for missing dependencies

## Development Workflow

Recommended development workflow:

1. Make code changes
2. Run `cargo-fmt.sh` to check formatting
3. Run `cargo-clippy.sh` to catch issues early
4. Run `cargo-check.sh` for fast compilation check
5. Run `cargo-test.sh` to verify functionality
6. Push to GitHub where full CI pipeline runs
