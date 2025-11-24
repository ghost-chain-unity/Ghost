//! A collection of node-specific RPC methods.
//! Substrate provides the `sc-rpc` crate, which defines the core RPC layer
//! used by Substrate nodes. This file extends those RPC definitions with
//! capabilities that are specific to this project's runtime configuration.

#![warn(missing_docs)]

pub mod frontier;
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
pub struct FullDeps<C, P, B> {
    /// The client instance to use.
    pub client: Arc<C>,
    /// Transaction pool instance.
    pub pool: Arc<P>,
    /// Rate limiter instance (Phase 1.1.3 JSON-RPC integration, awaiting jsonrpsee API update)
    #[allow(dead_code)]
    pub rate_limiter: RateLimiter,
    /// Frontier backend for Ethereum compatibility
    pub frontier_backend: Arc<fc_db::Backend<Block, C>>,
    /// Storage override handle for EVM
    pub overrides: Arc<fc_rpc::OverrideHandle<Block>>,
    /// Filter pool for eth_newFilter, eth_getFilterChanges
    pub filter_pool: Option<Arc<fc_rpc::EthFilterApi<Block, C>>>,
    /// Fee history cache
    pub fee_history_cache: fc_rpc::FeeHistoryCache,
    /// Backend type marker
    pub _backend: std::marker::PhantomData<B>,
}

/// Instantiate all full RPC extensions.
pub fn create_full<C, P, B>(
    deps: FullDeps<C, P, B>,
) -> Result<RpcModule<()>, Box<dyn std::error::Error + Send + Sync>>
where
    C: ProvideRuntimeApi<Block>,
    C: HeaderBackend<Block> + HeaderMetadata<Block, Error = BlockChainError> + 'static,
    C: sc_client_api::BlockBackend<Block> + sc_client_api::StorageProvider<Block, B> + 'static,
    C: Send + Sync + 'static,
    C::Api: substrate_frame_rpc_system::AccountNonceApi<Block, AccountId, Nonce>,
    C::Api: pallet_transaction_payment_rpc::TransactionPaymentRuntimeApi<Block, Balance>,
    C::Api: BlockBuilder<Block>,
    C::Api: ChainGhostRuntimeApi<Block, AccountId, BlockNumber>,
    C::Api: G3MailRuntimeApi<Block, AccountId, BlockNumber>,
    C::Api: GhonityRuntimeApi<Block, AccountId>,
    C::Api: fp_rpc::EthereumRuntimeRPCApi<Block>,
    C::Api: fp_rpc::ConvertTransactionRuntimeApi<Block>,
    P: TransactionPool + 'static,
    B: sc_client_api::Backend<Block> + 'static,
    B::State: sc_client_api::StateBackend<sp_runtime::traits::HashingFor<Block>>,
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
        frontier_backend,
        overrides,
        filter_pool,
        fee_history_cache,
        _backend,
    } = deps;

    // Substrate RPC methods
    module.merge(System::new(client.clone(), pool.clone()).into_rpc())?;
    module.merge(TransactionPayment::new(client.clone()).into_rpc())?;

    // Ghost Protocol custom RPC methods
    module.merge(ChainGhost::new(client.clone()).into_rpc())?;
    module.merge(G3Mail::new(client.clone()).into_rpc())?;
    module.merge(Ghonity::new(client.clone()).into_rpc())?;

    // Frontier Ethereum RPC methods
    let frontier_deps = frontier::FrontierRpcDeps {
        client: client.clone(),
        pool: pool.clone(),
        backend: frontier_backend.clone(),
        overrides: overrides.clone(),
        filter_pool: filter_pool.clone(),
        fee_history_cache: fee_history_cache.clone(),
    };

    module.merge(frontier::create_frontier_rpc(frontier_deps)?)?;

    Ok(module)
}

/// Apply rate limiting to RPC module (jsonrpsee 0.26+ middleware)
/// 
/// Note: Rate limiting middleware is available via RpcServiceBuilder layer_fn at server startup.
/// See service.rs for integration point.
#[allow(dead_code)]
pub fn apply_rate_limit_info_headers(
    rate_limiter: &RateLimiter,
    ip: Option<IpAddr>,
) -> Result<(), RateLimitError> {
    check_rate_limit(rate_limiter, ip, None).map(|_| ())
}

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
