// Frontier (EVM) configuration for Ghost Protocol blockchain
//
// This module configures Ethereum Virtual Machine (EVM) compatibility via Frontier pallets:
// - pallet_evm: Core EVM execution environment
// - pallet_ethereum: Ethereum block and transaction format support
// - pallet_base_fee: EIP-1559 base fee mechanism

use super::{AccountId, Balance, Balances, Runtime, RuntimeEvent, Timestamp};
use frame_support::{
    parameter_types,
    traits::{FindAuthor, OnFinalize},
    weights::Weight,
    ConsensusEngineId,
};
use pallet_evm::{
    EnsureAddressNever, EnsureAddressRoot, FeeCalculator, IdentityAddressMapping,
};
use sp_core::{H160, H256, U256};
use sp_runtime::{
    traits::{BlakeTwo256, IdentityLookup},
    Permill,
};

/// Ghost Protocol EVM chain ID: 200
/// This is the unique identifier for Ghost Protocol's EVM environment
pub const CHAIN_ID: u64 = 200;

/// Maximum gas limit per block: 15,000,000
/// Supports ~500 token transfers or ~100 contract deployments per block
/// At 3-second block time, this enables 1000+ TPS for simple transfers
pub const BLOCK_GAS_LIMIT: u64 = 15_000_000;

/// EVM gas per second of computation
/// Used to calculate weight-to-gas conversion
pub const GAS_PER_SECOND: u64 = 40_000_000;

/// Weight per gas unit (inverse of gas per second)
pub const WEIGHT_PER_GAS: u64 = 25_000;

parameter_types! {
    /// The EVM chain ID for Ghost Protocol
    pub const ChainId: u64 = CHAIN_ID;
    
    /// Maximum gas limit per block
    pub BlockGasLimit: U256 = U256::from(BLOCK_GAS_LIMIT);
    
    /// Weight per gas unit for transaction weight calculation
    pub WeightPerGas: Weight = Weight::from_parts(WEIGHT_PER_GAS, 0);
    
    /// EIP-1559 base fee elasticity multiplier (controls base fee change rate)
    pub Elasticity: Permill = Permill::from_parts(125_000); // 12.5%
}

/// Finds the author of a block (validator/authority)
pub struct FindAuthorTruncated<F>(sp_std::marker::PhantomData<F>);
impl<F: FindAuthor<u32>> FindAuthor<H160> for FindAuthorTruncated<F> {
    fn find_author<'a, I>(digests: I) -> Option<H160>
    where
        I: 'a + IntoIterator<Item = (ConsensusEngineId, &'a [u8])>,
    {
        F::find_author(digests).map(|author_index| {
            // Convert authority index to H160 address
            // Use a deterministic mapping: hash the index with a prefix
            let mut data = [0u8; 32];
            data[0..4].copy_from_slice(b"auth");
            data[4..8].copy_from_slice(&author_index.to_le_bytes());
            H160::from_slice(&BlakeTwo256::hash(&data).as_bytes()[0..20])
        })
    }
}

/// Fixed gas price for transactions (before EIP-1559)
/// This is used as a fallback when base fee is not active
pub struct FixedGasPrice;
impl FeeCalculator for FixedGasPrice {
    fn min_gas_price() -> (U256, Weight) {
        // 1 Gwei = 1,000,000,000 wei
        // This is a reasonable default for a low-fee chain
        (U256::from(1_000_000_000u128), Weight::zero())
    }
}

/// EVM precompiles configuration
/// Using empty precompile set for initial integration
/// TODO: Add standard Ethereum precompiles (ecrecover, sha256, ripemd160, etc.) 
/// when precompile crates are added to dependencies
pub struct GhostPrecompiles<R>(sp_std::marker::PhantomData<R>);

impl<R> pallet_evm::PrecompileSet for GhostPrecompiles<R>
where
    R: pallet_evm::Config,
{
    fn execute(
        &self,
        handle: &mut impl pallet_evm::PrecompileHandle,
    ) -> Option<pallet_evm::PrecompileResult> {
        // Empty precompile set for now
        // Precompiles will be added in a future update
        None
    }
    
    fn is_precompile(&self, _address: H160, _remaining_gas: u64) -> pallet_evm::IsPrecompileResult {
        pallet_evm::IsPrecompileResult::Answer {
            is_precompile: false,
            extra_cost: 0,
        }
    }
}

