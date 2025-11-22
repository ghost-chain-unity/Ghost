use codec::{Decode, Encode};
use scale_info::TypeInfo;
use sp_api::decl_runtime_apis;
use sp_std::vec::Vec;

pub use pallet_chainghost::{IntentId, IntentStatus};
pub use pallet_g3mail::MessageId;

#[derive(Clone, Encode, Decode, Eq, PartialEq, TypeInfo)]
#[cfg_attr(feature = "std", derive(Debug))]
pub struct IntentData<AccountId, BlockNumber> {
    pub intent_id: IntentId,
    pub account: AccountId,
    pub status: IntentStatus,
    pub timestamp: BlockNumber,
    pub metadata: Vec<u8>,
}

#[derive(Clone, Encode, Decode, Eq, PartialEq, TypeInfo)]
#[cfg_attr(feature = "std", derive(Debug))]
pub struct JourneyStepData<BlockNumber> {
    pub step_id: u32,
    pub description: Vec<u8>,
    pub timestamp: BlockNumber,
}

#[derive(Clone, Encode, Decode, Eq, PartialEq, TypeInfo)]
#[cfg_attr(feature = "std", derive(Debug))]
pub struct MessagePointerData<AccountId, BlockNumber> {
    pub message_id: MessageId,
    pub sender: AccountId,
    pub recipient: AccountId,
    pub cid: Vec<u8>,
    pub timestamp: BlockNumber,
    pub read: bool,
}

decl_runtime_apis! {
    pub trait ChainGhostRuntimeApi<AccountId, BlockNumber>
    where
        AccountId: Encode + Decode,
        BlockNumber: Encode + Decode,
    {
        fn get_intent(intent_id: IntentId) -> Option<IntentData<AccountId, BlockNumber>>;

        fn get_intents_by_account(account: AccountId) -> Vec<IntentId>;

        fn get_journey_steps(intent_id: IntentId) -> Vec<JourneyStepData<BlockNumber>>;

        fn get_intent_status(intent_id: IntentId) -> Option<IntentStatus>;
    }

    pub trait G3MailRuntimeApi<AccountId, BlockNumber>
    where
        AccountId: Encode + Decode,
        BlockNumber: Encode + Decode,
    {
        fn get_public_key(account: AccountId) -> Option<Vec<u8>>;

        fn get_messages_by_recipient(recipient: AccountId) -> Vec<(MessageId, MessagePointerData<AccountId, BlockNumber>)>;

        fn get_message(recipient: AccountId, message_id: MessageId) -> Option<MessagePointerData<AccountId, BlockNumber>>;

        fn get_inbox_count(account: AccountId) -> u32;
    }

    pub trait GhonityRuntimeApi<AccountId>
    where
        AccountId: Encode + Decode,
    {
        fn is_following(follower: AccountId, followee: AccountId) -> bool;

        fn get_follower_count(account: AccountId) -> u32;

        fn get_following_count(account: AccountId) -> u32;

        fn get_reputation_score(account: AccountId) -> u32;
    }
}
