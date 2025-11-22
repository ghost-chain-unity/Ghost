//! Benchmarking setup for pallet-g3mail

use super::*;

#[allow(unused)]
use crate::Pallet as G3Mail;
use frame_benchmarking::v2::*;
use frame_system::RawOrigin;

#[benchmarks]
mod benchmarks {
    use super::*;
    extern crate alloc;
    use alloc::vec;

    #[benchmark]
    fn register_public_key() {
        let public_key = vec![0u8; 64];
        let caller: T::AccountId = whitelisted_caller();

        #[extrinsic_call]
        register_public_key(RawOrigin::Signed(caller.clone()), public_key.clone());

        assert!(PublicKeys::<T>::contains_key(&caller));
    }

    #[benchmark]
    fn send_message() {
        let sender: T::AccountId = whitelisted_caller();
        let recipient: T::AccountId = account("recipient", 0, 0);
        let sender_key = vec![0u8; 64];
        let recipient_key = vec![1u8; 64];
        let cid = b"QmXYZ123".to_vec();

        // Register sender's public key first
        let _ =
            G3Mail::<T>::register_public_key(RawOrigin::Signed(sender.clone()).into(), sender_key);

        // Register recipient's public key
        let _ = G3Mail::<T>::register_public_key(
            RawOrigin::Signed(recipient.clone()).into(),
            recipient_key,
        );

        #[extrinsic_call]
        send_message(
            RawOrigin::Signed(sender.clone()),
            recipient.clone(),
            cid.clone(),
        );

        assert_eq!(G3Mail::<T>::next_message_id(), 1);
        assert_eq!(G3Mail::<T>::inbox_count(&recipient), 1);
    }

    #[benchmark]
    fn mark_message_read() {
        let sender: T::AccountId = whitelisted_caller();
        let recipient: T::AccountId = account("recipient", 0, 0);
        let sender_key = vec![0u8; 64];
        let recipient_key = vec![1u8; 64];
        let cid = b"QmXYZ123".to_vec();

        let _ =
            G3Mail::<T>::register_public_key(RawOrigin::Signed(sender.clone()).into(), sender_key);
        let _ = G3Mail::<T>::register_public_key(
            RawOrigin::Signed(recipient.clone()).into(),
            recipient_key,
        );
        let _ = G3Mail::<T>::send_message(RawOrigin::Signed(sender).into(), recipient.clone(), cid);

        #[extrinsic_call]
        mark_message_read(RawOrigin::Signed(recipient.clone()), 0);

        let message =
            G3Mail::<T>::messages_by_recipient(&recipient, 0).expect("Message should exist");
        assert_eq!(message.read, true);
    }

    impl_benchmark_test_suite!(G3Mail, crate::mock::new_test_ext(), crate::mock::Test);
}
