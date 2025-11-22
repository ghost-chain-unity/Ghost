use std::sync::Arc;

use jsonrpsee::{core::RpcResult, proc_macros::rpc, types::ErrorObjectOwned};
use sp_api::ProvideRuntimeApi;
use sp_blockchain::HeaderBackend;
use sp_runtime::traits::Block as BlockT;

use ghost_runtime::{opaque::Block, AccountId, BlockNumber};

use super::types::{IntentResponse, IntentStatus, JourneyStepResponse, MessageResponse};

pub use ghost_runtime::apis::ghost_protocol::{
    ChainGhostRuntimeApi, G3MailRuntimeApi, GhonityRuntimeApi,
};

fn runtime_error_into_rpc_error(err: impl std::fmt::Display) -> ErrorObjectOwned {
    ErrorObjectOwned::owned(
        jsonrpsee::types::error::ErrorCode::InternalError.code(),
        "Runtime API error".to_string(),
        Some(format!("{}", err)),
    )
}

#[rpc(client, server)]
pub trait ChainGhostApi<BlockHash, AccountId, BlockNumber> {
    #[method(name = "chainghost_getIntent")]
    fn get_intent(
        &self,
        intent_id: u64,
        at: Option<BlockHash>,
    ) -> RpcResult<Option<IntentResponse<AccountId, BlockNumber>>>;

    #[method(name = "chainghost_getIntentsByAccount")]
    fn get_intents_by_account(
        &self,
        account: AccountId,
        at: Option<BlockHash>,
    ) -> RpcResult<Vec<u64>>;

    #[method(name = "chainghost_getJourneySteps")]
    fn get_journey_steps(
        &self,
        intent_id: u64,
        at: Option<BlockHash>,
    ) -> RpcResult<Vec<JourneyStepResponse<BlockNumber>>>;

    #[method(name = "chainghost_getIntentStatus")]
    fn get_intent_status(
        &self,
        intent_id: u64,
        at: Option<BlockHash>,
    ) -> RpcResult<Option<IntentStatus>>;
}

#[rpc(client, server)]
pub trait G3MailApi<BlockHash, AccountId, BlockNumber> {
    #[method(name = "g3mail_getPublicKey")]
    fn get_public_key(
        &self,
        account: AccountId,
        at: Option<BlockHash>,
    ) -> RpcResult<Option<Vec<u8>>>;

    #[method(name = "g3mail_getMessagesByRecipient")]
    fn get_messages_by_recipient(
        &self,
        recipient: AccountId,
        at: Option<BlockHash>,
    ) -> RpcResult<Vec<(u64, MessageResponse<AccountId, BlockNumber>)>>;

    #[method(name = "g3mail_getMessage")]
    fn get_message(
        &self,
        recipient: AccountId,
        message_id: u64,
        at: Option<BlockHash>,
    ) -> RpcResult<Option<MessageResponse<AccountId, BlockNumber>>>;

    #[method(name = "g3mail_getInboxCount")]
    fn get_inbox_count(&self, account: AccountId, at: Option<BlockHash>) -> RpcResult<u32>;
}

#[rpc(client, server)]
pub trait GhonityApi<BlockHash, AccountId> {
    #[method(name = "ghonity_isFollowing")]
    fn is_following(
        &self,
        follower: AccountId,
        followee: AccountId,
        at: Option<BlockHash>,
    ) -> RpcResult<bool>;

    #[method(name = "ghonity_getFollowerCount")]
    fn get_follower_count(&self, account: AccountId, at: Option<BlockHash>) -> RpcResult<u32>;

    #[method(name = "ghonity_getFollowingCount")]
    fn get_following_count(&self, account: AccountId, at: Option<BlockHash>) -> RpcResult<u32>;

    #[method(name = "ghonity_getReputationScore")]
    fn get_reputation_score(&self, account: AccountId, at: Option<BlockHash>) -> RpcResult<u32>;
}

pub struct ChainGhost<C, Block> {
    client: Arc<C>,
    _marker: std::marker::PhantomData<Block>,
}

impl<C, Block> ChainGhost<C, Block> {
    pub fn new(client: Arc<C>) -> Self {
        Self {
            client,
            _marker: Default::default(),
        }
    }
}

