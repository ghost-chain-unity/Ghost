// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.
//
// In jurisdictions that recognize copyright laws, the author or authors
// of this software dedicate any and all copyright interest in the
// software to the public domain. We make this dedication for the benefit
// of the public at large and to the detriment of our heirs and
// successors. We intend this dedication to be an overt act of
// relinquishment in perpetuity of all present and future rights to this
// software under copyright law.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
// OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//
// For more information, please refer to <http://unlicense.org>

// External crates imports
use alloc::vec::Vec;
use frame_support::{
    genesis_builder_helper::{build_state, get_preset},
    weights::Weight,
};
use pallet_grandpa::AuthorityId as GrandpaId;
use sp_api::impl_runtime_apis;
use sp_consensus_aura::sr25519::AuthorityId as AuraId;
use sp_core::{crypto::KeyTypeId, OpaqueMetadata};
use sp_runtime::{
    traits::{Block as BlockT, NumberFor},
    transaction_validity::{TransactionSource, TransactionValidity},
    ApplyExtrinsicResult,
};
use sp_version::RuntimeVersion;

// Local module imports
use super::{
    AccountId, Aura, Balance, Block, BlockNumber, Executive, Grandpa,
    Nonce, Runtime, RuntimeCall, RuntimeGenesisConfig, SessionKeys, System,
    TransactionPayment, UncheckedExtrinsic, VERSION,
};

use crate::apis::ghost_protocol::{IntentData, JourneyStepData, MessagePointerData};
use pallet_chainghost::{IntentById, IntentsByAccount, JourneyByIntent};
use pallet_g3mail::{InboxCount, MessagesByRecipient, PublicKeys};
use pallet_ghonity::{FollowerCount, FollowingCount, Follows, ReputationScores};

