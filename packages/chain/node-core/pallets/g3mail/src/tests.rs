use crate::{mock::*, Error, Event, InboxCount, MessagesByRecipient, NextMessageId, PublicKeys};
use frame_support::{assert_noop, assert_ok};

// Helper function to create a valid public key
fn create_valid_public_key(size: usize) -> Vec<u8> {
    vec![1u8; size]
}

// Helper function to create a valid CID
fn create_valid_cid(size: usize) -> Vec<u8> {
    vec![2u8; size]
}

#[test]
fn register_public_key_works() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);

        let account = 1u64;
        let public_key = create_valid_public_key(64);

        // Register public key
        assert_ok!(G3Mail::register_public_key(
            RuntimeOrigin::signed(account),
            public_key.clone()
        ));

        // Verify storage
        assert!(PublicKeys::<Test>::contains_key(account));

        // Verify event
        let key_hash = sp_core::H256::from(sp_io::hashing::blake2_256(&public_key));
        System::assert_last_event(Event::PublicKeyRegistered { account, key_hash }.into());
    });
}

#[test]
fn register_public_key_fails_if_already_registered() {
    new_test_ext().execute_with(|| {
        let account = 1u64;
        let public_key = create_valid_public_key(64);

        // Register first time
        assert_ok!(G3Mail::register_public_key(
            RuntimeOrigin::signed(account),
            public_key.clone()
        ));

        // Try to register again
        assert_noop!(
            G3Mail::register_public_key(RuntimeOrigin::signed(account), public_key),
            Error::<Test>::PublicKeyAlreadyRegistered
        );
    });
}

#[test]
fn register_public_key_fails_if_too_short() {
    new_test_ext().execute_with(|| {
        let account = 1u64;
        let public_key = create_valid_public_key(31); // Less than 32 bytes

        assert_noop!(
            G3Mail::register_public_key(RuntimeOrigin::signed(account), public_key),
            Error::<Test>::InvalidPublicKeyLength
        );
    });
}

#[test]
fn register_public_key_fails_if_too_long() {
    new_test_ext().execute_with(|| {
        let account = 1u64;
        let public_key = create_valid_public_key(129); // More than 128 bytes

        assert_noop!(
            G3Mail::register_public_key(RuntimeOrigin::signed(account), public_key),
            Error::<Test>::InvalidPublicKeyLength
        );
    });
}

#[test]
fn send_message_works() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);

        let sender = 1u64;
        let recipient = 2u64;
        let sender_key = create_valid_public_key(64);
        let recipient_key = create_valid_public_key(64);
        let cid = create_valid_cid(46);

        // Register public keys
        assert_ok!(G3Mail::register_public_key(
            RuntimeOrigin::signed(sender),
            sender_key
        ));
        assert_ok!(G3Mail::register_public_key(
            RuntimeOrigin::signed(recipient),
            recipient_key
        ));

        // Send message
        assert_ok!(G3Mail::send_message(
            RuntimeOrigin::signed(sender),
            recipient,
            cid.clone()
        ));

        // Verify storage
        let message_id = 0u64;
        assert!(MessagesByRecipient::<Test>::contains_key(
            recipient, message_id
        ));

        let message = MessagesByRecipient::<Test>::get(recipient, message_id).unwrap();
        assert_eq!(message.sender, sender);
        assert_eq!(message.recipient, recipient);
        assert_eq!(message.message_id, message_id);
        assert!(!message.read);

        // Verify inbox count
        assert_eq!(InboxCount::<Test>::get(recipient), 1);

        // Verify next message ID
        assert_eq!(NextMessageId::<Test>::get(), 1);

        // Verify event
        System::assert_last_event(
            Event::MessageSent {
                message_id,
                sender,
                recipient,
                cid: cid.try_into().unwrap(),
                timestamp: 1,
            }
            .into(),
        );
    });
}

#[test]
fn send_message_fails_if_recipient_has_no_public_key() {
    new_test_ext().execute_with(|| {
        let sender = 1u64;
        let recipient = 2u64;
        let sender_key = create_valid_public_key(64);
        let cid = create_valid_cid(46);

        // Only register sender's key
        assert_ok!(G3Mail::register_public_key(
            RuntimeOrigin::signed(sender),
            sender_key
        ));

        // Try to send message
        assert_noop!(
            G3Mail::send_message(RuntimeOrigin::signed(sender), recipient, cid),
            Error::<Test>::RecipientPublicKeyNotFound
        );
    });
}

