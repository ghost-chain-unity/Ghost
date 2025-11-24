// This file is part of Substrate.

// Copyright (C) Parity Technologies (UK) Ltd.
// SPDX-License-Identifier: Apache-2.0

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

use crate::{AccountId, RuntimeGenesisConfig as GenesisConfig, BalancesConfig, SudoConfig};
use alloc::{vec, vec::Vec};
use frame_support::build_struct_json_patch;
use serde_json::Value;
use sp_consensus_aura::sr25519::AuthorityId as AuraId;
use sp_consensus_grandpa::AuthorityId as GrandpaId;
use sp_genesis_builder::{self, PresetId};
use sp_keyring::Sr25519Keyring;
use sp_core::{H160, U256};
use alloc::collections::BTreeMap;

// Helper function to convert AccountId to EVM H160 address
// Strategy: Take first 20 bytes of the 32-byte AccountId
fn account_id_to_h160(account_id: &AccountId) -> H160 {
    let account_bytes: &[u8; 32] = account_id.as_ref();
    H160::from_slice(&account_bytes[0..20])
}

// Helper function to create EVM genesis accounts for well-known test accounts
fn get_evm_genesis_accounts() -> BTreeMap<H160, fp_evm::GenesisAccount> {
    let mut accounts = BTreeMap::new();
    
    // Pre-fund Alice's EVM account
    let alice_account_id = Sr25519Keyring::Alice.to_account_id();
    let alice_evm_address = account_id_to_h160(&alice_account_id);
    accounts.insert(
        alice_evm_address,
        fp_evm::GenesisAccount {
            balance: U256::from(1u128 << 60), // Same as Substrate balance
            code: Default::default(),
            nonce: Default::default(),
            storage: Default::default(),
        },
    );
    
    // Pre-fund Bob's EVM account
    let bob_account_id = Sr25519Keyring::Bob.to_account_id();
    let bob_evm_address = account_id_to_h160(&bob_account_id);
    accounts.insert(
        bob_evm_address,
        fp_evm::GenesisAccount {
            balance: U256::from(1u128 << 60),
            code: Default::default(),
            nonce: Default::default(),
            storage: Default::default(),
        },
    );
    
    accounts
}

// Returns the genesis config presets populated with given parameters.
fn testnet_genesis(
    initial_authorities: Vec<(AuraId, GrandpaId)>,
    endowed_accounts: Vec<AccountId>,
    root: AccountId,
) -> Value {
    build_struct_json_patch!(GenesisConfig {
        balances: BalancesConfig {
            balances: endowed_accounts
                .iter()
                .cloned()
                .map(|k| (k, 1u128 << 60))
                .collect::<Vec<_>>(),
        },
        aura: pallet_aura::GenesisConfig {
            authorities: initial_authorities
                .iter()
                .map(|x| x.0.clone())
                .collect::<Vec<_>>(),
        },
        grandpa: pallet_grandpa::GenesisConfig {
            authorities: initial_authorities
                .iter()
                .map(|x| (x.1.clone(), 1))
                .collect::<Vec<_>>(),
        },
        sudo: SudoConfig { key: Some(root) },
        evm: pallet_evm::GenesisConfig {
            accounts: get_evm_genesis_accounts(),
            _config: Default::default(),
        },
    })
}

/// Return the development genesis config.
pub fn development_config_genesis() -> Value {
    testnet_genesis(
        vec![(
            sp_keyring::Sr25519Keyring::Alice.public().into(),
            sp_keyring::Ed25519Keyring::Alice.public().into(),
        )],
        vec![
            Sr25519Keyring::Alice.to_account_id(),
            Sr25519Keyring::Bob.to_account_id(),
            Sr25519Keyring::AliceStash.to_account_id(),
            Sr25519Keyring::BobStash.to_account_id(),
        ],
        sp_keyring::Sr25519Keyring::Alice.to_account_id(),
    )
}

/// Return the local genesis config preset.
pub fn local_config_genesis() -> Value {
    testnet_genesis(
        vec![
            (
                sp_keyring::Sr25519Keyring::Alice.public().into(),
                sp_keyring::Ed25519Keyring::Alice.public().into(),
            ),
            (
                sp_keyring::Sr25519Keyring::Bob.public().into(),
                sp_keyring::Ed25519Keyring::Bob.public().into(),
            ),
            (
                sp_keyring::Sr25519Keyring::Charlie.public().into(),
                sp_keyring::Ed25519Keyring::Charlie.public().into(),
            ),
        ],
        Sr25519Keyring::iter()
            .filter(|v| v != &Sr25519Keyring::One && v != &Sr25519Keyring::Two)
            .map(|v| v.to_account_id())
            .collect::<Vec<_>>(),
        Sr25519Keyring::Alice.to_account_id(),
    )
}

/// Provides the JSON representation of predefined genesis config for given `id`.
pub fn get_preset(id: &PresetId) -> Option<Vec<u8>> {
    let patch = match id.as_ref() {
        sp_genesis_builder::DEV_RUNTIME_PRESET => development_config_genesis(),
        sp_genesis_builder::LOCAL_TESTNET_RUNTIME_PRESET => local_config_genesis(),
        _ => return None,
    };
    Some(
        serde_json::to_string(&patch)
            .expect("serialization to json is expected to work. qed.")
            .into_bytes(),
    )
}

/// List of supported presets.
pub fn preset_names() -> Vec<PresetId> {
    vec![
        PresetId::from(sp_genesis_builder::DEV_RUNTIME_PRESET),
        PresetId::from(sp_genesis_builder::LOCAL_TESTNET_RUNTIME_PRESET),
    ]
}