impl_runtime_apis! {
    impl sp_api::Core<Block> for Runtime {
        fn version() -> RuntimeVersion {
            VERSION
        }

        fn execute_block(block: Block) {
            Executive::execute_block(block);
        }

        fn initialize_block(header: &<Block as BlockT>::Header) -> sp_runtime::ExtrinsicInclusionMode {
            Executive::initialize_block(header)
        }
    }

    impl sp_api::Metadata<Block> for Runtime {
        fn metadata() -> OpaqueMetadata {
            OpaqueMetadata::new(Runtime::metadata().into())
        }

        fn metadata_at_version(version: u32) -> Option<OpaqueMetadata> {
            Runtime::metadata_at_version(version)
        }

        fn metadata_versions() -> Vec<u32> {
            Runtime::metadata_versions()
        }
    }

    impl sp_block_builder::BlockBuilder<Block> for Runtime {
        fn apply_extrinsic(extrinsic: <Block as BlockT>::Extrinsic) -> ApplyExtrinsicResult {
            Executive::apply_extrinsic(extrinsic)
        }

        fn finalize_block() -> <Block as BlockT>::Header {
            Executive::finalize_block()
        }

        fn inherent_extrinsics(data: sp_inherents::InherentData) -> Vec<<Block as BlockT>::Extrinsic> {
            data.create_extrinsics()
        }

        fn check_inherents(
            block: Block,
            data: sp_inherents::InherentData,
        ) -> sp_inherents::CheckInherentsResult {
            data.check_extrinsics(&block)
        }
    }

    impl sp_transaction_pool::runtime_api::TaggedTransactionQueue<Block> for Runtime {
        fn validate_transaction(
            source: TransactionSource,
            tx: <Block as BlockT>::Extrinsic,
            block_hash: <Block as BlockT>::Hash,
        ) -> TransactionValidity {
            Executive::validate_transaction(source, tx, block_hash)
        }
    }

    impl sp_offchain::OffchainWorkerApi<Block> for Runtime {
        fn offchain_worker(header: &<Block as BlockT>::Header) {
            Executive::offchain_worker(header)
        }
    }

    impl sp_consensus_aura::AuraApi<Block, AuraId> for Runtime {
        fn slot_duration() -> sp_consensus_aura::SlotDuration {
            sp_consensus_aura::SlotDuration::from_millis(Aura::slot_duration())
        }

        fn authorities() -> Vec<AuraId> {
            pallet_aura::Authorities::<Runtime>::get().into_inner()
        }
    }

    impl sp_session::SessionKeys<Block> for Runtime {
        fn generate_session_keys(seed: Option<Vec<u8>>) -> Vec<u8> {
            SessionKeys::generate(seed)
        }

        fn decode_session_keys(
            encoded: Vec<u8>,
        ) -> Option<Vec<(Vec<u8>, KeyTypeId)>> {
            SessionKeys::decode_into_raw_public_keys(&encoded)
        }
    }

    impl sp_consensus_grandpa::GrandpaApi<Block> for Runtime {
        fn grandpa_authorities() -> sp_consensus_grandpa::AuthorityList {
            Grandpa::grandpa_authorities()
        }

        fn current_set_id() -> sp_consensus_grandpa::SetId {
            Grandpa::current_set_id()
        }

        fn submit_report_equivocation_unsigned_extrinsic(
            _equivocation_proof: sp_consensus_grandpa::EquivocationProof<
                <Block as BlockT>::Hash,
                NumberFor<Block>,
            >,
            _key_owner_proof: sp_consensus_grandpa::OpaqueKeyOwnershipProof,
        ) -> Option<()> {
            None
        }

        fn generate_key_ownership_proof(
            _set_id: sp_consensus_grandpa::SetId,
            _authority_id: GrandpaId,
        ) -> Option<sp_consensus_grandpa::OpaqueKeyOwnershipProof> {
            // NOTE: this is the only implementation possible since we've
            // defined our key owner proof type as a bottom type (i.e. a type
            // with no values).
            None
        }
    }

    impl frame_system_rpc_runtime_api::AccountNonceApi<Block, AccountId, Nonce> for Runtime {
        fn account_nonce(account: AccountId) -> Nonce {
            System::account_nonce(account)
        }
    }

    impl pallet_transaction_payment_rpc_runtime_api::TransactionPaymentApi<Block, Balance> for Runtime {
        fn query_info(
            uxt: <Block as BlockT>::Extrinsic,
            len: u32,
        ) -> pallet_transaction_payment_rpc_runtime_api::RuntimeDispatchInfo<Balance> {
            TransactionPayment::query_info(uxt, len)
        }
        fn query_fee_details(
            uxt: <Block as BlockT>::Extrinsic,
            len: u32,
        ) -> pallet_transaction_payment::FeeDetails<Balance> {
            TransactionPayment::query_fee_details(uxt, len)
        }
        fn query_weight_to_fee(weight: Weight) -> Balance {
            TransactionPayment::weight_to_fee(weight)
        }
        fn query_length_to_fee(length: u32) -> Balance {
            TransactionPayment::length_to_fee(length)
        }
    }

    impl pallet_transaction_payment_rpc_runtime_api::TransactionPaymentCallApi<Block, Balance, RuntimeCall>
        for Runtime
    {
        fn query_call_info(
            call: RuntimeCall,
            len: u32,
        ) -> pallet_transaction_payment::RuntimeDispatchInfo<Balance> {
            TransactionPayment::query_call_info(call, len)
        }
        fn query_call_fee_details(
            call: RuntimeCall,
            len: u32,
        ) -> pallet_transaction_payment::FeeDetails<Balance> {
            TransactionPayment::query_call_fee_details(call, len)
        }
        fn query_weight_to_fee(weight: Weight) -> Balance {
            TransactionPayment::weight_to_fee(weight)
        }
        fn query_length_to_fee(length: u32) -> Balance {
            TransactionPayment::length_to_fee(length)
        }
    }

    #[cfg(feature = "runtime-benchmarks")]
    impl frame_benchmarking::Benchmark<Block> for Runtime {
        fn benchmark_metadata(extra: bool) -> (
            Vec<frame_benchmarking::BenchmarkList>,
            Vec<frame_support::traits::StorageInfo>,
        ) {
            use frame_benchmarking::{baseline, BenchmarkList};
            use frame_support::traits::StorageInfoTrait;
            use frame_system_benchmarking::Pallet as SystemBench;
            use frame_system_benchmarking::extensions::Pallet as SystemExtensionsBench;
            use baseline::Pallet as BaselineBench;
            use super::*;

            let mut list = Vec::<BenchmarkList>::new();
            list_benchmarks!(list, extra);

            let storage_info = AllPalletsWithSystem::storage_info();

            (list, storage_info)
        }

        #[allow(non_local_definitions)]
        fn dispatch_benchmark(
            config: frame_benchmarking::BenchmarkConfig
        ) -> Result<Vec<frame_benchmarking::BenchmarkBatch>, alloc::string::String> {
            use frame_benchmarking::{baseline, BenchmarkBatch};
            use sp_storage::TrackedStorageKey;
            use frame_system_benchmarking::Pallet as SystemBench;
            use frame_system_benchmarking::extensions::Pallet as SystemExtensionsBench;
            use baseline::Pallet as BaselineBench;
            use super::*;

            impl frame_system_benchmarking::Config for Runtime {}
            impl baseline::Config for Runtime {}

            use frame_support::traits::WhitelistedStorageKeys;
            let whitelist: Vec<TrackedStorageKey> = AllPalletsWithSystem::whitelisted_storage_keys();

            let mut batches = Vec::<BenchmarkBatch>::new();
            let params = (&config, &whitelist);
            add_benchmarks!(params, batches);

            Ok(batches)
        }
    }

    #[cfg(feature = "try-runtime")]
    impl frame_try_runtime::TryRuntime<Block> for Runtime {
        fn on_runtime_upgrade(checks: frame_try_runtime::UpgradeCheckSelect) -> (Weight, Weight) {
            // NOTE: intentional unwrap: we don't want to propagate the error backwards, and want to
            // have a backtrace here. If any of the pre/post migration checks fail, we shall stop
            // right here and right now.
            let weight = Executive::try_runtime_upgrade(checks).unwrap();
            (weight, super::configs::RuntimeBlockWeights::get().max_block)
        }

        fn execute_block(
            block: Block,
            state_root_check: bool,
            signature_check: bool,
            select: frame_try_runtime::TryStateSelect
        ) -> Weight {
            // NOTE: intentional unwrap: we don't want to propagate the error backwards, and want to
            // have a backtrace here.
            Executive::try_execute_block(block, state_root_check, signature_check, select).expect("execute-block failed")
        }
    }

    impl sp_genesis_builder::GenesisBuilder<Block> for Runtime {
        fn build_state(config: Vec<u8>) -> sp_genesis_builder::Result {
            build_state::<RuntimeGenesisConfig>(config)
        }

        fn get_preset(id: &Option<sp_genesis_builder::PresetId>) -> Option<Vec<u8>> {
            get_preset::<RuntimeGenesisConfig>(id, crate::genesis_config_presets::get_preset)
        }

        fn preset_names() -> Vec<sp_genesis_builder::PresetId> {
            crate::genesis_config_presets::preset_names()
        }
    }

    impl crate::apis::ghost_protocol::ChainGhostRuntimeApi<Block, AccountId, BlockNumber> for Runtime {
        fn get_intent(intent_id: pallet_chainghost::IntentId) -> Option<IntentData<AccountId, BlockNumber>> {
            IntentById::<Runtime>::get(intent_id).map(|intent| IntentData {
                intent_id: intent.intent_id,
                account: intent.account,
                status: intent.status,
                timestamp: intent.timestamp,
                metadata: intent.metadata.into_inner(),
            })
        }

        fn get_intents_by_account(account: AccountId) -> Vec<pallet_chainghost::IntentId> {
            IntentsByAccount::<Runtime>::get(account).into_inner()
        }

        fn get_journey_steps(intent_id: pallet_chainghost::IntentId) -> Vec<JourneyStepData<BlockNumber>> {
            JourneyByIntent::<Runtime>::get(intent_id)
                .iter()
                .map(|step| JourneyStepData {
                    step_id: step.step_id,
                    description: step.description.clone().into_inner(),
                    timestamp: step.timestamp,
                })
                .collect()
        }

        fn get_intent_status(intent_id: pallet_chainghost::IntentId) -> Option<pallet_chainghost::IntentStatus> {
            IntentById::<Runtime>::get(intent_id).map(|intent| intent.status)
        }
    }

    impl crate::apis::ghost_protocol::G3MailRuntimeApi<Block, AccountId, BlockNumber> for Runtime {
        fn get_public_key(account: AccountId) -> Option<Vec<u8>> {
            PublicKeys::<Runtime>::get(account).map(|key| key.into_inner())
        }

        fn get_messages_by_recipient(_recipient: AccountId) -> Vec<(pallet_g3mail::MessageId, MessagePointerData<AccountId, BlockNumber>)> {
            sp_std::vec::Vec::new()
        }

        fn get_message(recipient: AccountId, message_id: pallet_g3mail::MessageId) -> Option<MessagePointerData<AccountId, BlockNumber>> {
            MessagesByRecipient::<Runtime>::get(recipient, message_id).map(|msg| MessagePointerData {
                message_id: msg.message_id,
                sender: msg.sender,
                recipient: msg.recipient,
                cid: msg.cid.into_inner(),
                timestamp: msg.timestamp,
                read: msg.read,
            })
        }

        fn get_inbox_count(account: AccountId) -> u32 {
            InboxCount::<Runtime>::get(account)
        }
    }

    impl crate::apis::ghost_protocol::GhonityRuntimeApi<Block, AccountId> for Runtime {
        fn is_following(follower: AccountId, followee: AccountId) -> bool {
            Follows::<Runtime>::contains_key(&follower, &followee)
        }

        fn get_follower_count(account: AccountId) -> u32 {
            FollowerCount::<Runtime>::get(account)
        }

        fn get_following_count(account: AccountId) -> u32 {
            FollowingCount::<Runtime>::get(account)
        }

        fn get_reputation_score(account: AccountId) -> u32 {
            ReputationScores::<Runtime>::get(account)
        }
    }

    impl fp_rpc::EthereumRuntimeRPCApi<Block> for Runtime {
        fn chain_id() -> u64 {
            <Runtime as pallet_evm::Config>::ChainId::get()
        }

        fn account_basic(address: sp_core::H160) -> fp_evm::Account {
            pallet_evm::Pallet::<Runtime>::account_basic(&address)
        }

        fn gas_price() -> sp_core::U256 {
            let (gas_price, _) = <Runtime as pallet_evm::Config>::FeeCalculator::min_gas_price();
            gas_price
        }

        fn account_code_at(address: sp_core::H160) -> Vec<u8> {
            pallet_evm::AccountCodes::<Runtime>::get(address)
        }

        fn author() -> sp_core::H160 {
            <pallet_evm::Pallet<Runtime>>::find_author()
        }

        fn storage_at(address: sp_core::H160, index: sp_core::U256) -> sp_core::U256 {
            let mut tmp = [0u8; 32];
            index.to_big_endian(&mut tmp);
            pallet_evm::AccountStorages::<Runtime>::get(address, sp_core::H256::from_slice(&tmp[..]))
        }

        fn call(
            from: sp_core::H160,
            to: sp_core::H160,
            data: Vec<u8>,
            value: sp_core::U256,
            gas_limit: sp_core::U256,
            max_fee_per_gas: Option<sp_core::U256>,
            max_priority_fee_per_gas: Option<sp_core::U256>,
            nonce: Option<sp_core::U256>,
            estimate: bool,
            access_list: Option<Vec<(sp_core::H160, Vec<sp_core::H256>)>>,
        ) -> Result<pallet_evm::CallInfo, sp_runtime::DispatchError> {
            let config = if estimate {
                let mut config = <Runtime as pallet_evm::Config>::config().clone();
                config.estimate = true;
                Some(config)
            } else {
                None
            };

            let is_transactional = false;
            let validate = true;

            let mut estimated_transaction_len = data.len() +
                20 + 
                20 + 
                32 + 
                32 + 
                32 + 
                32;
            if max_fee_per_gas.is_some() {
                estimated_transaction_len += 32;
            }
            if max_priority_fee_per_gas.is_some() {
                estimated_transaction_len += 32;
            }
            if access_list.is_some() {
                estimated_transaction_len += access_list.as_ref().unwrap().len() * 68;
            }

            let gas_limit = gas_limit.min(sp_core::U256::from(u64::MAX));
            let without_base_extrinsic_weight = true;

            let (weight_limit, proof_size_base_cost) = match pallet_ethereum::Pallet::<Runtime>::transaction_weight(
                from,
                gas_limit.unique_saturated_into(),
                estimated_transaction_len as u64,
            ) {
                Ok(weight_limit) => {
                    if without_base_extrinsic_weight {
                        (Some(weight_limit), None)
                    } else {
                        (Some(weight_limit), Some(estimated_transaction_len as u64))
                    }
                }
                Err(_) => (None, None),
            };

            <Runtime as pallet_evm::Config>::Runner::call(
                from,
                to,
                data,
                value,
                gas_limit.unique_saturated_into(),
                max_fee_per_gas,
                max_priority_fee_per_gas,
                nonce,
                access_list.unwrap_or_default(),
                is_transactional,
                validate,
                weight_limit,
                proof_size_base_cost,
                config.as_ref().unwrap_or_else(|| <Runtime as pallet_evm::Config>::config()),
            )
            .map_err(|err| err.error.into())
        }

        fn create(
            from: sp_core::H160,
            data: Vec<u8>,
            value: sp_core::U256,
            gas_limit: sp_core::U256,
            max_fee_per_gas: Option<sp_core::U256>,
            max_priority_fee_per_gas: Option<sp_core::U256>,
            nonce: Option<sp_core::U256>,
            estimate: bool,
            access_list: Option<Vec<(sp_core::H160, Vec<sp_core::H256>)>>,
        ) -> Result<pallet_evm::CreateInfo, sp_runtime::DispatchError> {
            let config = if estimate {
                let mut config = <Runtime as pallet_evm::Config>::config().clone();
                config.estimate = true;
                Some(config)
            } else {
                None
            };

            let is_transactional = false;
            let validate = true;

            let mut estimated_transaction_len = data.len() +
                20 + 
                32 + 
                32 + 
                32;
            if max_fee_per_gas.is_some() {
                estimated_transaction_len += 32;
            }
            if max_priority_fee_per_gas.is_some() {
                estimated_transaction_len += 32;
            }
            if access_list.is_some() {
                estimated_transaction_len += access_list.as_ref().unwrap().len() * 68;
            }

            let gas_limit = gas_limit.min(sp_core::U256::from(u64::MAX));
            let without_base_extrinsic_weight = true;

            let (weight_limit, proof_size_base_cost) = match pallet_ethereum::Pallet::<Runtime>::transaction_weight(
                from,
                gas_limit.unique_saturated_into(),
                estimated_transaction_len as u64,
            ) {
                Ok(weight_limit) => {
                    if without_base_extrinsic_weight {
                        (Some(weight_limit), None)
                    } else {
                        (Some(weight_limit), Some(estimated_transaction_len as u64))
                    }
                }
                Err(_) => (None, None),
            };

            <Runtime as pallet_evm::Config>::Runner::create(
                from,
                data,
                value,
                gas_limit.unique_saturated_into(),
                max_fee_per_gas,
                max_priority_fee_per_gas,
                nonce,
                access_list.unwrap_or_default(),
                is_transactional,
                validate,
                weight_limit,
                proof_size_base_cost,
                config.as_ref().unwrap_or_else(|| <Runtime as pallet_evm::Config>::config()),
            )
            .map_err(|err| err.error.into())
        }

        fn current_transaction_statuses() -> Option<Vec<fp_rpc::TransactionStatus>> {
            pallet_ethereum::CurrentTransactionStatuses::<Runtime>::get()
        }

        fn current_block() -> Option<pallet_ethereum::Block> {
            pallet_ethereum::CurrentBlock::<Runtime>::get()
        }

        fn current_receipts() -> Option<Vec<pallet_ethereum::Receipt>> {
            pallet_ethereum::CurrentReceipts::<Runtime>::get()
        }

        fn current_all() -> (
            Option<pallet_ethereum::Block>,
            Option<Vec<pallet_ethereum::Receipt>>,
            Option<Vec<fp_rpc::TransactionStatus>>,
        ) {
            (
                pallet_ethereum::CurrentBlock::<Runtime>::get(),
                pallet_ethereum::CurrentReceipts::<Runtime>::get(),
                pallet_ethereum::CurrentTransactionStatuses::<Runtime>::get(),
            )
        }

        fn extrinsic_filter(
            xts: Vec<<Block as BlockT>::Extrinsic>,
        ) -> Vec<pallet_ethereum::Transaction> {
            xts.into_iter().filter_map(|xt| match xt.0.function {
                RuntimeCall::Ethereum(pallet_ethereum::Call::transact { transaction }) => Some(transaction),
                _ => None
            }).collect::<Vec<pallet_ethereum::Transaction>>()
        }

        fn elasticity() -> Option<sp_runtime::Permill> {
            Some(pallet_base_fee::Elasticity::<Runtime>::get())
        }

        fn gas_limit_multiplier_support() {}

        fn pending_block(
            xts: Vec<<Block as BlockT>::Extrinsic>,
        ) -> (Option<pallet_ethereum::Block>, Option<Vec<fp_rpc::TransactionStatus>>) {
            for ext in xts.into_iter() {
                let _ = Executive::apply_extrinsic(ext);
            }

            (
                pallet_ethereum::CurrentBlock::<Runtime>::get(),
                pallet_ethereum::CurrentTransactionStatuses::<Runtime>::get(),
            )
        }

        fn initialize_pending_block(header: &<Block as BlockT>::Header) {
            Executive::initialize_block(header);
        }
    }

    impl fp_rpc::ConvertTransactionRuntimeApi<Block> for Runtime {
        fn convert_transaction(
            transaction: pallet_ethereum::Transaction,
        ) -> <Block as BlockT>::Extrinsic {
            UncheckedExtrinsic::new_unsigned(
                pallet_ethereum::Call::<Runtime>::transact { transaction }.into(),
            )
        }
    }
}