impl<C> ChainGhostApiServer<<Block as BlockT>::Hash, AccountId, BlockNumber>
    for ChainGhost<C, Block>
where
    C: ProvideRuntimeApi<Block> + HeaderBackend<Block> + Send + Sync + 'static,
    C::Api: ChainGhostRuntimeApi<Block, AccountId, BlockNumber>,
{
    fn get_intent(
        &self,
        intent_id: u64,
        at: Option<<Block as BlockT>::Hash>,
    ) -> RpcResult<Option<IntentResponse<AccountId, BlockNumber>>> {
        let api = self.client.runtime_api();
        let at_hash = at.unwrap_or_else(|| self.client.info().best_hash);

        let intent_data = api
            .get_intent(at_hash, intent_id)
            .map_err(runtime_error_into_rpc_error)?;

        Ok(intent_data.map(|data| IntentResponse {
            intent_id: data.intent_id,
            account: data.account,
            status: match data.status {
                ghost_runtime::IntentStatus::Pending => IntentStatus::Pending,
                ghost_runtime::IntentStatus::Executed => IntentStatus::Executed,
                ghost_runtime::IntentStatus::Failed => IntentStatus::Failed,
            },
            timestamp: data.timestamp,
            metadata: data.metadata,
        }))
    }

    fn get_intents_by_account(
        &self,
        account: AccountId,
        at: Option<<Block as BlockT>::Hash>,
    ) -> RpcResult<Vec<u64>> {
        let api = self.client.runtime_api();
        let at_hash = at.unwrap_or_else(|| self.client.info().best_hash);

        api.get_intents_by_account(at_hash, account)
            .map_err(runtime_error_into_rpc_error)
    }

    fn get_journey_steps(
        &self,
        intent_id: u64,
        at: Option<<Block as BlockT>::Hash>,
    ) -> RpcResult<Vec<JourneyStepResponse<BlockNumber>>> {
        let api = self.client.runtime_api();
        let at_hash = at.unwrap_or_else(|| self.client.info().best_hash);

        let steps = api
            .get_journey_steps(at_hash, intent_id)
            .map_err(runtime_error_into_rpc_error)?;

        Ok(steps
            .into_iter()
            .map(|step| JourneyStepResponse {
                step_id: step.step_id,
                description: step.description,
                timestamp: step.timestamp,
            })
            .collect())
    }

    fn get_intent_status(
        &self,
        intent_id: u64,
        at: Option<<Block as BlockT>::Hash>,
    ) -> RpcResult<Option<IntentStatus>> {
        let api = self.client.runtime_api();
        let at_hash = at.unwrap_or_else(|| self.client.info().best_hash);

        let status = api
            .get_intent_status(at_hash, intent_id)
            .map_err(runtime_error_into_rpc_error)?;

        Ok(status.map(|s| match s {
            ghost_runtime::IntentStatus::Pending => IntentStatus::Pending,
            ghost_runtime::IntentStatus::Executed => IntentStatus::Executed,
            ghost_runtime::IntentStatus::Failed => IntentStatus::Failed,
        }))
    }
}

pub struct G3Mail<C, Block> {
    client: Arc<C>,
    _marker: std::marker::PhantomData<Block>,
}

impl<C, Block> G3Mail<C, Block> {
    pub fn new(client: Arc<C>) -> Self {
        Self {
            client,
            _marker: Default::default(),
        }
    }
}

