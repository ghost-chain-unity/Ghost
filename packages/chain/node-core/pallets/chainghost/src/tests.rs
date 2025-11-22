use crate::{mock::*, Error, Event, IntentStatus};
use frame_support::{assert_noop, assert_ok};

#[test]
fn execute_intent_works() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);

        let metadata = b"Swap 100 USDC to ETH".to_vec();

        // Execute intent
        assert_ok!(ChainGhost::execute_intent(
            RuntimeOrigin::signed(1),
            metadata.clone()
        ));

        // Verify intent was created
        let intent = ChainGhost::intent_by_id(0).expect("Intent should exist");
        assert_eq!(intent.intent_id, 0);
        assert_eq!(intent.account, 1);
        assert_eq!(intent.status, IntentStatus::Pending);
        assert_eq!(intent.metadata.to_vec(), metadata);

        // Verify intent was added to account's list
        let account_intents = ChainGhost::intents_by_account(1);
        assert_eq!(account_intents.len(), 1);
        assert_eq!(account_intents[0], 0);

        // Verify next intent ID was incremented
        assert_eq!(ChainGhost::next_intent_id(), 1);

        // Verify event was emitted
        System::assert_last_event(
            Event::IntentExecuted {
                intent_id: 0,
                account: 1,
                timestamp: 1,
            }
            .into(),
        );
    });
}

#[test]
fn execute_multiple_intents_works() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);

        // Execute first intent
        assert_ok!(ChainGhost::execute_intent(
            RuntimeOrigin::signed(1),
            b"First intent".to_vec()
        ));

        // Execute second intent
        assert_ok!(ChainGhost::execute_intent(
            RuntimeOrigin::signed(1),
            b"Second intent".to_vec()
        ));

        // Verify both intents were created
        assert!(ChainGhost::intent_by_id(0).is_some());
        assert!(ChainGhost::intent_by_id(1).is_some());

        // Verify account has both intents
        let account_intents = ChainGhost::intents_by_account(1);
        assert_eq!(account_intents.len(), 2);
        assert_eq!(account_intents[0], 0);
        assert_eq!(account_intents[1], 1);
    });
}

#[test]
fn execute_intent_max_intents_per_account_fails() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);

        // Fill up account's intent slots
        for i in 0..100 {
            assert_ok!(ChainGhost::execute_intent(
                RuntimeOrigin::signed(1),
                format!("Intent {}", i).as_bytes().to_vec()
            ));
        }

        // Verify account has 100 intents
        let account_intents = ChainGhost::intents_by_account(1);
        assert_eq!(account_intents.len(), 100);

        // Try to add one more intent (should fail)
        assert_noop!(
            ChainGhost::execute_intent(RuntimeOrigin::signed(1), b"Extra intent".to_vec()),
            Error::<Test>::MaxIntentsPerAccountExceeded
        );
    });
}

#[test]
fn record_journey_works() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);

        // Create intent first
        assert_ok!(ChainGhost::execute_intent(
            RuntimeOrigin::signed(1),
            b"Test intent".to_vec()
        ));

        System::set_block_number(2);

        // Record journey step
        let description = b"Step 1: Transaction initiated".to_vec();
        assert_ok!(ChainGhost::record_journey(
            RuntimeOrigin::signed(1),
            0,
            description.clone()
        ));

        // Verify journey step was recorded
        let journey_steps = ChainGhost::journey_by_intent(0);
        assert_eq!(journey_steps.len(), 1);
        assert_eq!(journey_steps[0].step_id, 0);
        assert_eq!(journey_steps[0].description.to_vec(), description);
        assert_eq!(journey_steps[0].timestamp, 2);

        // Verify event was emitted
        System::assert_last_event(
            Event::JourneyRecorded {
                intent_id: 0,
                step_count: 1,
            }
            .into(),
        );
    });
}