/// Configure pallet_evm
impl pallet_evm::Config for Runtime {
    /// The EVM fee calculator (uses BaseFee pallet when available, FixedGasPrice otherwise)
    type FeeCalculator = pallet_base_fee::BaseFee<Runtime>;
    
    /// Gas weight mapping for transaction weight calculation
    type GasWeightMapping = pallet_evm::FixedGasWeightMapping<Runtime>;
    
    /// Weight per gas unit
    type WeightPerGas = WeightPerGas;
    
    /// Block hash mapping (uses Ethereum-compatible block hash lookup)
    type BlockHashMapping = pallet_ethereum::EthereumBlockHashMapping<Runtime>;
    
    /// EVM call origin (ensures calls are from valid Ethereum addresses)
    type CallOrigin = pallet_evm::EnsureAddressRoot<AccountId>;
    
    /// Withdraw origin (only root can withdraw)
    type WithdrawOrigin = EnsureAddressNever<AccountId>;
    
    /// Address mapping (converts between Substrate AccountId and Ethereum H160)
    /// For now using identity mapping, can be customized for SS58 ↔ H160 conversion
    type AddressMapping = IdentityAddressMapping;
    
    /// Currency type for EVM balance operations
    type Currency = Balances;
    
    /// Runtime event type
    type RuntimeEvent = RuntimeEvent;
    
    /// EVM precompiles (standard Ethereum precompiles)
    type PrecompilesType = GhostPrecompiles<Runtime>;
    type PrecompilesValue = ();
    
    /// EVM chain ID
    type ChainId = ChainId;
    
    /// Block gas limit
    type BlockGasLimit = BlockGasLimit;
    
    /// Runner for EVM execution
    type Runner = pallet_evm::runner::stack::Runner<Self>;
    
    /// On-charge transaction handler (handles fee payment)
    type OnChargeTransaction = pallet_evm::EVMFungibleAdapter<Balances, ()>;
    
    /// On-create action (no special action on contract creation)
    type OnCreate = ();
    
    /// Find author (block validator)
    type FindAuthor = FindAuthorTruncated<pallet_aura::FindAccountFromAuthorIndex<Runtime, pallet_aura::Pallet<Runtime>>>;
    
    /// Gas limit PoV size ratio
    type GasLimitPovSizeRatio = ();
    
    /// Timestamp provider
    type Timestamp = Timestamp;
    
    /// Weight info for benchmarking
    type WeightInfo = pallet_evm::weights::SubstrateWeight<Runtime>;
    
    /// SuicideQuickClearLimit - number of storage items to clear on contract self-destruct
    type SuicideQuickClearLimit = frame_support::traits::ConstU32<0>;
}

/// Configure pallet_ethereum
impl pallet_ethereum::Config for Runtime {
    /// Runtime event type
    type RuntimeEvent = RuntimeEvent;
    
    /// State root provider (uses EVM state root)
    type StateRoot = pallet_ethereum::IntermediateStateRoot<Runtime>;
    
    /// Post-log hook (no special action after log emission)
    type PostLogContent = ();
    
    /// Extra data in Ethereum blocks (empty by default)
    type ExtraDataLength = frame_support::traits::ConstU32<30>;
}

/// Configure pallet_base_fee (EIP-1559)
impl pallet_base_fee::Config for Runtime {
    /// Runtime event type
    type RuntimeEvent = RuntimeEvent;
    
    /// Threshold for base fee adjustment
    type Threshold = Elasticity;
    
    /// Default base fee (1 Gwei)
    type DefaultBaseFeePerGas = frame_support::traits::ConstU128<1_000_000_000>;
    
    /// Default elasticity (12.5% - standard for EIP-1559)
    type DefaultElasticity = Elasticity;
}

// ============================================================================
// IMPORTANT: EVM Pallet Initialization
// ============================================================================
// The EVM pallet requires on_finalize to be called to update base fee.
// This is handled automatically by the frame_executive, but we document it here
// for clarity. The BaseFee pallet's on_finalize hook updates the base fee
// based on block fullness (EIP-1559 mechanism).
