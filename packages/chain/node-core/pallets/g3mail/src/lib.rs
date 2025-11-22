//! # G3Mail Pallet
//!
//! The G3Mail pallet provides decentralized messaging with on-chain message pointers for the Ghost Protocol blockchain.
//!
//! ## Overview
//!
//! This pallet enables users to:
//! - Register public encryption keys for secure messaging
//! - Send encrypted messages with on-chain pointers to off-chain storage (IPFS)
//! - Mark messages as read with ownership validation
//! - Track inbox message counts with enforced limits
//!
#![cfg_attr(not(feature = "std"), no_std)]

pub use pallet::*;

#[cfg(test)]
mod mock;

#[cfg(test)]
mod tests;

#[cfg(feature = "runtime-benchmarks")]
mod benchmarking;
pub mod weights;
pub use weights::*;

#[frame_support::pallet]
pub mod pallet {
    use super::*;
    use frame_support::pallet_prelude::*;
    use frame_support::sp_runtime::traits::Hash;
    use frame_system::pallet_prelude::*;
    use sp_std::vec::Vec;

    /// Type alias for Message ID
    pub type MessageId = u64;

    /// MessagePointer struct containing all message-related data
    ///
    /// This struct stores the on-chain pointer to an encrypted message stored off-chain.
    /// The actual encrypted message content is stored on IPFS, and only the CID (content hash)
    /// is stored on-chain.
    #[derive(Clone, Encode, Decode, Eq, PartialEq, TypeInfo, MaxEncodedLen)]
    #[scale_info(skip_type_params(T))]
    pub struct MessagePointer<T: Config> {
        /// Unique message identifier
        pub message_id: MessageId,
        /// Account that sent the message
        pub sender: T::AccountId,
        /// Account that will receive the message
        pub recipient: T::AccountId,
        /// IPFS content identifier (CID) pointing to encrypted message
        pub cid: BoundedVec<u8, T::MaxCidLength>,
        /// Block number when message was sent
        pub timestamp: BlockNumberFor<T>,
        /// Whether the message has been marked as read
        pub read: bool,
    }

    #[pallet::pallet]
    pub struct Pallet<T>(_);

    /// Configuration trait for the G3Mail pallet
    #[pallet::config]
    pub trait Config: frame_system::Config {
        /// The overarching runtime event type
        type RuntimeEvent: From<Event<Self>> + IsType<<Self as frame_system::Config>::RuntimeEvent>;

        /// Weight information for extrinsics in this pallet
        type WeightInfo: WeightInfo;

        /// Maximum number of messages per inbox
        #[pallet::constant]
        type MaxInboxMessages: Get<u32>;

        /// Maximum length of public key in bytes
        #[pallet::constant]
        type MaxPublicKeyLength: Get<u32>;

        /// Maximum length of CID (IPFS content hash) in bytes
        #[pallet::constant]
        type MaxCidLength: Get<u32>;
    }

    /// Storage for public encryption keys
    ///
    /// Maps AccountId to public key (32-128 bytes for ECIES encryption)
    #[pallet::storage]
    #[pallet::getter(fn public_keys)]
    pub type PublicKeys<T: Config> =
        StorageMap<_, Blake2_128Concat, T::AccountId, BoundedVec<u8, T::MaxPublicKeyLength>>;

    /// Storage for the next message ID (auto-incrementing counter)
    #[pallet::storage]
    #[pallet::getter(fn next_message_id)]
    pub type NextMessageId<T> = StorageValue<_, MessageId, ValueQuery>;

    /// Storage for message pointers indexed by recipient and message ID
    ///
    /// Double map: (Recipient AccountId, MessageId) → MessagePointer
    /// This allows efficient querying of all messages for a specific recipient
    #[pallet::storage]
    #[pallet::getter(fn messages_by_recipient)]
    pub type MessagesByRecipient<T: Config> = StorageDoubleMap<
        _,
        Blake2_128Concat,
        T::AccountId,
        Blake2_128Concat,
        MessageId,
        MessagePointer<T>,
    >;

