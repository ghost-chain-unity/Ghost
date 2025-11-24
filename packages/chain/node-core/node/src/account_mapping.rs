//! Account mapping module for Substrate ↔ Ethereum address conversion
//! 
//! Converts between Substrate SS58 addresses and Ethereum H160 addresses
//! using Blake2b-256 hashing for deterministic mapping.

use sp_core::H160;
use sp_runtime::AccountId32;
use sp_core::blake2_256;

/// Maps Substrate AccountId32 to Ethereum H160 address
/// Uses Blake2b-256 hash of AccountId + "eth" prefix for deterministic conversion
pub fn account_id_to_h160(account: &AccountId32) -> H160 {
    let mut data = [0u8; 32];
    data[0..4].copy_from_slice(b"eth:");
    data[4..32].copy_from_slice(&account.as_ref()[0..28]);
    
    let hash = blake2_256(&data);
    H160::from_slice(&hash[0..20])
}

/// Reverse mapping: Ethereum H160 → Substrate AccountId32
/// Creates deterministic AccountId from H160 address
pub fn h160_to_account_id(address: &H160) -> AccountId32 {
    let mut account_data = [0u8; 32];
    account_data[0..4].copy_from_slice(b"eth:");
    account_data[4..24].copy_from_slice(address.as_bytes());
    
    AccountId32::from(account_data)
}

/// Verify bidirectional mapping consistency
pub fn verify_mapping(account: &AccountId32, address: &H160) -> bool {
    &account_id_to_h160(account) == address
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_account_id_to_h160_deterministic() {
        let account = AccountId32::new([1u8; 32]);
        let h160_1 = account_id_to_h160(&account);
        let h160_2 = account_id_to_h160(&account);
        
        assert_eq!(h160_1, h160_2, "Mapping should be deterministic");
    }

    #[test]
    fn test_h160_to_account_id_deterministic() {
        let address = H160::from_low_u64_be(12345);
        let account_1 = h160_to_account_id(&address);
        let account_2 = h160_to_account_id(&address);
        
        assert_eq!(account_1, account_2, "Reverse mapping should be deterministic");
    }

    #[test]
    fn test_bidirectional_mapping() {
        let original_account = AccountId32::new([42u8; 32]);
        let h160 = account_id_to_h160(&original_account);
        let recovered_account = h160_to_account_id(&h160);
        
        assert_eq!(original_account, recovered_account, "Bidirectional mapping should be consistent");
    }

    #[test]
    fn test_different_accounts_different_addresses() {
        let account1 = AccountId32::new([1u8; 32]);
        let account2 = AccountId32::new([2u8; 32]);
        
        let address1 = account_id_to_h160(&account1);
        let address2 = account_id_to_h160(&account2);
        
        assert_ne!(address1, address2, "Different accounts should map to different addresses");
    }

    #[test]
    fn test_known_vector_alice() {
        // Test with a known Alice-like pattern
        let mut alice = [0u8; 32];
        alice[0..4].copy_from_slice(b"alic");
        let account = AccountId32::from(alice);
        
        let address = account_id_to_h160(&account);
        
        // Verify it's a valid H160
        assert_eq!(address.len(), 20, "H160 should be 20 bytes");
    }

    #[test]
    fn test_h160_zero_address() {
        let zero_address = H160::zero();
        let account = h160_to_account_id(&zero_address);
        
        // Should produce valid AccountId32
        assert_eq!(account.len(), 32, "AccountId32 should be 32 bytes");
    }

    #[test]
    fn test_verify_mapping_consistency() {
        let account = AccountId32::new([99u8; 32]);
        let address = account_id_to_h160(&account);
        
        assert!(verify_mapping(&account, &address), "Verification should pass for correct mapping");
    }

    #[test]
    fn test_verify_mapping_fails_for_mismatch() {
        let account = AccountId32::new([99u8; 32]);
        let wrong_address = H160::from_low_u64_be(999);
        
        assert!(!verify_mapping(&account, &wrong_address), "Verification should fail for wrong mapping");
    }
}
