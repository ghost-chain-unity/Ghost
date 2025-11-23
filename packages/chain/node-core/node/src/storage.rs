//! Ghost Protocol Storage Module
//!
//! Manages both on-chain (RocksDB via Substrate) and off-chain (DuckDB/LMDB) storage.
//!
//! # Architecture
//!
//! ## On-Chain Storage (RocksDB)
//! - **Provided by:** Substrate framework (sc_service)
//! - **Purpose:** Persistent blockchain state storage
//! - **Key-Value Format:** Trie-based (Blake2 hashing)
//! - **Use Cases:**
//!   - Block headers and finality justifications
//!   - Account balances and nonces
//!   - Intent execution state (pallet-chainghost)
//!   - Messaging state (pallet-g3mail)
//!   - Social graph data (pallet-ghonity)
//! - **Configuration:** Set via `config.database` in service.rs (default: RocksDB)
//!
//! ## Off-Chain Storage (Event Indexing)
//! - **Purpose:** High-performance event indexing and analytics
//! - **Storage Backends:**
//!   - DuckDB: OLAP queries, analytics, time-series
//!   - LMDB: Memory-mapped B+ trees, fast lookups
//!   - PostgreSQL: (future) Full-text search, complex joins
//!
//! # Usage
//!
//! ## On-Chain Storage Access
//! On-chain storage is automatically managed by Substrate's Backend API:
//!
//! ```ignore
//! // In a pallet:
//! #[pallet::storage]
//! pub type Intents<T: Config> = StorageDoubleMap<_, Blake2_128Concat, T::AccountId, /, /, Intent>;
//! ```
//!
//! ## Off-Chain Storage
//! Accessed via the OffchainWorker trait:
//!
//! ```ignore
//! // In offchain-worker tasks (Phase 1.2):
//! let db = offchain::storage::DatabaseBackend::connect(config)?;
//! db.index_event(event)?;
//! ```
//!
//! # Storage Lifecycle
//!
//! 1. **Initialization** (via service.rs)
//!    - RocksDB opened by Substrate via sc_service::new_full_parts
//!    - Offchain DB initialized via backend.offchain_storage()
//!
//! 2. **Block Processing**
//!    - On-chain events written to RocksDB (atomic)
//!    - Offchain indexing queued (async)
//!
//! 3. **Event Indexing** (off-chain worker)
//!    - Events retrieved from Offchain DB
//!    - Indexed in DuckDB/LMDB for fast queries
//!    - Used by AI Engine for story generation
//!
//! 4. **Finalization**
//!    - State commits to persistent RocksDB
//!    - Finality guarantees (via GRANDPA)
//!
//! # Performance Characteristics
//!
//! | Storage Type | Latency | Throughput | Use Case |
//! |---|---|---|---|
//! | RocksDB (On-chain) | ~1-5ms | 10k-100k ops/sec | State transitions |
//! | DuckDB (OLAP) | ~10-100ms | 100k ops/sec+ | Analytics, aggregations |
//! | LMDB (In-memory) | <1ms | 1M+ ops/sec | Hot lookups |
//!
//! # Future Enhancements
//!
//! - [ ] DuckDB integration for event analytics (Phase 1.2)
//! - [ ] LMDB option for in-memory event cache (Phase 1.2)
//! - [ ] PostgreSQL for full-text search (Phase 2)
//! - [ ] Storage metrics and monitoring (Phase 3)

use std::path::PathBuf;

/// Storage configuration for Ghost Protocol node
#[derive(Debug, Clone)]
pub struct StorageConfig {
    /// Path to RocksDB database (on-chain state)
    pub rocksdb_path: PathBuf,

    /// Optional path to DuckDB event index
    pub event_index_path: Option<PathBuf>,

    /// Maximum off-chain storage size (MB)
    pub max_offchain_size: u32,

    /// Enable event indexing in DuckDB
    pub enable_event_indexing: bool,
}

impl StorageConfig {
    /// Creates default storage config for testnet
    pub fn default_for_testnet(base_path: &std::path::Path) -> Self {
        let chains_path = base_path.join("chains").join("local_testnet");
        
        Self {
            rocksdb_path: chains_path.join("db").join("full"),
            event_index_path: Some(chains_path.join("event_index")),
            max_offchain_size: 100,
            enable_event_indexing: true,
        }
    }

