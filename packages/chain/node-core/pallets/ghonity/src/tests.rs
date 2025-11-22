use crate::{mock::*, Error, Event};
use frame_support::{assert_noop, assert_ok};

const ALICE: u64 = 1;
const BOB: u64 = 2;
const CHARLIE: u64 = 3;

#[test]
fn follow_works() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);

        assert_ok!(Ghonity::follow(RuntimeOrigin::signed(ALICE), BOB));

        assert!(Ghonity::is_following(&ALICE, &BOB));
        assert_eq!(Ghonity::get_follower_count(&BOB), 1);
        assert_eq!(Ghonity::get_following_count(&ALICE), 1);

        System::assert_last_event(
            Event::Followed {
                follower: ALICE,
                followee: BOB,
            }
            .into(),
        );
    });
}

#[test]
fn cannot_follow_self() {
    new_test_ext().execute_with(|| {
        assert_noop!(
            Ghonity::follow(RuntimeOrigin::signed(ALICE), ALICE),
            Error::<Test>::CannotFollowSelf
        );
    });
}

#[test]
fn cannot_follow_twice() {
    new_test_ext().execute_with(|| {
        assert_ok!(Ghonity::follow(RuntimeOrigin::signed(ALICE), BOB));

        assert_noop!(
            Ghonity::follow(RuntimeOrigin::signed(ALICE), BOB),
            Error::<Test>::AlreadyFollowing
        );
    });
}

#[test]
fn unfollow_works() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);

        assert_ok!(Ghonity::follow(RuntimeOrigin::signed(ALICE), BOB));
        assert_eq!(Ghonity::get_follower_count(&BOB), 1);
        assert_eq!(Ghonity::get_following_count(&ALICE), 1);

        assert_ok!(Ghonity::unfollow(RuntimeOrigin::signed(ALICE), BOB));

        assert!(!Ghonity::is_following(&ALICE, &BOB));
        assert_eq!(Ghonity::get_follower_count(&BOB), 0);
        assert_eq!(Ghonity::get_following_count(&ALICE), 0);

        System::assert_last_event(
            Event::Unfollowed {
                follower: ALICE,
                followee: BOB,
            }
            .into(),
        );
    });
}

#[test]
fn cannot_unfollow_if_not_following() {
    new_test_ext().execute_with(|| {
        assert_noop!(
            Ghonity::unfollow(RuntimeOrigin::signed(ALICE), BOB),
            Error::<Test>::NotFollowing
        );
    });
}

#[test]
fn update_reputation_works() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);

        assert_eq!(Ghonity::get_reputation(&ALICE), 0);

        assert_ok!(Ghonity::update_reputation(
            RuntimeOrigin::root(),
            ALICE,
            100
        ));

        assert_eq!(Ghonity::get_reputation(&ALICE), 100);

        System::assert_last_event(
            Event::ReputationUpdated {
                account: ALICE,
                old_score: 0,
                new_score: 100,
            }
            .into(),
        );
    });
}

#[test]
fn update_reputation_requires_root() {
    new_test_ext().execute_with(|| {
        assert_noop!(
            Ghonity::update_reputation(RuntimeOrigin::signed(ALICE), BOB, 100),
            sp_runtime::DispatchError::BadOrigin
        );
    });
}

#[test]
fn update_reputation_can_decrease() {
    new_test_ext().execute_with(|| {
        assert_ok!(Ghonity::update_reputation(
            RuntimeOrigin::root(),
            ALICE,
            100
        ));
        assert_eq!(Ghonity::get_reputation(&ALICE), 100);

        assert_ok!(Ghonity::update_reputation(RuntimeOrigin::root(), ALICE, 50));
        assert_eq!(Ghonity::get_reputation(&ALICE), 50);
    });
}

#[test]
fn bidirectional_follows_work() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);

        assert_ok!(Ghonity::follow(RuntimeOrigin::signed(ALICE), BOB));
        assert_ok!(Ghonity::follow(RuntimeOrigin::signed(BOB), ALICE));

        assert!(Ghonity::is_following(&ALICE, &BOB));
        assert!(Ghonity::is_following(&BOB, &ALICE));

        assert_eq!(Ghonity::get_follower_count(&ALICE), 1);
        assert_eq!(Ghonity::get_follower_count(&BOB), 1);
        assert_eq!(Ghonity::get_following_count(&ALICE), 1);
        assert_eq!(Ghonity::get_following_count(&BOB), 1);
    });
}

#[test]
fn multiple_follows_work() {
    new_test_ext().execute_with(|| {
        assert_ok!(Ghonity::follow(RuntimeOrigin::signed(ALICE), BOB));
        assert_ok!(Ghonity::follow(RuntimeOrigin::signed(ALICE), CHARLIE));

        assert!(Ghonity::is_following(&ALICE, &BOB));
        assert!(Ghonity::is_following(&ALICE, &CHARLIE));

        assert_eq!(Ghonity::get_following_count(&ALICE), 2);
        assert_eq!(Ghonity::get_follower_count(&BOB), 1);
        assert_eq!(Ghonity::get_follower_count(&CHARLIE), 1);
    });
}