#[test]
fn record_multiple_journey_steps_works() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);

        // Create intent
        assert_ok!(ChainGhost::execute_intent(
            RuntimeOrigin::signed(1),
            b"Test intent".to_vec()
        ));

        // Record multiple journey steps
        for i in 0..5 {
            System::set_block_number(i + 2);
            assert_ok!(ChainGhost::record_journey(
                RuntimeOrigin::signed(1),
                0,
                format!("Step {}", i).as_bytes().to_vec()
            ));
        }

        // Verify all steps were recorded
        let journey_steps = ChainGhost::journey_by_intent(0);
        assert_eq!(journey_steps.len(), 5);

        // Verify step IDs are sequential
        for i in 0..5 {
            assert_eq!(journey_steps[i].step_id, i as u32);
        }
    });
}

#[test]
fn record_journey_intent_not_found_fails() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);

        // Try to record journey for non-existent intent
        assert_noop!(
            ChainGhost::record_journey(RuntimeOrigin::signed(1), 999, b"Step 1".to_vec()),
            Error::<Test>::IntentNotFound
        );
    });
}

#[test]
fn record_journey_not_owner_fails() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);

        // Account 1 creates intent
        assert_ok!(ChainGhost::execute_intent(
            RuntimeOrigin::signed(1),
            b"Test intent".to_vec()
        ));

        // Account 2 tries to record journey (should fail)
        assert_noop!(
            ChainGhost::record_journey(RuntimeOrigin::signed(2), 0, b"Step 1".to_vec()),
            Error::<Test>::NotIntentOwner
        );
    });
}

#[test]
fn record_journey_max_steps_exceeded_fails() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);

        // Create intent
        assert_ok!(ChainGhost::execute_intent(
            RuntimeOrigin::signed(1),
            b"Test intent".to_vec()
        ));

        // Fill up journey steps (max is 50)
        for i in 0..50 {
            assert_ok!(ChainGhost::record_journey(
                RuntimeOrigin::signed(1),
                0,
                format!("Step {}", i).as_bytes().to_vec()
            ));
        }

        // Verify we have 50 steps
        let journey_steps = ChainGhost::journey_by_intent(0);
        assert_eq!(journey_steps.len(), 50);

        // Try to add one more step (should fail)
        assert_noop!(
            ChainGhost::record_journey(RuntimeOrigin::signed(1), 0, b"Extra step".to_vec()),
            Error::<Test>::MaxJourneyStepsExceeded
        );
    });
}

#[test]
fn update_intent_status_works() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);

        // Create intent
        assert_ok!(ChainGhost::execute_intent(
            RuntimeOrigin::signed(1),
            b"Test intent".to_vec()
        ));

        // Verify initial status is Pending
        let intent = ChainGhost::intent_by_id(0).unwrap();
        assert_eq!(intent.status, IntentStatus::Pending);

        // Update status to Executed
        assert_ok!(ChainGhost::update_intent_status(
            RuntimeOrigin::signed(1),
            0,
            IntentStatus::Executed.as_u8()
        ));

        // Verify status was updated
        let intent = ChainGhost::intent_by_id(0).unwrap();
        assert_eq!(intent.status, IntentStatus::Executed);

        // Verify event was emitted
        System::assert_last_event(
            Event::IntentStatusUpdated {
                intent_id: 0,
                old_status: IntentStatus::Pending.as_u8(),
                new_status: IntentStatus::Executed.as_u8(),
            }
            .into(),
        );
    });
}

#[test]
fn update_intent_status_intent_not_found_fails() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);

        // Try to update non-existent intent
        assert_noop!(
            ChainGhost::update_intent_status(RuntimeOrigin::signed(1), 999, IntentStatus::Executed.as_u8()),
            Error::<Test>::IntentNotFound
        );
    });
}

#[test]
fn update_intent_status_not_owner_fails() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);

        // Account 1 creates intent
        assert_ok!(ChainGhost::execute_intent(
            RuntimeOrigin::signed(1),
            b"Test intent".to_vec()
        ));

        // Account 2 tries to update status (should fail)
        assert_noop!(
            ChainGhost::update_intent_status(RuntimeOrigin::signed(2), 0, IntentStatus::Executed.as_u8()),
            Error::<Test>::NotIntentOwner
        );
    });
}

