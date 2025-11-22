# Smart Contracts

Smart contracts for Ghost Protocol.

## Contracts

### chaing-token
ChainG token contract - native token for Ghost Protocol.
- **Standard:** ERC-20 / ink! (depending on chain)
- **Features:** Minting, burning, staking
- **Status:** 📋 Planned (not implemented)

### marketplace
NFT marketplace contract - trading, listing, offers.
- **Standard:** ERC-721, ERC-1155
- **Features:** Buy, sell, auction, offers
- **Status:** 📋 Planned (not implemented)

## Additional Contracts (Planned)

- **GhostBit Mining Token** - Mining rewards
- **Staking Module** - Token staking
- **Governance Voting** - DAO governance
- **NFT Hologram Contract** - 3D NFT storage
- **G3Mail Pointer Contract** - Web3 mail pointers

## Development

### Install Dependencies

```bash
# For Solidity contracts
npm install

# For ink! contracts (Rust)
cargo install cargo-contract
```

### Compile

```bash
# Hardhat (Solidity)
npx hardhat compile

# ink! (Rust)
cargo contract build
```

### Test

```bash
# Hardhat tests
npx hardhat test

# ink! tests
cargo test
```

### Deploy

```bash
# Deploy to testnet
npx hardhat deploy --network goerli

# Deploy to mainnet (after audit)
npx hardhat deploy --network mainnet
```

## Security

**MANDATORY before mainnet deployment:**
- [ ] Unit test coverage >95%
- [ ] Fuzz testing (Echidna/Foundry)
- [ ] Static analysis (Slither, Mythril)
- [ ] Third-party security audit
- [ ] Gas optimization
- [ ] Testnet validation (>30 days)

## Directory Structure

```
contracts/
├── chaing-token/
│   ├── contracts/
│   ├── test/
│   ├── scripts/
│   └── hardhat.config.js
└── marketplace/
    ├── contracts/
    ├── test/
    ├── scripts/
    └── hardhat.config.js
```

---

**Last Updated:** November 15, 2025