impl<C> G3MailApiServer<<Block as BlockT>::Hash, AccountId, BlockNumber> for G3Mail<C, Block>
where
    C: ProvideRuntimeApi<Block> + HeaderBackend<Block> + Send + Sync + 'static,
    C::Api: G3MailRuntimeApi<Block, AccountId, BlockNumber>,
{
    fn get_public_key(
        &self,
        account: AccountId,
        at: Option<<Block as BlockT>::Hash>,
    ) -> RpcResult<Option<Vec<u8>>> {
        let api = self.client.runtime_api();
        let at_hash = at.unwrap_or_else(|| self.client.info().best_hash);

        api.get_public_key(at_hash, account)
            .map_err(runtime_error_into_rpc_error)
    }

    fn get_messages_by_recipient(
        &self,
        recipient: AccountId,
        at: Option<<Block as BlockT>::Hash>,
    ) -> RpcResult<Vec<(u64, MessageResponse<AccountId, BlockNumber>)>> {
        let api = self.client.runtime_api();
        let at_hash = at.unwrap_or_else(|| self.client.info().best_hash);

        let messages = api
            .get_messages_by_recipient(at_hash, recipient)
            .map_err(runtime_error_into_rpc_error)?;

        Ok(messages
            .into_iter()
            .map(|(id, msg)| {
                (
                    id,
                    MessageResponse {
                        message_id: msg.message_id,
                        sender: msg.sender,
                        recipient: msg.recipient,
                        cid: msg.cid,
                        timestamp: msg.timestamp,
                        read: msg.read,
                    },
                )
            })
            .collect())
    }

    fn get_message(
        &self,
        recipient: AccountId,
        message_id: u64,
        at: Option<<Block as BlockT>::Hash>,
    ) -> RpcResult<Option<MessageResponse<AccountId, BlockNumber>>> {
        let api = self.client.runtime_api();
        let at_hash = at.unwrap_or_else(|| self.client.info().best_hash);

        let message = api
            .get_message(at_hash, recipient, message_id)
            .map_err(runtime_error_into_rpc_error)?;

        Ok(message.map(|msg| MessageResponse {
            message_id: msg.message_id,
            sender: msg.sender,
            recipient: msg.recipient,
            cid: msg.cid,
            timestamp: msg.timestamp,
            read: msg.read,
        }))
    }

    fn get_inbox_count(
        &self,
        account: AccountId,
        at: Option<<Block as BlockT>::Hash>,
    ) -> RpcResult<u32> {
        let api = self.client.runtime_api();
        let at_hash = at.unwrap_or_else(|| self.client.info().best_hash);

        api.get_inbox_count(at_hash, account)
            .map_err(runtime_error_into_rpc_error)
    }
}

pub struct Ghonity<C, Block> {
    client: Arc<C>,
    _marker: std::marker::PhantomData<Block>,
}

impl<C, Block> Ghonity<C, Block> {
    pub fn new(client: Arc<C>) -> Self {
        Self {
            client,
            _marker: Default::default(),
        }
    }
}

impl<C> GhonityApiServer<<Block as BlockT>::Hash, AccountId> for Ghonity<C, Block>
where
    C: ProvideRuntimeApi<Block> + HeaderBackend<Block> + Send + Sync + 'static,
    C::Api: GhonityRuntimeApi<Block, AccountId>,
{
    fn is_following(
        &self,
        follower: AccountId,
        followee: AccountId,
        at: Option<<Block as BlockT>::Hash>,
    ) -> RpcResult<bool> {
        let api = self.client.runtime_api();
        let at_hash = at.unwrap_or_else(|| self.client.info().best_hash);

        api.is_following(at_hash, follower, followee)
            .map_err(runtime_error_into_rpc_error)
    }

    fn get_follower_count(
        &self,
        account: AccountId,
        at: Option<<Block as BlockT>::Hash>,
    ) -> RpcResult<u32> {
        let api = self.client.runtime_api();
        let at_hash = at.unwrap_or_else(|| self.client.info().best_hash);

        api.get_follower_count(at_hash, account)
            .map_err(runtime_error_into_rpc_error)
    }

    fn get_following_count(
        &self,
        account: AccountId,
        at: Option<<Block as BlockT>::Hash>,
    ) -> RpcResult<u32> {
        let api = self.client.runtime_api();
        let at_hash = at.unwrap_or_else(|| self.client.info().best_hash);

        api.get_following_count(at_hash, account)
            .map_err(runtime_error_into_rpc_error)
    }

    fn get_reputation_score(
        &self,
        account: AccountId,
        at: Option<<Block as BlockT>::Hash>,
    ) -> RpcResult<u32> {
        let api = self.client.runtime_api();
        let at_hash = at.unwrap_or_else(|| self.client.info().best_hash);

        api.get_reputation_score(at_hash, account)
            .map_err(runtime_error_into_rpc_error)
    }
}