    /// Storage for inbox message count per recipient
    ///
    /// Tracks the number of messages each recipient has received
    /// Used to enforce the MaxInboxMessages limit
    #[pallet::storage]
    #[pallet::getter(fn inbox_count)]
    pub type InboxCount<T: Config> = StorageMap<_, Blake2_128Concat, T::AccountId, u32, ValueQuery>;

    /// Events emitted by the G3Mail pallet
    #[pallet::event]
    #[pallet::generate_deposit(pub(super) fn deposit_event)]
    pub enum Event<T: Config> {
        /// A public key has been registered
        PublicKeyRegistered {
            /// The account that registered the key
            account: T::AccountId,
            /// Hash of the public key (for privacy)
            key_hash: T::Hash,
        },
        /// A message has been sent
        MessageSent {
            /// Unique message identifier
            message_id: MessageId,
            /// The sender account
            sender: T::AccountId,
            /// The recipient account
            recipient: T::AccountId,
            /// IPFS CID of the encrypted message
            cid: BoundedVec<u8, T::MaxCidLength>,
            /// Block number when sent
            timestamp: BlockNumberFor<T>,
        },
        /// A message has been marked as read
        MessageRead {
            /// The message identifier
            message_id: MessageId,
            /// The recipient who read the message
            recipient: T::AccountId,
        },
    }

    /// Errors that can be returned by the G3Mail pallet
    #[pallet::error]
    pub enum Error<T> {
        /// The account already has a public key registered
        PublicKeyAlreadyRegistered,
        /// The account has not registered a public key
        PublicKeyNotFound,
        /// The recipient has not registered a public key
        RecipientPublicKeyNotFound,
        /// The specified message does not exist
        MessageNotFound,
        /// The caller is not the recipient of the message
        NotMessageRecipient,
        /// The recipient's inbox has reached the maximum message limit
        MaxInboxMessagesExceeded,
        /// The public key length is invalid (must be 32-128 bytes)
        InvalidPublicKeyLength,
        /// The CID length is invalid (must be within bounds)
        InvalidCidLength,
    }

    #[pallet::call]
    impl<T: Config> Pallet<T> {
        /// Register a public encryption key for the caller
        ///
        /// Stores the caller's public key which other users will use to encrypt messages.
        /// The public key must be between 32 and 128 bytes (suitable for ECIES).
        /// Only the hash of the public key is emitted in events for privacy.
        ///
        /// # Parameters
        ///
        /// - `origin`: The account registering the key (must be signed)
        /// - `public_key`: The public encryption key (32-128 bytes)
        ///
        /// # Errors
        ///
        /// - `PublicKeyAlreadyRegistered`: Account already has a public key
        /// - `InvalidPublicKeyLength`: Key length is not within valid range
        ///
        /// # Events
        ///
        /// - `PublicKeyRegistered`: Emitted when key is successfully registered
        #[pallet::call_index(0)]
        #[pallet::weight(T::WeightInfo::register_public_key())]
        pub fn register_public_key(origin: OriginFor<T>, public_key: Vec<u8>) -> DispatchResult {
            let who = ensure_signed(origin)?;

            // Ensure account doesn't already have a public key
            ensure!(
                !PublicKeys::<T>::contains_key(&who),
                Error::<T>::PublicKeyAlreadyRegistered
            );

            // Validate public key length (32-128 bytes for ECIES)
            let key_len = public_key.len();
            let max_key_len = T::MaxPublicKeyLength::get() as usize;
            let valid_key_len = key_len >= 32 && key_len <= max_key_len;
            ensure!(valid_key_len, Error::<T>::InvalidPublicKeyLength);

            // Convert to BoundedVec
            let bounded_key: BoundedVec<u8, T::MaxPublicKeyLength> = public_key
                .try_into()
                .map_err(|_| Error::<T>::InvalidPublicKeyLength)?;

            // Hash the public key for the event (privacy)
            let key_hash = T::Hashing::hash(&bounded_key[..]);

            // Store the public key
            PublicKeys::<T>::insert(&who, bounded_key);

            // Emit event
            Self::deposit_event(Event::PublicKeyRegistered {
                account: who,
                key_hash,
            });

            Ok(())
        }

