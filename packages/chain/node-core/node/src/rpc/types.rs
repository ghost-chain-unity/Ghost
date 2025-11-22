use codec::{Decode, Encode};
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize, Encode, Decode)]
#[serde(rename_all = "camelCase")]
pub enum IntentStatus {
    Pending,
    Executed,
    Failed,
}

#[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize, Encode, Decode)]
#[serde(rename_all = "camelCase")]
pub struct IntentResponse<AccountId, BlockNumber> {
    pub intent_id: u64,
    pub account: AccountId,
    pub status: IntentStatus,
    pub timestamp: BlockNumber,
    #[serde(with = "serde_bytes")]
    pub metadata: Vec<u8>,
}

#[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize, Encode, Decode)]
#[serde(rename_all = "camelCase")]
pub struct JourneyStepResponse<BlockNumber> {
    pub step_id: u32,
    #[serde(with = "serde_bytes")]
    pub description: Vec<u8>,
    pub timestamp: BlockNumber,
}

#[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize, Encode, Decode)]
#[serde(rename_all = "camelCase")]
pub struct MessageResponse<AccountId, BlockNumber> {
    pub message_id: u64,
    pub sender: AccountId,
    pub recipient: AccountId,
    #[serde(with = "serde_bytes")]
    pub cid: Vec<u8>,
    pub timestamp: BlockNumber,
    pub read: bool,
}