#[test]
fn send_message_fails_if_cid_is_empty() {
    new_test_ext().execute_with(|| {
        let sender = 1u64;
        let recipient = 2u64;
        let sender_key = create_valid_public_key(64);
        let recipient_key = create_valid_public_key(64);
        let cid = vec![];

        // Register public keys
        assert_ok!(G3Mail::register_public_key(
            RuntimeOrigin::signed(sender),
            sender_key
        ));
        assert_ok!(G3Mail::register_public_key(
            RuntimeOrigin::signed(recipient),
            recipient_key
        ));

        // Try to send message with empty CID
        assert_noop!(
            G3Mail::send_message(RuntimeOrigin::signed(sender), recipient, cid),
            Error::<Test>::InvalidCidLength
        );
    });
}

#[test]
fn send_message_fails_if_cid_too_long() {
    new_test_ext().execute_with(|| {
        let sender = 1u64;
        let recipient = 2u64;
        let sender_key = create_valid_public_key(64);
        let recipient_key = create_valid_public_key(64);
        let cid = create_valid_cid(129); // Exceeds MaxCidLength

        // Register public keys
        assert_ok!(G3Mail::register_public_key(
            RuntimeOrigin::signed(sender),
            sender_key
        ));
        assert_ok!(G3Mail::register_public_key(
            RuntimeOrigin::signed(recipient),
            recipient_key
        ));

        // Try to send message
        assert_noop!(
            G3Mail::send_message(RuntimeOrigin::signed(sender), recipient, cid),
            Error::<Test>::InvalidCidLength
        );
    });
}

#[test]
fn send_message_fails_if_inbox_limit_exceeded() {
    new_test_ext().execute_with(|| {
        let sender = 1u64;
        let recipient = 2u64;
        let sender_key = create_valid_public_key(64);
        let recipient_key = create_valid_public_key(64);

        // Register public keys
        assert_ok!(G3Mail::register_public_key(
            RuntimeOrigin::signed(sender),
            sender_key
        ));
        assert_ok!(G3Mail::register_public_key(
            RuntimeOrigin::signed(recipient),
            recipient_key
        ));

        // Set inbox count to max
        InboxCount::<Test>::insert(recipient, 1000);

        // Try to send message
        let cid = create_valid_cid(46);
        assert_noop!(
            G3Mail::send_message(RuntimeOrigin::signed(sender), recipient, cid),
            Error::<Test>::MaxInboxMessagesExceeded
        );
    });
}

#[test]
fn mark_message_read_works() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);

        let sender = 1u64;
        let recipient = 2u64;
        let sender_key = create_valid_public_key(64);
        let recipient_key = create_valid_public_key(64);
        let cid = create_valid_cid(46);

        // Register public keys and send message
        assert_ok!(G3Mail::register_public_key(
            RuntimeOrigin::signed(sender),
            sender_key
        ));
        assert_ok!(G3Mail::register_public_key(
            RuntimeOrigin::signed(recipient),
            recipient_key
        ));
        assert_ok!(G3Mail::send_message(
            RuntimeOrigin::signed(sender),
            recipient,
            cid
        ));

        let message_id = 0u64;

        // Verify message is unread
        let message = MessagesByRecipient::<Test>::get(recipient, message_id).unwrap();
        assert!(!message.read);

        // Mark as read
        assert_ok!(G3Mail::mark_message_read(
            RuntimeOrigin::signed(recipient),
            message_id
        ));

        // Verify message is read
        let message = MessagesByRecipient::<Test>::get(recipient, message_id).unwrap();
        assert!(message.read);

        // Verify event
        System::assert_last_event(
            Event::MessageRead {
                message_id,
                recipient,
            }
            .into(),
        );
    });
}

#[test]
fn mark_message_read_fails_if_message_not_found() {
    new_test_ext().execute_with(|| {
        let account = 1u64;
        let message_id = 999u64;

        assert_noop!(
            G3Mail::mark_message_read(RuntimeOrigin::signed(account), message_id),
            Error::<Test>::MessageNotFound
        );
    });
}

