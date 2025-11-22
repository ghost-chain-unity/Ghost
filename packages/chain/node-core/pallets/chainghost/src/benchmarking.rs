//! Benchmarking setup for pallet-chainghost

use super::*;

#[allow(unused)]
use crate::Pallet as ChainGhost;
use frame_benchmarking::v2::*;
use frame_system::RawOrigin;

#[benchmarks]
mod benchmarks {
    use super::*;

    #[benchmark]
    fn execute_intent() {
        let metadata = b"Swap 100 USDC to ETH on Arbitrum".to_vec();
        let caller: T::AccountId = whitelisted_caller();

        #[extrinsic_call]
        execute_intent(RawOrigin::Signed(caller.clone()), metadata.clone());

        assert_eq!(ChainGhost::<T>::next_intent_id(), 1);
        let intent = ChainGhost::<T>::intent_by_id(0).expect("Intent should exist");
        assert_eq!(intent.account, caller);
    }

    #[benchmark]
    fn record_journey() {
        let metadata = b"Test intent".to_vec();
        let caller: T::AccountId = whitelisted_caller();

        // Setup: Create an intent first
        let _ = ChainGhost::<T>::execute_intent(RawOrigin::Signed(caller.clone()).into(), metadata);

        let description = b"Step 1: Transaction initiated on Arbitrum".to_vec();

        #[extrinsic_call]
        record_journey(RawOrigin::Signed(caller), 0, description.clone());

        let journey_steps = ChainGhost::<T>::journey_by_intent(0);
        assert_eq!(journey_steps.len(), 1);
    }

    #[benchmark]
    fn update_intent_status() {
        let metadata = b"Test intent".to_vec();
        let caller: T::AccountId = whitelisted_caller();

        // Setup: Create an intent first
        let _ = ChainGhost::<T>::execute_intent(RawOrigin::Signed(caller.clone()).into(), metadata);

        #[extrinsic_call]
        update_intent_status(RawOrigin::Signed(caller), 0, 1); // 1 = Executed

        let intent = ChainGhost::<T>::intent_by_id(0).expect("Intent should exist");
        assert_eq!(intent.status, IntentStatus::Executed);
    }

    impl_benchmark_test_suite!(ChainGhost, crate::mock::new_test_ext(), crate::mock::Test);
}
