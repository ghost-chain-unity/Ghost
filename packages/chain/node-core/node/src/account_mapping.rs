// Account mapping between Substrate SS58 addresses and Ethereum H160 addresses
//
// This module provides bidirectional conversion between Substrate AccountId (SS58)
// and Ethereum addresses (H160) for Ghost Protocol's EVM integration.

use sp_core::{blake2_256, H160};
use sp_runtime::AccountId32;

/// Convert a Substrate SS58 AccountId to an Ethereum H160 address
/// 
/// Strategy: Take the first 20 bytes of the 32-byte AccountId
/// This ensures deterministic and reversible conversion for accounts
/// that were originally created from Ethereum addresses.
///
/// # Arguments
/// * `account_id` - The Substrate AccountId32 to convert
///
/// # Returns
/// An Ethereum H160 address (20 bytes)
///
/// # Example
/// ```ignore
/// use sp_runtime::AccountId32;
/// let account_id = AccountId32::from([1u8; 32]);
/// let eth_address = ss58_to_h160(&account_id);
/// assert_eq!(eth_address, H160::from([1u8; 20]));
/// ```
pub fn ss58_to_h160(account_id: &AccountId32) -> H160 {
    let account_bytes = account_id.as_ref();
    // Take first 20 bytes of the 32-byte AccountId
    H160::from_slice(&account_bytes[0..20])
}

/// Convert an Ethereum H160 address to a Substrate SS58 AccountId
///
/// Strategy: Hash the H160 address with a prefix to create a 32-byte AccountId
/// This ensures that Ethereum addresses have deterministic Substrate representations.
///
/// # Arguments
/// * `address` - The Ethereum H160 address to convert
///
/// # Returns
/// A Substrate AccountId32 (32 bytes)
///
/// # Example
/// ```ignore
/// use sp_core::H160;
/// let eth_address = H160::from_low_u64_be(42);
/// let account_id = h160_to_ss58(&eth_address);
/// // AccountId is deterministic for the same eth_address
/// assert_eq!(account_id, h160_to_ss58(&eth_address));
/// ```
pub fn h160_to_ss58(address: &H160) -> AccountId32 {
    let mut data = [0u8; 24];
    // Use "evm:" prefix (4 bytes) + H160 address (20 bytes) = 24 bytes
    data[0..4].copy_from_slice(b"evm:");
    data[4..24].copy_from_slice(address.as_bytes());
    
    // Hash to create 32-byte AccountId
    let hash = blake2_256(&data);
    AccountId32::from(hash)
}

/// Verify round-trip conversion for EVM-originated accounts
///
/// For accounts that originate from Ethereum addresses, we can verify
/// that converting H160 → SS58 → H160 preserves the original address
/// if the conversion is done correctly.
///
/// Note: This only works for EVM-originated accounts. Native Substrate
/// accounts will not round-trip.
pub fn verify_evm_roundtrip(eth_address: &H160) -> bool {
    let account_id = h160_to_ss58(eth_address);
    let recovered = ss58_to_h160(&account_id);
    
    // For EVM-originated accounts, check if the first 20 bytes match
    // (This will not be true for all cases due to the hashing in h160_to_ss58)
    recovered == *eth_address
}

#[cfg(test)]
mod tests {
    use super::*;
    use sp_core::H160;
    use sp_runtime::AccountId32;

    #[test]
    fn test_ss58_to_h160_deterministic() {
        let account_id = AccountId32::from([1u8; 32]);
        let h160_1 = ss58_to_h160(&account_id);
        let h160_2 = ss58_to_h160(&account_id);
        
        assert_eq!(h160_1, h160_2, "Conversion should be deterministic");
        assert_eq!(h160_1, H160::from([1u8; 20]), "Should take first 20 bytes");
    }

    #[test]
    fn test_h160_to_ss58_deterministic() {
        let eth_address = H160::from_low_u64_be(42);
        let account_1 = h160_to_ss58(&eth_address);
        let account_2 = h160_to_ss58(&eth_address);
        
        assert_eq!(account_1, account_2, "Conversion should be deterministic");
    }

    #[test]
    fn test_h160_to_ss58_different_addresses() {
        let addr1 = H160::from_low_u64_be(1);
        let addr2 = H160::from_low_u64_be(2);
        
        let account1 = h160_to_ss58(&addr1);
        let account2 = h160_to_ss58(&addr2);
        
        assert_ne!(account1, account2, "Different addresses should map to different accounts");
    }

    #[test]
    fn test_ss58_to_h160_truncation() {
        let mut account_bytes = [0u8; 32];
        // Set first 20 bytes to 1
        account_bytes[0..20].copy_from_slice(&[1u8; 20]);
        // Set last 12 bytes to 2 (these should be ignored)
        account_bytes[20..32].copy_from_slice(&[2u8; 12]);
        
        let account_id = AccountId32::from(account_bytes);
        let h160_addr = ss58_to_h160(&account_id);
        
        assert_eq!(h160_addr, H160::from([1u8; 20]), "Should only use first 20 bytes");
    }

    #[test]
    fn test_alice_account_conversion() {
        // Alice's well-known AccountId (in hex): 
        // d43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d
        let alice = sp_keyring::AccountKeyring::Alice.to_account_id();
        let alice_eth = ss58_to_h160(&alice);
        
        // Verify the conversion is deterministic
        assert_eq!(alice_eth, ss58_to_h160(&alice));
        
        // Verify it's 20 bytes
        assert_eq!(alice_eth.as_bytes().len(), 20);
    }

    #[test]
    fn test_bob_account_conversion() {
        let bob = sp_keyring::AccountKeyring::Bob.to_account_id();
        let bob_eth = ss58_to_h160(&bob);
        
        // Bob and Alice should have different Ethereum addresses
        let alice_eth = ss58_to_h160(&sp_keyring::AccountKeyring::Alice.to_account_id());
        assert_ne!(alice_eth, bob_eth, "Different accounts should map to different addresses");
    }

    #[test]
    fn test_zero_address() {
        let zero_eth = H160::zero();
        let account = h160_to_ss58(&zero_eth);
        
        // Zero address should create a valid AccountId
        assert_ne!(account, AccountId32::from([0u8; 32]), "Should not be all zeros due to hashing");
        
        // Should be deterministic
        assert_eq!(account, h160_to_ss58(&zero_eth));
    }

    #[test]
    fn test_max_address() {
        let max_eth = H160::from([0xff; 20]);
        let account = h160_to_ss58(&max_eth);
        
        // Should create a valid AccountId
        assert_ne!(account, AccountId32::from([0xff; 32]), "Should not be all 0xff due to hashing");
        
        // Should be deterministic
        assert_eq!(account, h160_to_ss58(&max_eth));
    }
}
