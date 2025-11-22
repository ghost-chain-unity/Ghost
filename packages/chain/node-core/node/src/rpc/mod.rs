//! A collection of node-specific RPC methods.
//! Substrate provides the `sc-rpc` crate, which defines the core RPC layer
//! used by Substrate nodes. This file extends those RPC definitions with
//! capabilities that are specific to this project's runtime configuration.

#![warn(missing_docs)]

pub mod ghost_protocol;
pub mod rate_limit;
pub mod types;

use std::sync::Arc;
use std::net::IpAddr;

use jsonrpsee::RpcModule;
use sc_transaction_pool_api::TransactionPool;
use ghost_runtime::{opaque::Block, AccountId, Balance, BlockNumber, Nonce};
use sp_api::ProvideRuntimeApi;
use sp_block_builder::BlockBuilder;
use sp_blockchain::{Error as BlockChainError, HeaderBackend, HeaderMetadata};

use ghost_runtime::apis::ghost_protocol::{
    ChainGhostRuntimeApi, G3MailRuntimeApi, GhonityRuntimeApi,
};

#[allow(dead_code)]
pub use rate_limit::{RateLimitError, RateLimitInfo, RateLimiter};

/// Full client dependencies.
pub struct FullDeps<C, P> {
    /// The client instance to use.
    pub client: Arc<C>,
    /// Transaction pool instance.
    pub pool: Arc<P>,
    /// Rate limiter instance (Phase 1.1.3 JSON-RPC integration, awaiting jsonrpsee API update)
    #[allow(dead_code)]
    pub rate_limiter: RateLimiter,
}

/// Instantiate all full RPC extensions.
pub fn create_full<C, P>(
    deps: FullDeps<C, P>,
) -> Result<RpcModule<()>, Box<dyn std::error::Error + Send + Sync>>
where
    C: ProvideRuntimeApi<Block>,
    C: HeaderBackend<Block> + HeaderMetadata<Block, Error = BlockChainError> + 'static,
    C: Send + Sync + 'static,
    C::Api: substrate_frame_rpc_system::AccountNonceApi<Block, AccountId, Nonce>,
    C::Api: pallet_transaction_payment_rpc::TransactionPaymentRuntimeApi<Block, Balance>,
    C::Api: BlockBuilder<Block>,
    C::Api: ChainGhostRuntimeApi<Block, AccountId, BlockNumber>,
    C::Api: G3MailRuntimeApi<Block, AccountId, BlockNumber>,
    C::Api: GhonityRuntimeApi<Block, AccountId>,
    P: TransactionPool + 'static,
{
    use ghost_protocol::{
        ChainGhost, ChainGhostApiServer, G3Mail, G3MailApiServer, Ghonity, GhonityApiServer,
    };
    use pallet_transaction_payment_rpc::{TransactionPayment, TransactionPaymentApiServer};
    use substrate_frame_rpc_system::{System, SystemApiServer};

    let mut module = RpcModule::new(());
    let FullDeps {
        client,
        pool,
        rate_limiter: _,
    } = deps;

    module.merge(System::new(client.clone(), pool).into_rpc())?;
    module.merge(TransactionPayment::new(client.clone()).into_rpc())?;

    module.merge(ChainGhost::new(client.clone()).into_rpc())?;
    module.merge(G3Mail::new(client.clone()).into_rpc())?;
    module.merge(Ghonity::new(client.clone()).into_rpc())?;

    Ok(module)
}

// TODO: Rate limiting middleware - DEFERRED (DEFER-1.1.3-3)
// The `into_context` method is deprecated/removed in jsonrpsee 0.24.x
// Code preserved below for future integration when jsonrpsee API stabilizes
// Phase 1.1.3 JSON-RPC Integration: Rate limiting module (rate_limit.rs) fully implemented with 8 unit tests
// Awaiting jsonrpsee new middleware API. Ready for immediate integration within 2-3 hours of API release.
// See rate_limit.rs for complete implementation and DEFER-1.1.3-3 in roadmap-tasks.md for details.
/*
#[allow(dead_code)]
mod rate_limit_middleware_commented {
    use super::*;
    
    /// Apply rate limiting middleware to RPC module
    pub fn apply_rate_limit_middleware<'a>(
        module: RpcModule<()>,
        rate_limiter: RateLimiter,
    ) -> RpcModule<RateLimiterContext> {
        let context = RateLimiterContext { rate_limiter };
        module.into_context(context)
    }

    /// Context for rate limiter
    #[derive(Clone)]
    pub struct RateLimiterContext {
        /// Rate limiter instance
        pub rate_limiter: RateLimiter,
    }
}
*/

/// Helper function to check rate limit from request
#[allow(dead_code)]
pub fn check_rate_limit(
    rate_limiter: &RateLimiter,
    ip: Option<IpAddr>,
    token: Option<&str>,
) -> Result<RateLimitInfo, RateLimitError> {
    let ip = ip.unwrap_or(IpAddr::from([127, 0, 0, 1]));
    rate_limiter.check_rate_limit(ip, token)
}