#[test]
fn multiple_followers_work() {
    new_test_ext().execute_with(|| {
        assert_ok!(Ghonity::follow(RuntimeOrigin::signed(ALICE), BOB));
        assert_ok!(Ghonity::follow(RuntimeOrigin::signed(CHARLIE), BOB));

        assert!(Ghonity::is_following(&ALICE, &BOB));
        assert!(Ghonity::is_following(&CHARLIE, &BOB));

        assert_eq!(Ghonity::get_follower_count(&BOB), 2);
        assert_eq!(Ghonity::get_following_count(&ALICE), 1);
        assert_eq!(Ghonity::get_following_count(&CHARLIE), 1);
    });
}

#[test]
fn counters_remain_consistent_after_unfollow() {
    new_test_ext().execute_with(|| {
        assert_ok!(Ghonity::follow(RuntimeOrigin::signed(ALICE), BOB));
        assert_ok!(Ghonity::follow(RuntimeOrigin::signed(ALICE), CHARLIE));
        assert_ok!(Ghonity::follow(RuntimeOrigin::signed(BOB), CHARLIE));

        assert_eq!(Ghonity::get_following_count(&ALICE), 2);
        assert_eq!(Ghonity::get_follower_count(&CHARLIE), 2);

        assert_ok!(Ghonity::unfollow(RuntimeOrigin::signed(ALICE), CHARLIE));

        assert_eq!(Ghonity::get_following_count(&ALICE), 1);
        assert_eq!(Ghonity::get_follower_count(&CHARLIE), 1);
        assert!(Ghonity::is_following(&ALICE, &BOB));
        assert!(Ghonity::is_following(&BOB, &CHARLIE));
    });
}

#[test]
fn helper_functions_work() {
    new_test_ext().execute_with(|| {
        assert!(!Ghonity::is_following(&ALICE, &BOB));
        assert_eq!(Ghonity::get_follower_count(&BOB), 0);
        assert_eq!(Ghonity::get_following_count(&ALICE), 0);
        assert_eq!(Ghonity::get_reputation(&ALICE), 0);

        assert_ok!(Ghonity::follow(RuntimeOrigin::signed(ALICE), BOB));
        assert_ok!(Ghonity::update_reputation(
            RuntimeOrigin::root(),
            ALICE,
            100
        ));

        assert!(Ghonity::is_following(&ALICE, &BOB));
        assert_eq!(Ghonity::get_follower_count(&BOB), 1);
        assert_eq!(Ghonity::get_following_count(&ALICE), 1);
        assert_eq!(Ghonity::get_reputation(&ALICE), 100);
    });
}

#[test]
fn max_following_limit_enforced() {
    new_test_ext().execute_with(|| {
        let max_following = <Test as crate::Config>::MaxFollowing::get();

        for i in 0..max_following {
            let followee = 1000 + i as u64;
            assert_ok!(Ghonity::follow(RuntimeOrigin::signed(ALICE), followee));
        }

        assert_eq!(Ghonity::get_following_count(&ALICE), max_following);

        let one_more = 1000 + max_following as u64;
        assert_noop!(
            Ghonity::follow(RuntimeOrigin::signed(ALICE), one_more),
            Error::<Test>::MaxFollowingExceeded
        );
    });
}

#[test]
fn can_follow_after_unfollowing_within_limit() {
    new_test_ext().execute_with(|| {
        assert_ok!(Ghonity::follow(RuntimeOrigin::signed(ALICE), BOB));
        assert_ok!(Ghonity::unfollow(RuntimeOrigin::signed(ALICE), BOB));
        assert_ok!(Ghonity::follow(RuntimeOrigin::signed(ALICE), CHARLIE));

        assert!(!Ghonity::is_following(&ALICE, &BOB));
        assert!(Ghonity::is_following(&ALICE, &CHARLIE));
        assert_eq!(Ghonity::get_following_count(&ALICE), 1);
    });
}

#[test]
fn reputation_max_value_works() {
    new_test_ext().execute_with(|| {
        assert_ok!(Ghonity::update_reputation(
            RuntimeOrigin::root(),
            ALICE,
            u32::MAX
        ));
        assert_eq!(Ghonity::get_reputation(&ALICE), u32::MAX);
    });
}

#[test]
fn events_emitted_correctly() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);

        assert_ok!(Ghonity::follow(RuntimeOrigin::signed(ALICE), BOB));
        System::assert_has_event(
            Event::Followed {
                follower: ALICE,
                followee: BOB,
            }
            .into(),
        );

        assert_ok!(Ghonity::unfollow(RuntimeOrigin::signed(ALICE), BOB));
        System::assert_has_event(
            Event::Unfollowed {
                follower: ALICE,
                followee: BOB,
            }
            .into(),
        );

        assert_ok!(Ghonity::update_reputation(
            RuntimeOrigin::root(),
            ALICE,
            100
        ));
        System::assert_has_event(
            Event::ReputationUpdated {
                account: ALICE,
                old_score: 0,
                new_score: 100,
            }
            .into(),
        );
    });
}

#[test]
fn storage_independence_per_account() {
    new_test_ext().execute_with(|| {
        assert_ok!(Ghonity::follow(RuntimeOrigin::signed(ALICE), BOB));
        assert_ok!(Ghonity::follow(RuntimeOrigin::signed(CHARLIE), BOB));

        assert_ok!(Ghonity::unfollow(RuntimeOrigin::signed(ALICE), BOB));

        assert!(!Ghonity::is_following(&ALICE, &BOB));
        assert!(Ghonity::is_following(&CHARLIE, &BOB));
        assert_eq!(Ghonity::get_follower_count(&BOB), 1);
    });
}
