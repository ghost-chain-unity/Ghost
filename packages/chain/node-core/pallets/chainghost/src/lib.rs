//! # ChainGhost Pallet
//!
//! The ChainGhost pallet provides intent-based execution and journey visualization for the Ghost Protocol blockchain.
//!
//! ## Overview
//!
//! This pallet enables users to:
//! - Execute intent-based transactions with on-chain tracking
//! - Record journey steps for narrative visualization
//! - Manage intent status transitions (Pending → Executed/Failed)
//! - Track per-account intent history with bounded collections
//!
//! ## Key Features
//!
//! - **Intent Execution**: Create and track user intents with unique IDs
//! - **Journey Recording**: Build narrative timelines by recording journey steps
//! - **Status Management**: Update intent status with ownership validation
//! - **Resource Limits**: Enforce per-account intent caps and journey step limits
//!
//! ## Storage Items
//!
//! - `NextIntentId`: Counter for generating unique intent IDs
//! - `IntentById`: Main storage mapping IntentId → Intent struct
//! - `IntentsByAccount`: Index mapping AccountId → BoundedVec<IntentId>
//! - `JourneyByIntent`: Journey data mapping IntentId → BoundedVec<JourneyStep>
//!
//! ## Dispatchable Functions
//!
//! - `execute_intent`: Creates new intent record with metadata
//! - `record_journey`: Adds journey step to existing intent
//! - `update_intent_status`: Updates intent status (requires ownership)
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
    use frame_system::pallet_prelude::*;
    use sp_std::vec::Vec;

    /// Intent status enum representing the lifecycle of an intent
    #[derive(Clone, Encode, Decode, Debug, Eq, PartialEq, TypeInfo, MaxEncodedLen)]
    pub enum IntentStatus {
        /// Intent has been created but not yet executed
        Pending,
        /// Intent has been successfully executed
        Executed,
        /// Intent execution has failed
        Failed,
    }

    impl IntentStatus {
        /// Convert IntentStatus to u8 for storage in events
        pub fn as_u8(&self) -> u8 {
            match self {
                IntentStatus::Pending => 0,
                IntentStatus::Executed => 1,
                IntentStatus::Failed => 2,
            }
        }

        /// Convert u8 to IntentStatus
        pub fn from_u8(value: u8) -> Option<Self> {
            match value {
                0 => Some(IntentStatus::Pending),
                1 => Some(IntentStatus::Executed),
                2 => Some(IntentStatus::Failed),
                _ => None,
            }
        }
    }

    /// Type alias for Intent ID
    pub type IntentId = u64;

    /// Type alias for Moment (timestamp)
    pub type Moment = u64;

    /// Intent struct containing all intent-related data
    #[derive(Clone, Encode, Decode, Eq, PartialEq, TypeInfo, MaxEncodedLen)]
    #[scale_info(skip_type_params(T))]
    pub struct Intent<T: Config> {
        /// Unique intent identifier
        pub intent_id: IntentId,
        /// Account that created the intent
        pub account: T::AccountId,
        /// Current status of the intent
        pub status: IntentStatus,
        /// Block number when intent was created
        pub timestamp: BlockNumberFor<T>,
        /// Metadata describing the intent (bounded to 256 bytes)
        pub metadata: BoundedVec<u8, ConstU32<256>>,
    }

    /// Journey step struct representing a single step in the user's journey
    #[derive(Clone, Encode, Decode, Eq, PartialEq, TypeInfo, MaxEncodedLen)]
    #[scale_info(skip_type_params(T))]
    pub struct JourneyStep<T: Config> {
        /// Sequential step identifier within the intent
        pub step_id: u32,
        /// Description of the journey step (bounded to 512 bytes)
        pub description: BoundedVec<u8, ConstU32<512>>,
        /// Block number when step was recorded
        pub timestamp: BlockNumberFor<T>,
    }

    #[pallet::pallet]
    pub struct Pallet<T>(_);

    /// Configuration trait for the ChainGhost pallet
    #[pallet::config]
    pub trait Config: frame_system::Config {
        /// The overarching runtime event type
        type RuntimeEvent: From<Event<Self>> + IsType<<Self as frame_system::Config>::RuntimeEvent>;

        /// Weight information for extrinsics in this pallet
        type WeightInfo: WeightInfo;

        /// Maximum number of intents per account
        #[pallet::constant]
        type MaxIntentsPerAccount: Get<u32>;

        /// Maximum number of journey steps per intent
        #[pallet::constant]
        type MaxJourneyStepsPerIntent: Get<u32>;
    }

    /// Storage for the next intent ID (auto-incrementing counter)
    #[pallet::storage]
    #[pallet::getter(fn next_intent_id)]
    pub type NextIntentId<T> = StorageValue<_, IntentId, ValueQuery>;

    /// Storage mapping from IntentId to Intent struct
    #[pallet::storage]
    #[pallet::getter(fn intent_by_id)]
    pub type IntentById<T: Config> = StorageMap<_, Blake2_128Concat, IntentId, Intent<T>>;

    /// Storage mapping from AccountId to list of IntentIds
    #[pallet::storage]
    #[pallet::getter(fn intents_by_account)]
    pub type IntentsByAccount<T: Config> = StorageMap<
        _,
        Blake2_128Concat,
        T::AccountId,
        BoundedVec<IntentId, T::MaxIntentsPerAccount>,
        ValueQuery,
    >;

    /// Storage mapping from IntentId to list of JourneySteps
    #[pallet::storage]
    #[pallet::getter(fn journey_by_intent)]
    pub type JourneyByIntent<T: Config> = StorageMap<
        _,
        Blake2_128Concat,
        IntentId,
        BoundedVec<JourneyStep<T>, T::MaxJourneyStepsPerIntent>,
        ValueQuery,
    >;

    /// Events emitted by the ChainGhost pallet
    #[pallet::event]
    #[pallet::generate_deposit(pub(super) fn deposit_event)]
    pub enum Event<T: Config> {
        /// An intent has been successfully executed
        IntentExecuted {
            /// The unique intent ID
            intent_id: IntentId,
            /// The account that executed the intent
            account: T::AccountId,
            /// Block number when intent was executed
            timestamp: BlockNumberFor<T>,
        },
        /// An intent's status has been updated
        IntentStatusUpdated {
            /// The unique intent ID
            intent_id: IntentId,
            /// Previous status (as u8: 0=Pending, 1=Executed, 2=Failed)
            old_status: u8,
            /// New status (as u8: 0=Pending, 1=Executed, 2=Failed)
            new_status: u8,
        },
        /// A journey step has been recorded for an intent
        JourneyRecorded {
            /// The unique intent ID
            intent_id: IntentId,
            /// Total number of journey steps for this intent
            step_count: u32,
        },
    }

    /// Errors that can be returned by the ChainGhost pallet
    #[pallet::error]
    pub enum Error<T> {
        /// The specified intent does not exist
        IntentNotFound,
        /// The caller is not the owner of the intent
        NotIntentOwner,
        /// The account has reached the maximum number of intents
        MaxIntentsPerAccountExceeded,
        /// The intent has reached the maximum number of journey steps
        MaxJourneyStepsExceeded,
        /// The intent status is invalid for this operation
        InvalidIntentStatus,
    }

    #[pallet::call]
    impl<T: Config> Pallet<T> {
        /// Execute a new intent with the provided metadata
        ///
        /// Creates a new intent record, assigns it a unique ID, and stores it in the blockchain.
        /// Enforces per-account intent limits to prevent spam.
        ///
        /// # Parameters
        ///
        /// - `origin`: The account executing the intent (must be signed)
        /// - `metadata`: Intent metadata (max 256 bytes)
        ///
        /// # Errors
        ///
        /// - `MaxIntentsPerAccountExceeded`: Account has too many intents
        ///
        /// # Events
        ///
        /// - `IntentExecuted`: Emitted when intent is successfully created
        #[pallet::call_index(0)]
        #[pallet::weight(T::WeightInfo::execute_intent())]
        pub fn execute_intent(origin: OriginFor<T>, metadata: Vec<u8>) -> DispatchResult {
            let who = ensure_signed(origin)?;

            // Get next intent ID and increment counter
            let intent_id = NextIntentId::<T>::get();
            NextIntentId::<T>::put(intent_id.saturating_add(1));

            // Convert metadata to BoundedVec (automatically truncates if too long)
            let bounded_metadata: BoundedVec<u8, ConstU32<256>> = metadata
                .try_into()
                .map_err(|_| Error::<T>::InvalidIntentStatus)?;

            // Get current block number as timestamp
            let timestamp = frame_system::Pallet::<T>::block_number();

            // Create intent struct
            let intent = Intent {
                intent_id,
                account: who.clone(),
                status: IntentStatus::Pending,
                timestamp,
                metadata: bounded_metadata,
            };

            // Store intent by ID
            IntentById::<T>::insert(intent_id, intent);

            // Add intent ID to account's intent list (enforce max limit)
            IntentsByAccount::<T>::try_mutate(&who, |intents| -> DispatchResult {
                intents
                    .try_push(intent_id)
                    .map_err(|_| Error::<T>::MaxIntentsPerAccountExceeded)?;
                Ok(())
            })?;

            // Emit event
            Self::deposit_event(Event::IntentExecuted {
                intent_id,
                account: who,
                timestamp,
            });

            Ok(())
        }

        /// Record a journey step for an existing intent
        ///
        /// Adds a new step to the intent's journey timeline. Only the intent owner can record steps.
        /// Journey steps are used for narrative visualization and AI story generation.
        ///
        /// # Parameters
        ///
        /// - `origin`: The account recording the journey step (must be intent owner)
        /// - `intent_id`: The intent to add the step to
        /// - `description`: Step description (max 512 bytes)
        ///
        /// # Errors
        ///
        /// - `IntentNotFound`: Intent does not exist
        /// - `NotIntentOwner`: Caller is not the intent owner
        /// - `MaxJourneyStepsExceeded`: Intent has too many journey steps
        ///
        /// # Events
        ///
        /// - `JourneyRecorded`: Emitted when step is successfully recorded
        #[pallet::call_index(1)]
        #[pallet::weight(T::WeightInfo::record_journey())]
        pub fn record_journey(
            origin: OriginFor<T>,
            intent_id: IntentId,
            description: Vec<u8>,
        ) -> DispatchResult {
            let who = ensure_signed(origin)?;

            // Verify intent exists
            let intent = IntentById::<T>::get(intent_id).ok_or(Error::<T>::IntentNotFound)?;

            // Verify caller is intent owner
            ensure!(intent.account == who, Error::<T>::NotIntentOwner);

            // Convert description to BoundedVec
            let bounded_description: BoundedVec<u8, ConstU32<512>> = description
                .try_into()
                .map_err(|_| Error::<T>::InvalidIntentStatus)?;

            // Get current block number as timestamp
            let timestamp = frame_system::Pallet::<T>::block_number();

            // Add journey step (enforce max limit)
            JourneyByIntent::<T>::try_mutate(intent_id, |steps| -> DispatchResult {
                let step_id = steps.len() as u32;

                let journey_step = JourneyStep {
                    step_id,
                    description: bounded_description,
                    timestamp,
                };

                steps
                    .try_push(journey_step)
                    .map_err(|_| Error::<T>::MaxJourneyStepsExceeded)?;

                Ok(())
            })?;

            // Get updated step count
            let step_count = JourneyByIntent::<T>::get(intent_id).len() as u32;

            // Emit event
            Self::deposit_event(Event::JourneyRecorded {
                intent_id,
                step_count,
            });

            Ok(())
        }

        /// Update the status of an existing intent
        ///
        /// Transitions an intent from one status to another (e.g., Pending → Executed).
        /// Only the intent owner can update the status.
        ///
        /// # Parameters
        ///
        /// - `origin`: The account updating the status (must be intent owner)
        /// - `intent_id`: The intent to update
        /// - `new_status`: The new status to set
        ///
        /// # Errors
        ///
        /// - `IntentNotFound`: Intent does not exist
        /// - `NotIntentOwner`: Caller is not the intent owner
        ///
        /// # Events
        ///
        /// - `IntentStatusUpdated`: Emitted when status is successfully updated
        #[pallet::call_index(2)]
        #[pallet::weight(T::WeightInfo::update_intent_status())]
        pub fn update_intent_status(
            origin: OriginFor<T>,
            intent_id: IntentId,
            new_status: u8,
        ) -> DispatchResult {
            let who = ensure_signed(origin)?;

            // Convert u8 to IntentStatus
            let new_status =
                IntentStatus::from_u8(new_status).ok_or(Error::<T>::InvalidIntentStatus)?;

            // Verify intent exists and update status
            IntentById::<T>::try_mutate(intent_id, |maybe_intent| -> DispatchResult {
                let intent = maybe_intent.as_mut().ok_or(Error::<T>::IntentNotFound)?;

                // Verify caller is intent owner
                ensure!(intent.account == who, Error::<T>::NotIntentOwner);

                // Store old status for event
                let old_status = intent.status.clone();

                // Update status
                intent.status = new_status.clone();

                // Emit event (convert statuses to u8)
                Self::deposit_event(Event::IntentStatusUpdated {
                    intent_id,
                    old_status: old_status.as_u8(),
                    new_status: new_status.as_u8(),
                });

                Ok(())
            })
        }
    }
}
