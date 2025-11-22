//! Benchmarking setup for pallet-ghonity

use super::*;

#[allow(unused)]
use crate::Pallet as Ghonity;
use frame_benchmarking::v2::*;
use frame_system::RawOrigin;

#[benchmarks]
mod benchmarks {
    use super::*;

    #[benchmark]
    fn follow() {
        let caller: T::AccountId = whitelisted_caller();
        let followee: T::AccountId = account("followee", 0, 0);

        #[extrinsic_call]
        follow(RawOrigin::Signed(caller.clone()), followee.clone());

        assert!(Follows::<T>::get(&caller, &followee));
        assert_eq!(FollowingCount::<T>::get(&caller), 1);
        assert_eq!(FollowerCount::<T>::get(&followee), 1);
    }

    #[benchmark]
    fn unfollow() {
        let caller: T::AccountId = whitelisted_caller();
        let followee: T::AccountId = account("followee", 0, 0);

        // Setup: Create a follow relationship first using the dispatchable
        let _ = Ghonity::<T>::follow(RawOrigin::Signed(caller.clone()).into(), followee.clone());

        #[extrinsic_call]
        unfollow(RawOrigin::Signed(caller.clone()), followee.clone());

        assert!(!Follows::<T>::get(&caller, &followee));
        assert_eq!(FollowingCount::<T>::get(&caller), 0);
        assert_eq!(FollowerCount::<T>::get(&followee), 0);
    }

    #[benchmark]
    fn update_reputation() {
        let account: T::AccountId = whitelisted_caller();
        let score = 100u32;

        #[extrinsic_call]
        update_reputation(RawOrigin::Root, account.clone(), score);

        assert_eq!(ReputationScores::<T>::get(&account), score);
    }

    impl_benchmark_test_suite!(Ghonity, crate::mock::new_test_ext(), crate::mock::Test);
}