#[test]
fn mark_message_read_fails_if_not_recipient() {
    new_test_ext().execute_with(|| {
        let sender = 1u64;
        let recipient = 2u64;
        let other = 3u64;
        let sender_key = create_valid_public_key(64);
        let recipient_key = create_valid_public_key(64);
        let cid = create_valid_cid(46);

        // Register public keys and send message
        assert_ok!(G3Mail::register_public_key(
            RuntimeOrigin::signed(sender),
            sender_key
        ));
        assert_ok!(G3Mail::register_public_key(
            RuntimeOrigin::signed(recipient),
            recipient_key
        ));
        assert_ok!(G3Mail::send_message(
            RuntimeOrigin::signed(sender),
            recipient,
            cid
        ));

        let message_id = 0u64;

        // Try to mark as read by non-recipient
        assert_noop!(
            G3Mail::mark_message_read(RuntimeOrigin::signed(other), message_id),
            Error::<Test>::MessageNotFound
        );
    });
}

#[test]
fn complete_message_flow_works() {
    new_test_ext().execute_with(|| {
        System::set_block_number(1);

        // Setup accounts
        let alice = 1u64;
        let bob = 2u64;
        let alice_key = create_valid_public_key(64);
        let bob_key = create_valid_public_key(64);

        // Step 1: Both users register public keys
        assert_ok!(G3Mail::register_public_key(
            RuntimeOrigin::signed(alice),
            alice_key
        ));
        assert_ok!(G3Mail::register_public_key(
            RuntimeOrigin::signed(bob),
            bob_key
        ));

        // Step 2: Alice sends message to Bob
        let message_1_cid = create_valid_cid(46);
        assert_ok!(G3Mail::send_message(
            RuntimeOrigin::signed(alice),
            bob,
            message_1_cid
        ));
        assert_eq!(InboxCount::<Test>::get(bob), 1);

        // Step 3: Bob sends message to Alice
        let message_2_cid = create_valid_cid(50);
        assert_ok!(G3Mail::send_message(
            RuntimeOrigin::signed(bob),
            alice,
            message_2_cid
        ));
        assert_eq!(InboxCount::<Test>::get(alice), 1);

        // Step 4: Bob marks Alice's message as read
        assert_ok!(G3Mail::mark_message_read(RuntimeOrigin::signed(bob), 0));
        let message = MessagesByRecipient::<Test>::get(bob, 0).unwrap();
        assert!(message.read);

        // Step 5: Alice marks Bob's message as read
        assert_ok!(G3Mail::mark_message_read(RuntimeOrigin::signed(alice), 1));
        let message = MessagesByRecipient::<Test>::get(alice, 1).unwrap();
        assert!(message.read);

        // Verify final state
        assert_eq!(NextMessageId::<Test>::get(), 2);
        assert_eq!(InboxCount::<Test>::get(alice), 1);
        assert_eq!(InboxCount::<Test>::get(bob), 1);
    });
}

#[test]
fn multiple_messages_to_same_recipient_works() {
    new_test_ext().execute_with(|| {
        let sender = 1u64;
        let recipient = 2u64;
        let sender_key = create_valid_public_key(64);
        let recipient_key = create_valid_public_key(64);

        // Register public keys
        assert_ok!(G3Mail::register_public_key(
            RuntimeOrigin::signed(sender),
            sender_key
        ));
        assert_ok!(G3Mail::register_public_key(
            RuntimeOrigin::signed(recipient),
            recipient_key
        ));

        // Send 5 messages
        for i in 0..5 {
            let cid = create_valid_cid(46 + i);
            assert_ok!(G3Mail::send_message(
                RuntimeOrigin::signed(sender),
                recipient,
                cid
            ));
        }

        // Verify inbox count
        assert_eq!(InboxCount::<Test>::get(recipient), 5);

        // Verify next message ID
        assert_eq!(NextMessageId::<Test>::get(), 5);

        // Verify all messages exist
        for i in 0..5 {
            assert!(MessagesByRecipient::<Test>::contains_key(recipient, i));
        }
    });
}
