# G3Mail — Ghost Web3 Mail (Decentralized Communication Product)

**Product Category:** Communication Layer - Encrypted Messaging  
**Status:** Phase 3 Development (Planned Q3 2026)  
**Last Updated:** November 16, 2025

---

## Overview

G3Mail (Ghost Web3 Mail) is Ghost Protocol's decentralized communication product that enables **encrypted, censorship-resistant messaging** with on-chain message pointers and client-side decryption. It's email for the Web3 era—private, portable, and permanent.

### Core Philosophy

**"Your messages, your keys, your control"**

G3Mail eliminates centralized control over communication by:
- Storing encrypted messages off-chain (IPFS/S3)
- Recording message pointers on-chain (immutable, verifiable)
- Enabling client-side decryption (only recipient can read)
- Making communication portable (tied to wallet, not platform)

---

## Product Vision

### The Problem

Traditional communication platforms (Gmail, Telegram, Discord) have critical flaws:

**Centralization Issues:**
- Platform controls your data (can read, censor, delete)
- Account can be banned (lose all message history)
- No true privacy (company has decryption keys)
- Platform lock-in (can't export to competitors)

**Web3 Communication Gaps:**
- Most projects use Web2 tools (Discord, Telegram)
- No native Web3-first communication layer
- Wallet-to-wallet messaging is fragmented
- ENS names underutilized for communication

### The G3Mail Solution

G3Mail provides **decentralized, encrypted communication** with blockchain guarantees:

```
┌──────────────────────────────────────────────────────────┐
│                  G3MAIL ARCHITECTURE                     │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  CLIENT SIDE              BLOCKCHAIN          OFF-CHAIN │
│  ├─ Encryption            ├─ Message         ├─ IPFS   │
│  ├─ Decryption            │   pointers       ├─ S3     │
│  ├─ Key management        ├─ Verification    └─ Arweave│
│  └─ Wallet integration    └─ Immutability              │
│                                                          │
│         "Private by design, Permanent by default"       │
└──────────────────────────────────────────────────────────┘
```

---

## Core Features

### 1. Wallet-to-Wallet Messaging

**Send/Receive Messages:**
- Address messages to wallet addresses (0x... or ENS names)
- Auto-discovery of recipient's public key
- No account creation required (use existing wallet)
- Cross-chain compatibility (any EVM wallet)

**Message Types:**
- Text messages (encrypted Markdown)
- File attachments (encrypted, IPFS-stored)
- NFT shares (embed NFT metadata)
- Transaction links (reference on-chain activity)

### 2. Client-Side Encryption (E2EE)

**Encryption Flow:**
```
1. Compose message in G3Mail UI
2. Retrieve recipient's public key from blockchain registry
3. Encrypt message with ECIES (Elliptic Curve Integrated Encryption)
4. Upload encrypted payload to IPFS/S3
5. Store message pointer on-chain (ChainG smart contract)
6. Recipient retrieves pointer, downloads payload, decrypts locally
```

**Security Guarantees:**
- End-to-end encryption (E2EE)
- Zero-knowledge (server never sees plaintext)
- Perfect forward secrecy (rotating keys)
- Client-side key management (wallet-derived keys)

### 3. On-Chain Message Pointers

**Smart Contract Storage:**
```solidity
contract G3MailPointer {
    struct Message {
        address sender;
        address recipient;
        string ipfsHash;        // CID of encrypted message
        uint256 timestamp;
        bytes32 messageHash;    // Hash for verification
    }
    
    mapping(address => Message[]) public inbox;
    mapping(address => Message[]) public sent;
}
```

**Pointer Benefits:**
- Immutable message log (can't be deleted)
- Verifiable sender (signed by wallet)
- Spam prevention (on-chain cost to send)
- Audit trail (all messages time-stamped)

### 4. Decentralized Storage

**Storage Options:**
```
Primary: IPFS (InterPlanetary File System)
  - Content-addressable storage
  - Pinning services (Pinata, Web3.Storage)
  - Redundancy via multiple nodes

Backup: S3 (Encrypted, Ghost Protocol-controlled)
  - For availability SLA
  - KMS-encrypted at rest
  - Cross-region replication

Permanent: Arweave (Optional, pay-once store-forever)
  - For critical messages
  - Immutable storage
  - Higher cost, permanent archival
```

**Retention Policy:**
- IPFS: Pinned for 2 years (renewable)
- S3: 5 years retention
- Arweave: Permanent (user-initiated)

### 5. ENS Integration

**Human-Readable Addresses:**
- Send to `vitalik.eth` instead of `0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045`
- ENS reverse resolution (display name, not address)
- Avatar and metadata from ENS records

**Contact Management:**
- Automatic ENS name lookup
- Store frequently used addresses
- Contact groups (multicast messages)

---

## User Flows

### Flow 1: Send First Message

```
1. User connects wallet to G3Mail
2. Clicks "Compose" button
3. Enters recipient: alice.eth
4. Types message: "Hey Alice, check out this NFT!"
5. Attaches NFT link or embeds metadata
6. Clicks "Send"
7. G3Mail encrypts message client-side
8. Uploads to IPFS, gets CID (QmXyz...)
9. Stores pointer on-chain (ChainG contract)
10. Recipient's inbox updates (real-time via WebSocket)
11. Alice decrypts and reads message
```

### Flow 2: Receive & Reply

```
1. Alice opens G3Mail inbox
2. Sees new message from bob.eth
3. Clicks to read (auto-decryption with wallet key)
4. Message displays: "Hey Alice, check out this NFT!"
5. Alice clicks "Reply"
6. Types response, sends (same encryption flow)
7. Bob receives reply notification
```

### Flow 3: Group Messaging

```
1. Bob creates group: "DeFi Alpha Crew"
2. Adds members: alice.eth, charlie.eth, dave.eth
3. Composes message to group
4. G3Mail encrypts for each recipient separately
5. Stores 3 on-chain pointers (one per recipient)
6. All members receive encrypted copy
7. Thread view shows all messages in group
```

---

## Technical Architecture

### Frontend Layer (Next.js + Web3 Libraries)

**Components:**
- `Inbox.tsx`: Message list with pagination
- `Compose.tsx`: Message editor with encryption
- `MessageThread.tsx`: Conversation view
- `ContactList.tsx`: Wallet address book
- `AttachmentViewer.tsx`: Encrypted file preview

**Web3 Integration:**
- `wagmi` for wallet connection
- `ethers.js` for contract interaction
- `@ensdomains/ensjs` for ENS resolution
- `ipfs-http-client` for IPFS uploads

### Backend Layer (NestJS)

**Services:**
- `MessageService`: On-chain pointer CRUD
- `IPFSService`: Upload/pin encrypted payloads
- `NotificationService`: Real-time inbox updates
- `SpamFilter`: Rate limiting and reputation

**APIs:**
- `/api/v1/messages/send`: Store message pointer
- `/api/v1/messages/inbox/:wallet`: Get inbox
- `/api/v1/messages/:id`: Retrieve message metadata
- `/api/v1/contacts/:wallet`: Contact management

### Blockchain Layer (Smart Contracts)

**Contracts:**
```solidity
// G3MailPointer.sol - On-chain message registry
// PublicKeyRegistry.sol - Store user public keys
// G3MailToken.sol - Utility token for premium features
```

**Events:**
```solidity
event MessageSent(
    address indexed sender,
    address indexed recipient,
    string ipfsHash,
    uint256 timestamp
);

event MessageRead(
    address indexed reader,
    string messageId,
    uint256 timestamp
);
```

### Encryption Layer

**ECIES (Elliptic Curve Integrated Encryption Scheme):**
```javascript
// Encryption
const recipientPublicKey = await getPublicKey(recipientAddress);
const encryptedMessage = await encrypt(recipientPublicKey, messageText);
const ipfsHash = await uploadToIPFS(encryptedMessage);

// Decryption
const encryptedPayload = await fetchFromIPFS(ipfsHash);
const decryptedMessage = await decrypt(walletPrivateKey, encryptedPayload);
```

**Key Management:**
- Public keys derived from wallet address (ECDSA)
- Private keys never leave client (wallet signature)
- Optional: Separate encryption key pair (stored in wallet)

---

## Security & Privacy

### Encryption Standards

**Algorithm:** ECIES (Elliptic Curve Integrated Encryption Scheme)
- Asymmetric encryption (public/private key pairs)
- AES-256-GCM for symmetric encryption
- SHA-256 for hashing
- Secure random number generation

**Key Rotation:**
- Users can regenerate encryption keys
- Old messages remain decryptable (archived keys)
- Forward secrecy via ephemeral keys

### Spam Prevention

**On-Chain Cost:**
- Sending message requires small gas fee (0.001 ETH)
- Prevents bulk spam (economic deterrent)
- Recipient can set minimum stake requirement

**Reputation System:**
- Track sender reputation (% of messages not marked as spam)
- Low reputation → messages go to spam folder
- Recipients can whitelist trusted senders

**Rate Limiting:**
- Max 100 messages per wallet per day
- Exponential backoff for repeat senders
- Premium users can increase limits (stake G3Mail tokens)

### Privacy Features

**Metadata Protection:**
- Message size obfuscation (padding to fixed size)
- Timestamp fuzzing (±10 minute randomness)
- IP address not logged
- No tracking pixels or read receipts (unless opted-in)

**Opt-In Read Receipts:**
- Disabled by default
- User can enable per conversation
- Signed read receipt stored on-chain (optional)

---

## Premium Features (G3Mail Token)

### Free Tier
- Send 100 messages/month
- 10 MB storage per message
- IPFS storage (2-year pinning)
- Basic spam filtering

### Premium Tier (Stake 1000 G3MAIL tokens)
- Unlimited messages
- 100 MB storage per message
- Arweave permanent storage
- Priority delivery
- Advanced spam filtering
- Custom domain (yourname@g3mail.ghost)

### Enterprise Tier (Stake 10,000 G3MAIL tokens)
- White-label G3Mail for DAOs/projects
- Custom smart contract deployment
- Dedicated IPFS pinning nodes
- SLA guarantees (99.9% uptime)
- Compliance features (audit logs, e-discovery)

---

## Differentiation from Competitors

### vs Status.im
- **Status:** Mobile-first messenger (Whisper protocol)
- **G3Mail:** Web-first email replacement (IPFS + blockchain)

### vs XMTP (Extensible Message Transport Protocol)
- **XMTP:** Protocol layer (no UI, dev-focused)
- **G3Mail:** Full product (UI + protocol + wallet integration)

### vs Orbis Club
- **Orbis:** Social messaging (public threads)
- **G3Mail:** Private email (E2EE, one-to-one)

### vs Traditional Email (Gmail)
- **Gmail:** Centralized, platform reads messages
- **G3Mail:** Decentralized, client-side encryption

---

## Flywheel Integration

G3Mail enhances the Ghost Protocol ecosystem:

```
COMMUNICATION (G3Mail) ← ACTION (ChainGhost) ← COMMUNITY (Ghonity)
        ↓                         ↓                       ↓
  "We coordinate           "I execute              "We discover
   privately"               together"               opportunities"
        ↓                         ↓                       ↓
  Private alpha      ← Shared strategies ←  Public discussions
  sharing via            coordinated via       happen on Ghonity
  G3Mail                 ChainGhost
```

**Use Cases:**
- **Alpha Sharing:** DeFi traders share private signals via G3Mail
- **DAO Coordination:** Sensitive governance discussions encrypted
- **NFT Deals:** Negotiate private sales before public listing
- **Ghonity Integration:** Ghonity users can DM via G3Mail

---

## Roadmap

### Phase 1 (Q3 2026): MVP Launch
- [ ] Wallet-to-wallet text messaging
- [ ] ECIES encryption
- [ ] IPFS storage
- [ ] On-chain pointer smart contract
- [ ] Basic web UI (inbox, compose, send)

### Phase 2 (Q4 2026): Enhanced Features
- [ ] File attachments (up to 10 MB)
- [ ] Group messaging
- [ ] ENS integration
- [ ] Contact management
- [ ] Spam filtering v1

### Phase 3 (Q1 2027): Advanced Privacy
- [ ] Perfect forward secrecy
- [ ] Metadata protection
- [ ] Tor integration (optional)
- [ ] Decentralized key recovery
- [ ] Mobile app (iOS, Android)

### Phase 4 (Q2 2027): Enterprise & Scale
- [ ] G3Mail token launch
- [ ] Premium tier features
- [ ] Custom domains
- [ ] White-label solution
- [ ] Compliance features (e-discovery)

---

## Success Metrics

### Adoption KPIs
- **Active Users:** Monthly active senders
- **Messages Sent:** Total encrypted messages
- **IPFS Storage:** Total GB stored
- **Token Staking:** G3MAIL tokens staked for premium

### Engagement KPIs
- **Reply Rate:** % of messages that get replies
- **Daily Active Users:** DAU
- **Retention:** 30-day retention rate
- **Premium Conversion:** % of users upgrading

### Technical KPIs
- **Encryption Speed:** <500ms per message
- **IPFS Upload:** <3 seconds per 1MB
- **Message Delivery:** >99% successful delivery
- **Uptime:** 99.9% availability

---

## Use Cases

### 1. Private Alpha Sharing
**Scenario:** DeFi trader wants to share trade signals with select group

**Flow:**
1. Create group "Alpha Crew" with trusted wallets
2. Send encrypted message: "Uniswap V3 ETH/USDC pool looks imbalanced"
3. Members receive, decrypt, act on alpha
4. No centralized platform can censor or read

### 2. DAO Governance
**Scenario:** DAO members discuss sensitive proposal before public vote

**Flow:**
1. Core team uses G3Mail for private discussion
2. Draft proposal, share feedback encrypted
3. Finalize proposal, publish to public forum
4. Vote on-chain (transparent), but discussion was private

### 3. NFT Negotiations
**Scenario:** Collector wants to make private offer for NFT

**Flow:**
1. Send G3Mail to NFT owner's wallet
2. "I'll offer 5 ETH for Bored Ape #1234, let's negotiate"
3. Owner replies, they negotiate price privately
4. Agree on 5.5 ETH, execute sale on ChainGhost
5. No public bid wars, no MEV bots front-running

---

## Conclusion

G3Mail brings **privacy, permanence, and portability** to Web3 communication. It's the missing piece that enables true decentralized coordination without relying on Web2 platforms.

**Web3 needs native communication infrastructure. G3Mail is that infrastructure.**

---

**Related Products:**
- [ChainGhost.md](./ChainGhost.md) - Transaction execution & narrative
- [Ghonity.md](./Ghonity.md) - Public community & discovery

**Technical Documentation:**
- [docs/arsitektur.md](./docs/arsitektur.md) - System architecture
- [docs/adr/](./docs/adr/) - Architecture decisions
- [roadmap-tasks.md](./roadmap-tasks.md) - Development roadmap

**Maintained by:** Ghost Protocol Product Team  
**Last Updated:** November 16, 2025