    /// Creates default storage config for production
    pub fn default_for_production(base_path: &std::path::Path) -> Self {
        let chains_path = base_path.join("chains").join("main");
        
        Self {
            rocksdb_path: chains_path.join("db").join("full"),
            event_index_path: Some(chains_path.join("event_index")),
            max_offchain_size: 1000,
            enable_event_indexing: true,
        }
    }
}

/// Storage backend abstraction (for future extensibility)
#[allow(dead_code, clippy::upper_case_acronyms)]
pub enum StorageBackend {
    /// RocksDB (on-chain state) - automatically managed by Substrate
    RocksDB,
    /// DuckDB (off-chain event indexing)
    DuckDB,
    /// LMDB (memory-mapped event cache)
    LMDB,
}

impl std::fmt::Display for StorageBackend {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            StorageBackend::RocksDB => write!(f, "RocksDB (on-chain state)"),
            StorageBackend::DuckDB => write!(f, "DuckDB (event indexing)"),
            StorageBackend::LMDB => write!(f, "LMDB (in-memory cache)"),
        }
    }
}

/// Storage initialization utilities
pub mod init {
    use super::*;

    /// Ensures all required storage directories exist
    pub fn ensure_directories(config: &StorageConfig) -> std::io::Result<()> {
        // RocksDB path created by Substrate automatically, but we ensure parent exists
        if let Some(parent) = config.rocksdb_path.parent() {
            std::fs::create_dir_all(parent)?;
        }

        // Event index path
        if let Some(event_path) = &config.event_index_path {
            std::fs::create_dir_all(event_path)?;
        }

        Ok(())
    }

    /// Prints storage configuration summary
    pub fn print_summary(config: &StorageConfig) {
        eprintln!("━━━━ Storage Configuration ━━━━");
        eprintln!("On-Chain Storage (RocksDB):");
        eprintln!("  Path: {}", config.rocksdb_path.display());
        
        if let Some(event_path) = &config.event_index_path {
            eprintln!("Event Indexing (Off-Chain):");
            eprintln!("  Path: {}", event_path.display());
            eprintln!("  Max Size: {} MB", config.max_offchain_size);
            eprintln!("  Enabled: {}", config.enable_event_indexing);
        }
        eprintln!("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    }
}

/// Storage statistics and monitoring
#[derive(Debug, Clone, Default)]
#[allow(dead_code)]
pub struct StorageStats {
    /// Total blocks processed
    pub blocks_processed: u64,
    /// Total on-chain state writes
    pub state_writes: u64,
    /// Total off-chain events indexed
    pub events_indexed: u64,
    /// Current RocksDB size (MB)
    pub rocksdb_size_mb: u64,
    /// Current event index size (MB)
    pub event_index_size_mb: u64,
}

impl std::fmt::Display for StorageStats {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "StorageStats {{ blocks: {}, writes: {}, events: {}, db: {}MB, index: {}MB }}",
            self.blocks_processed,
            self.state_writes,
            self.events_indexed,
            self.rocksdb_size_mb,
            self.event_index_size_mb
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn storage_config_testnet() {
        let base = PathBuf::from("/tmp/test");
        let config = StorageConfig::default_for_testnet(&base);
        
        assert!(config.enable_event_indexing);
        assert_eq!(config.max_offchain_size, 100);
        assert!(config.event_index_path.is_some());
    }

    #[test]
    fn storage_config_production() {
        let base = PathBuf::from("/tmp/test");
        let config = StorageConfig::default_for_production(&base);
        
        assert!(config.enable_event_indexing);
        assert_eq!(config.max_offchain_size, 1000);
        assert!(config.event_index_path.is_some());
    }

    #[test]
    fn storage_backend_display() {
        assert_eq!(
            StorageBackend::RocksDB.to_string(),
            "RocksDB (on-chain state)"
        );
        assert_eq!(
            StorageBackend::DuckDB.to_string(),
            "DuckDB (event indexing)"
        );
        assert_eq!(
            StorageBackend::LMDB.to_string(),
            "LMDB (in-memory cache)"
        );
    }

    #[test]
    fn storage_stats_display() {
        let stats = StorageStats {
            blocks_processed: 100,
            state_writes: 500,
            events_indexed: 1000,
            rocksdb_size_mb: 50,
            event_index_size_mb: 20,
        };
        
        let display = stats.to_string();
        assert!(display.contains("blocks: 100"));
        assert!(display.contains("writes: 500"));
        assert!(display.contains("events: 1000"));
    }
}
