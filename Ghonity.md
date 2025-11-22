# Ghonity — Community Ecosystem (Social Graph & Discovery)

**Product Category:** Social Layer - Community & Discovery  
**Status:** Phase 3-4 Development (Planned Q3-Q4 2026)  
**Last Updated:** November 16, 2025

---

## Overview

Ghonity is Ghost Protocol's **community ecosystem** that transforms blockchain activity into social connections. It's where users **discover wallets, follow strategies, share alpha, and build reputation** through on-chain interactions. Think Twitter meets Nansen meets DeFi Llama—all in one social experience.

### Core Philosophy

**"Follow wallets, not accounts. Discover alpha, not followers."**

Ghonity shifts social focus from vanity metrics to on-chain activity:
- Follow wallets based on smart trading strategies
- Discover opportunities through community activity feed
- Build reputation through verifiable on-chain actions
- Copy-trade successful strategies transparently

---

## Product Vision

### The Problem

Web3 lacks native social infrastructure built on blockchain data:

**Social Media Issues:**
- **Web2 Platforms (Twitter, Discord):** Not crypto-native, no wallet integration
- **Vanity Metrics:** Followers/likes don't correlate with alpha
- **Information Asymmetry:** Whales hide activity, retail investors lack insights
- **No Reputation Layer:** Can't verify if someone is actually good at trading

**Existing Solutions Fall Short:**
- **Nansen/Dune:** Analytics tools (not social, technical barriers)
- **Crypto Twitter:** Text-based alpha (no wallet integration, signal-to-noise low)
- **Discord Groups:** Siloed communities (fragmented, hard to discover)

### The Ghonity Solution

Ghonity builds **social graph on top of blockchain activity**:

```
┌──────────────────────────────────────────────────────────┐
│                 GHONITY ARCHITECTURE                     │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  SOCIAL LAYER         DISCOVERY LAYER      ACTION LAYER │
│  ├─ Follow wallets    ├─ Trending         ├─ Copy-trade│
│  ├─ Activity feed     │   strategies       ├─ Share     │
│  ├─ Reputation        ├─ Alpha discovery  │   alpha     │
│  └─ Social graph      └─ Wallet search    └─ Interact   │
│                                                          │
│         "Your wallet is your social identity"           │
└──────────────────────────────────────────────────────────┘
```

---

## Core Features

### 1. Wallet Discovery & Following

**Discover Interesting Wallets:**
- **Trending Wallets:** Most active traders in last 24h/7d
- **Top Performers:** Highest PnL (profit/loss) this month
- **Strategy-Based:** Find wallets by strategy (DeFi, NFT, long-term holding)
- **Search by Address:** Look up any wallet (0x... or ENS name)

**Follow System:**
```
Follow Wallet → Activity Feed Updates → Notifications on Trades
```

**Follow Categories:**
- DeFi Whales (high-value DeFi operations)
- NFT Collectors (blue-chip NFT buyers)
- Early Adopters (first movers on new protocols)
- Gas Optimizers (L2/rollup power users)
- Smart Money (consistently profitable)

### 2. Activity Feed (The "Home" of Ghonity)

**Real-Time Transaction Stream:**
```
┌────────────────────────────────────────────┐
│  Activity Feed                             │
├────────────────────────────────────────────┤
│  🐋 vitalik.eth swapped 100 ETH → DAI      │
│     on Uniswap V3 (1 min ago)              │
│     📈 Potential market signal?            │
│                                            │
│  🎨 punk6529.eth minted Memories #5000     │
│     (5 mins ago)                           │
│     💬 "New collection looks promising"    │
│                                            │
│  💎 0x742d... staked 1000 AAVE             │
│     (10 mins ago)                          │
│     🔄 Copy trade? (1-click)               │
└────────────────────────────────────────────┘
```

**Feed Filters:**
- All Activity (global feed)
- Following (wallets you follow)
- Trending (most engagement)
- Categories (DeFi, NFT, Gaming, etc.)
- Chains (filter by blockchain)

**Engagement Actions:**
- **Like:** Signal appreciation (on-chain badge)
- **Comment:** Discuss trade (stored on G3Mail or IPFS)
- **Copy:** Replicate transaction (via ChainGhost)
- **Share:** Post to Twitter/Discord with G3Mail link

### 3. Wallet Profiles (On-Chain Identity)