#[test]
fn update_intent_status_to_failed_works() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);

        // Create intent
        assert_ok!(ChainGhost::execute_intent(
            RuntimeOrigin::signed(1),
            b"Test intent".to_vec()
        ));

        // Update status to Failed
        assert_ok!(ChainGhost::update_intent_status(
            RuntimeOrigin::signed(1),
            0,
            IntentStatus::Failed.as_u8()
        ));

        // Verify status was updated
        let intent = ChainGhost::intent_by_id(0).unwrap();
        assert_eq!(intent.status, IntentStatus::Failed);
    });
}

#[test]
fn complete_workflow_execute_journey_status_works() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);

        // Step 1: Execute intent
        assert_ok!(ChainGhost::execute_intent(
            RuntimeOrigin::signed(1),
            b"Swap 100 USDC to ETH on Arbitrum".to_vec()
        ));

        // Step 2: Record journey steps
        System::set_block_number(2);
        assert_ok!(ChainGhost::record_journey(
            RuntimeOrigin::signed(1),
            0,
            b"Analyzing best routes...".to_vec()
        ));

        System::set_block_number(3);
        assert_ok!(ChainGhost::record_journey(
            RuntimeOrigin::signed(1),
            0,
            b"Route selected: Arbitrum via Uniswap V3".to_vec()
        ));

        System::set_block_number(4);
        assert_ok!(ChainGhost::record_journey(
            RuntimeOrigin::signed(1),
            0,
            b"Transaction submitted to mempool".to_vec()
        ));

        // Step 3: Update status to Executed
        System::set_block_number(5);
        assert_ok!(ChainGhost::update_intent_status(
            RuntimeOrigin::signed(1),
            0,
            IntentStatus::Executed.as_u8()
        ));

        // Verify final state
        let intent = ChainGhost::intent_by_id(0).unwrap();
        assert_eq!(intent.status, IntentStatus::Executed);

        let journey_steps = ChainGhost::journey_by_intent(0);
        assert_eq!(journey_steps.len(), 3);
    });
}

#[test]
fn metadata_truncation_works() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);

        // Create metadata larger than 256 bytes
        let large_metadata = vec![b'A'; 300];

        // Execute intent with large metadata
        assert_ok!(ChainGhost::execute_intent(
            RuntimeOrigin::signed(1),
            large_metadata.clone()
        ));

        // Verify metadata was truncated to 256 bytes
        let intent = ChainGhost::intent_by_id(0).unwrap();
        assert_eq!(intent.metadata.len(), 256);
    });
}

#[test]
fn journey_description_truncation_works() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);

        // Create intent
        assert_ok!(ChainGhost::execute_intent(
            RuntimeOrigin::signed(1),
            b"Test intent".to_vec()
        ));

        // Create description larger than 512 bytes
        let large_description = vec![b'B'; 600];

        // Record journey with large description
        assert_ok!(ChainGhost::record_journey(
            RuntimeOrigin::signed(1),
            0,
            large_description.clone()
        ));

        // Verify description was truncated to 512 bytes
        let journey_steps = ChainGhost::journey_by_intent(0);
        assert_eq!(journey_steps[0].description.len(), 512);
    });
}

#[test]
fn multiple_accounts_independent_intents_works() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);

        // Account 1 creates intents
        assert_ok!(ChainGhost::execute_intent(
            RuntimeOrigin::signed(1),
            b"Account 1 intent 1".to_vec()
        ));
        assert_ok!(ChainGhost::execute_intent(
            RuntimeOrigin::signed(1),
            b"Account 1 intent 2".to_vec()
        ));

        // Account 2 creates intents
        assert_ok!(ChainGhost::execute_intent(
            RuntimeOrigin::signed(2),
            b"Account 2 intent 1".to_vec()
        ));

        // Verify account 1 has 2 intents
        let account1_intents = ChainGhost::intents_by_account(1);
        assert_eq!(account1_intents.len(), 2);

        // Verify account 2 has 1 intent
        let account2_intents = ChainGhost::intents_by_account(2);
        assert_eq!(account2_intents.len(), 1);

        // Verify intent ownership
        let intent0 = ChainGhost::intent_by_id(0).unwrap();
        assert_eq!(intent0.account, 1);

        let intent2 = ChainGhost::intent_by_id(2).unwrap();
        assert_eq!(intent2.account, 2);
    });
}