        /// Send a message to a recipient
        ///
        /// Creates an on-chain message pointer to an encrypted message stored on IPFS.
        /// The recipient must have a registered public key. The message is encrypted
        /// client-side before uploading to IPFS, and only the CID is stored on-chain.
        ///
        /// # Parameters
        ///
        /// - `origin`: The account sending the message (must be signed)
        /// - `recipient`: The account that will receive the message
        /// - `cid`: IPFS content identifier (CID) of the encrypted message
        ///
        /// # Errors
        ///
        /// - `RecipientPublicKeyNotFound`: Recipient has not registered a public key
        /// - `InvalidCidLength`: CID length exceeds maximum allowed
        /// - `MaxInboxMessagesExceeded`: Recipient's inbox is full
        ///
        /// # Events
        ///
        /// - `MessageSent`: Emitted when message is successfully sent
        #[pallet::call_index(1)]
        #[pallet::weight(T::WeightInfo::send_message())]
        pub fn send_message(
            origin: OriginFor<T>,
            recipient: T::AccountId,
            cid: Vec<u8>,
        ) -> DispatchResult {
            let sender = ensure_signed(origin)?;

            // Ensure recipient has a registered public key
            ensure!(
                PublicKeys::<T>::contains_key(&recipient),
                Error::<T>::RecipientPublicKeyNotFound
            );

            // Validate CID length
            let max_cid_len = T::MaxCidLength::get() as usize;
            let valid_cid_len = !cid.is_empty() && cid.len() <= max_cid_len;
            ensure!(valid_cid_len, Error::<T>::InvalidCidLength);

            // Convert CID to BoundedVec
            let bounded_cid: BoundedVec<u8, T::MaxCidLength> =
                cid.try_into().map_err(|_| Error::<T>::InvalidCidLength)?;

            // Check inbox limit
            let current_count = InboxCount::<T>::get(&recipient);
            ensure!(
                current_count < T::MaxInboxMessages::get(),
                Error::<T>::MaxInboxMessagesExceeded
            );

            // Get next message ID and increment counter
            let message_id = NextMessageId::<T>::get();
            NextMessageId::<T>::put(message_id.saturating_add(1));

            // Get current block number as timestamp
            let timestamp = frame_system::Pallet::<T>::block_number();

            // Create message pointer
            let message_pointer = MessagePointer {
                message_id,
                sender: sender.clone(),
                recipient: recipient.clone(),
                cid: bounded_cid.clone(),
                timestamp,
                read: false,
            };

            // Store message pointer
            MessagesByRecipient::<T>::insert(&recipient, message_id, message_pointer);

            // Increment inbox count
            InboxCount::<T>::insert(&recipient, current_count.saturating_add(1));

            // Emit event
            Self::deposit_event(Event::MessageSent {
                message_id,
                sender,
                recipient,
                cid: bounded_cid,
                timestamp,
            });

            Ok(())
        }

        /// Mark a message as read
        ///
        /// Updates the read status of a message to true. Only the recipient of the message
        /// can mark it as read. This is useful for read receipts and inbox management.
        ///
        /// # Parameters
        ///
        /// - `origin`: The account marking the message as read (must be signed)
        /// - `message_id`: The identifier of the message to mark as read
        ///
        /// # Errors
        ///
        /// - `MessageNotFound`: Message does not exist
        /// - `NotMessageRecipient`: Caller is not the recipient of the message
        ///
        /// # Events
        ///
        /// - `MessageRead`: Emitted when message is successfully marked as read
        #[pallet::call_index(2)]
        #[pallet::weight(T::WeightInfo::mark_message_read())]
        pub fn mark_message_read(origin: OriginFor<T>, message_id: MessageId) -> DispatchResult {
            let who = ensure_signed(origin)?;

            // Find and update the message
            MessagesByRecipient::<T>::try_mutate(
                &who,
                message_id,
                |maybe_message| -> DispatchResult {
                    let message = maybe_message.as_mut().ok_or(Error::<T>::MessageNotFound)?;

                    // Update the read status
                    message.read = true;

                    // Emit event
                    Self::deposit_event(Event::MessageRead {
                        message_id,
                        recipient: who.clone(),
                    });

                    Ok(())
                },
            )
        }
    }
}