**Profile Components:**
```
┌────────────────────────────────────────────┐
│  Wallet Profile: vitalik.eth               │
├────────────────────────────────────────────┤
│  📊 Stats                                  │
│    • Total Transactions: 25,431            │
│    • Chains Active: 5                      │
│    • Gas Spent: 145.5 ETH                  │
│    • First Transaction: 2015-07-30         │
│                                            │
│  🏆 Achievements                           │
│    • OG Ethereum Developer                 │
│    • Gas Whale                             │
│    • Multi-Chain Master                    │
│    • Community Builder                     │
│                                            │
│  📈 Strategy Mix                           │
│    • DeFi: 60%                             │
│    • NFT: 15%                              │
│    • L2 Usage: 25%                         │
│                                            │
│  👥 Social                                 │
│    • Followers: 1.2M                       │
│    • Following: 42                         │
│    • Reputation Score: 9.8/10              │
│                                            │
│  📜 Recent Transactions (ChainGhost)       │
│    [Transaction timeline with stories]     │
└────────────────────────────────────────────┘
```

**Profile Data Sources:**
- Transaction history (indexer)
- ENS metadata (name, avatar, bio)
- Reputation score (algorithmic + community votes)
- ChainGhost stories (narrative layer)

### 4. Reputation System

**Reputation Score (0-10):**
Calculated from:
- **Transaction Consistency:** Regular activity (not bot-like)
- **Profitability:** PnL over time (verified on-chain)
- **Community Engagement:** Likes, comments received
- **Longevity:** Account age (older = more trusted)
- **Diversity:** Multi-chain activity
- **No Exploits:** Never involved in scams/exploits

**Reputation Benefits:**
- Higher visibility in trending feeds
- Verified badge (reputation >8.0)
- Premium features access
- DAO voting weight

**Anti-Sybil Measures:**
- Minimum transaction history (>50 txs)
- Minimum gas spent (>0.1 ETH)
- Account age (>30 days)
- Unique wallet fingerprinting

### 5. Alpha Discovery

**Trending Strategies:**
```
┌────────────────────────────────────────────┐
│  Trending Strategies (Last 7 Days)         │
├────────────────────────────────────────────┤
│  1. Arbitrum Yield Farming                 │
│     • 1,250 wallets active                 │
│     • Avg APY: 15.2%                       │
│     • Top Protocol: GMX                    │
│     [Explore] [Copy]                       │
│                                            │
│  2. NFT Flipping (Pudgy Penguins)          │
│     • 850 flips in 7 days                  │
│     • Avg profit: 0.5 ETH                  │
│     • Success rate: 68%                    │
│     [Explore] [Copy]                       │
│                                            │
│  3. Base Chain Early Adoption              │
│     • 2,100 wallets bridging               │
│     • Top dApps: Aerodrome, Friend.tech    │
│     • Gas savings: 95% vs L1               │
│     [Explore] [Copy]                       │
└────────────────────────────────────────────┘
```

**Discovery Mechanisms:**
- **Whale Watching:** Track large wallets' new positions
- **Smart Money Tracking:** Follow profitable wallets' strategies
- **Early Mover Detection:** Find wallets using new protocols first
- **Pattern Recognition:** AI detects emerging trends

### 6. Copy-Trading (One-Click Strategy Replication)

**How It Works:**
```
1. User sees vitalik.eth swapped 100 ETH → DAI on Uniswap
2. Clicks "Copy Trade" button
3. Ghonity + ChainGhost:
   - Analyzes transaction parameters
   - Adjusts for user's balance (e.g., 0.1 ETH → DAI)
   - Executes via ChainGhost intent-based architecture
4. User's transaction completes
5. Story generated: "Following in the footsteps of vitalik.eth..."
```

**Copy-Trade Options:**
- **Exact Copy:** Same asset, proportional amount
- **Mirror Strategy:** Same action, different asset
- **Delayed Copy:** Wait for confirmation, then execute
- **Subscription:** Auto-copy all trades from wallet (premium)

**Risk Warnings:**
- "Past performance ≠ future results"
- Slippage warnings
- Gas cost estimates
- Liquidity checks

---

## Social Graph Architecture

### Graph Database (PostgreSQL + Edges)

**Entities:**
- **Wallets:** User nodes
- **Transactions:** Activity nodes
- **Follows:** Directed edges (A → B)
- **Engagement:** Weighted edges (likes, comments)

**Relationships:**
```sql
CREATE TABLE follows (
    follower_address VARCHAR(42),
    following_address VARCHAR(42),
    created_at TIMESTAMP,
    PRIMARY KEY (follower_address, following_address)
);

CREATE TABLE wallet_reputation (
    wallet_address VARCHAR(42) PRIMARY KEY,
    reputation_score DECIMAL(3,1),
    total_transactions INT,
    total_volume_usd DECIMAL(20,2),
    account_age_days INT,
    last_updated TIMESTAMP
);

CREATE TABLE activity_feed (
    id UUID PRIMARY KEY,
    wallet_address VARCHAR(42),
    action_type VARCHAR(50),
    blockchain VARCHAR(20),
    tx_hash VARCHAR(66),
    timestamp TIMESTAMP,
    metadata JSONB
);
```

### Real-Time Updates (WebSocket)

**Event Stream:**
```javascript
// User follows vitalik.eth
ws.on('follow', async (event) => {
  // Subscribe to vitalik.eth transactions
  const txStream = indexer.subscribe('vitalik.eth');
  
  // Push new transactions to user's feed
  txStream.on('transaction', (tx) => {
    ws.send({
      type: 'activity',
      wallet: 'vitalik.eth',
      action: tx.action,
      timestamp: tx.timestamp
    });
  });
});
```

---

## User Flows

### Flow 1: Discover & Follow Wallet

```
1. User opens Ghonity "Discover" tab
2. Sees trending wallet: vitalik.eth (100 swaps today)
3. Clicks profile to view activity
4. Sees impressive PnL: +$1.2M this month
5. Clicks "Follow" button
6. vitalik.eth's transactions now appear in user's feed
7. User gets notification: "vitalik.eth just swapped ETH → DAI"
```

### Flow 2: Copy-Trade Strategy

```
1. User sees on feed: "punk6529.eth bought Azuki #5000 for 10 ETH"
2. Clicks "Copy Trade" button
3. Ghonity opens ChainGhost with pre-filled:
   - Action: Buy Azuki
   - Amount: User's budget (e.g., 0.1 ETH)
   - Marketplace: OpenSea
4. User reviews, confirms transaction
5. NFT purchased, story generated
6. Post shared on Ghonity: "Following punk6529.eth's Azuki play"
```

### Flow 3: Engage with Community

```
1. User sees interesting trade on feed
2. Clicks "Comment" button
3. Types: "This looks like a good entry point, buying dip"
4. Comment stored on G3Mail (encrypted) or IPFS (public)
5. Other followers see comment, engage
6. Thread forms around trade discussion
7. Wallet earns engagement points → reputation boost
```

---

## Technical Architecture

### Frontend Layer (Next.js + GraphQL)

**Components:**
- `ActivityFeed.tsx`: Real-time transaction stream
- `WalletProfile.tsx`: Wallet stats and history
- `DiscoverPage.tsx`: Trending wallets and strategies
- `CopyTradeModal.tsx`: One-click trade replication
- `ReputationBadge.tsx`: Visual reputation display

**GraphQL Queries:**
```graphql
query GetActivityFeed($walletAddress: String!, $limit: Int) {
  activityFeed(walletAddress: $walletAddress, limit: $limit) {
    id
    wallet {
      address
      ensName
      reputation
    }
    action
    blockchain
    txHash
    timestamp
    metadata
  }
}
```

### Backend Layer (NestJS + GraphQL)

**Services:**
- `SocialGraphService`: Manage follows, followers, graph
- `ReputationService`: Calculate reputation scores
- `DiscoveryService`: Trending wallets, strategies
- `ActivityFeedService`: Real-time feed generation
- `NotificationService`: WebSocket push notifications

**APIs:**
- `/api/v1/social/follow`: Follow wallet
- `/api/v1/social/feed`: Get activity feed
- `/api/v1/discovery/trending`: Trending wallets
- `/api/v1/reputation/:wallet`: Reputation score

### Indexer Integration

**Real-Time Transaction Streaming:**
```typescript
// Indexer pushes all transactions to Ghonity
indexer.on('transaction', async (tx) => {
  // Check if anyone follows this wallet
  const followers = await getFollowers(tx.from);
  
  // Push to followers' feeds
  for (const follower of followers) {
    await activityFeed.add({
      follower: follower.address,
      activity: tx
    });
    
    // Send WebSocket notification
    await notificationService.send(follower.address, {
      type: 'transaction',
      wallet: tx.from,
      data: tx
    });
  }
});
```

---

## Reputation Algorithm

### Score Calculation

```python
def calculate_reputation(wallet):
    # Base factors
    transaction_count = get_transaction_count(wallet)
    account_age_days = get_account_age(wallet)
    total_volume_usd = get_total_volume(wallet)
    
    # Profitability (PnL)
    pnl = calculate_profit_loss(wallet)
    pnl_score = normalize(pnl, min=-10000, max=100000)
    
    # Community engagement
    likes_received = get_likes_count(wallet)
    comments_received = get_comments_count(wallet)
    engagement_score = (likes_received + comments_received * 2) / 100
    
    # Multi-chain activity
    chains_active = get_active_chains(wallet)
    diversity_score = min(chains_active / 5, 1.0)  # Max at 5 chains
    
    # Anti-sybil checks
    is_verified = check_verification(wallet)
    no_exploits = check_exploit_history(wallet)
    
    # Weighted combination
    reputation = (
        pnl_score * 0.3 +
        engagement_score * 0.2 +
        diversity_score * 0.15 +
        normalize(transaction_count, 0, 1000) * 0.15 +
        normalize(account_age_days, 0, 365) * 0.1 +
        normalize(total_volume_usd, 0, 1000000) * 0.1
    )
    
    # Penalties
    if not is_verified:
        reputation *= 0.8
    if not no_exploits:
        reputation *= 0.5
    
    # Scale to 0-10
    return min(reputation * 10, 10.0)
```

---

## Flywheel Integration

Ghonity completes the Ghost Protocol flywheel:

```
COMMUNITY (Ghonity) → ACTION (ChainGhost) → NARRATIVE (Story)
        ↓                      ↓                     ↓
  "We discover          "I execute             "Story shared
   opportunities"        together"              back to community"
        ↓                      ↓                     ↓
  More alpha      ←   More actions    ←   Better narratives
  discovered          generating            attracting more
                      stories               discovery
```

**Flywheel Mechanics:**
1. **Discovery on Ghonity:** User finds interesting wallet strategy
2. **Execution on ChainGhost:** User copy-trades via ChainGhost
3. **Narrative Generated:** AI creates story about the trade
4. **Story Shared to Ghonity:** Story posted to activity feed
5. **Community Engagement:** Others see, engage, discover new alpha
6. **Cycle Repeats:** More discovery → more action → more stories

---

## Differentiation from Competitors

### vs Nansen
- **Nansen:** Analytics tool (charts, dashboards, no social)
- **Ghonity:** Social platform (follow, engage, copy-trade)

### vs Crypto Twitter (CT)
- **CT:** Text-based alpha (no wallet integration, fake accounts)
- **Ghonity:** On-chain verified activity (every post is a real transaction)

### vs DeBank
- **DeBank:** Portfolio tracker (view only, no social layer)
- **Ghonity:** Social graph + portfolio + copy-trading

### vs Friend.tech
- **Friend.tech:** Speculate on influencer keys (tokenized attention)
- **Ghonity:** Follow wallets based on real trading skill (merit-based)

---

## Roadmap

### Phase 1 (Q3 2026): MVP Launch
- [ ] Basic activity feed (follow wallets, view transactions)
- [ ] Wallet profiles (stats, reputation v1)
- [ ] Follow/unfollow functionality
- [ ] Simple search (by address/ENS)

### Phase 2 (Q4 2026): Discovery & Engagement
- [ ] Trending wallets page
- [ ] Alpha discovery (strategies, patterns)
- [ ] Like/comment on transactions
- [ ] Notification system (real-time)

### Phase 3 (Q1 2027): Copy-Trading
- [ ] One-click copy-trade integration with ChainGhost
- [ ] Auto-follow (copy all trades from wallet)
- [ ] Risk warnings and slippage protection
- [ ] Copy-trade leaderboard

### Phase 4 (Q2 2027): Advanced Social
- [ ] Direct messaging via G3Mail
- [ ] Group chats (DAOs, trading groups)
- [ ] Advanced reputation system
- [ ] DAO integration (governance participation)

---

## Success Metrics

### Adoption KPIs
- **Active Users:** Monthly active Ghonity users
- **Follows:** Total follow relationships
- **Engagement Rate:** % of users engaging daily
- **Copy-Trades:** Transactions executed via copy-trade

### Social KPIs
- **Feed Activity:** Posts per day
- **Engagement:** Likes + comments per post
- **Discovery:** Wallets discovered via trending page
- **Retention:** 30-day active user retention

### Community Health
- **Reputation Distribution:** Median reputation score
- **Anti-Sybil Success:** % of flagged bots/scams
- **Content Quality:** % of high-engagement posts
- **Network Growth:** New follows per user per month

---

## Conclusion

Ghonity transforms blockchain data into social connections, making Web3 discovery **social, transparent, and actionable**. It's where the community discovers alpha, shares strategies, and builds reputation through verifiable on-chain activity.

**In Web3, your wallet is your identity. Ghonity is where that identity comes alive.**

---

**Related Products:**
- [ChainGhost.md](./ChainGhost.md) - Transaction execution & narrative
- [G3Mail.md](./G3Mail.md) - Private communication layer

**Technical Documentation:**
- [docs/arsitektur.md](./docs/arsitektur.md) - System architecture
- [docs/adr/](./docs/adr/) - Architecture decisions
- [roadmap-tasks.md](./roadmap-tasks.md) - Development roadmap

**Maintained by:** Ghost Protocol Product Team  
**Last Updated:** November 16, 2025
