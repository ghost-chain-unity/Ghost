//! # Ghonity Pallet
//!
//! The Ghonity pallet provides social graph and reputation system functionality for the Ghost Protocol blockchain.
//!
//! ## Overview
//!
//! This pallet enables users to:
//! - Follow and unfollow other accounts to build a social graph
//! - Track follower and following counts for each account
//! - Manage reputation scores (governance-controlled)
//! - Query social graph relationships
//!
//! ## Key Features
//!
//! - **Social Graph**: Follow/unfollow relationships with atomic counter updates
//! - **Reputation System**: Governance-controlled reputation scoring
//! - **Resource Limits**: Enforces maximum following limit per account (1000)
//! - **Query Helpers**: Public functions to query follow status and statistics
//!
//! ## Storage Items
//!
//! - `Follows`: Double map tracking follow relationships (Follower, Followee) → bool
//! - `FollowerCount`: Map of follower counts per account
//! - `FollowingCount`: Map of following counts per account
//! - `ReputationScores`: Map of reputation scores per account (default: 0)
//!
//! ## Dispatchable Functions
//!
//! - `follow`: Create a follow relationship
//! - `unfollow`: Remove a follow relationship
//! - `update_reputation`: Update account reputation (Root/Sudo only)

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

    #[pallet::pallet]
    pub struct Pallet<T>(_);

    /// Configuration trait for the Ghonity pallet
    #[pallet::config]
    pub trait Config: frame_system::Config {
        /// The overarching runtime event type
        type RuntimeEvent: From<Event<Self>> + IsType<<Self as frame_system::Config>::RuntimeEvent>;

        /// Weight information for extrinsics in this pallet
        type WeightInfo: WeightInfo;

        /// Maximum number of accounts a user can follow
        #[pallet::constant]
        type MaxFollowing: Get<u32>;
    }

    /// Storage for follow relationships
    /// Double map: (Follower AccountId, Followee AccountId) -> bool
    #[pallet::storage]
    #[pallet::getter(fn follows)]
    pub type Follows<T: Config> = StorageDoubleMap<
        _,
        Blake2_128Concat,
        T::AccountId,
        Blake2_128Concat,
        T::AccountId,
        bool,
        ValueQuery,
    >;

    /// Storage for follower counts per account
    #[pallet::storage]
    #[pallet::getter(fn follower_count)]
    pub type FollowerCount<T: Config> =
        StorageMap<_, Blake2_128Concat, T::AccountId, u32, ValueQuery>;

    /// Storage for following counts per account
    #[pallet::storage]
    #[pallet::getter(fn following_count)]
    pub type FollowingCount<T: Config> =
        StorageMap<_, Blake2_128Concat, T::AccountId, u32, ValueQuery>;

    /// Storage for reputation scores per account
    #[pallet::storage]
    #[pallet::getter(fn reputation_scores)]
    pub type ReputationScores<T: Config> =
        StorageMap<_, Blake2_128Concat, T::AccountId, u32, ValueQuery>;

    /// Events emitted by the Ghonity pallet
    #[pallet::event]
    #[pallet::generate_deposit(pub(super) fn deposit_event)]
    pub enum Event<T: Config> {
        /// A follow relationship was created
        Followed {
            /// The account that followed
            follower: T::AccountId,
            /// The account that was followed
            followee: T::AccountId,
        },
        /// A follow relationship was removed
        Unfollowed {
            /// The account that unfollowed
            follower: T::AccountId,
            /// The account that was unfollowed
            followee: T::AccountId,
        },
        /// An account's reputation was updated
        ReputationUpdated {
            /// The account whose reputation was updated
            account: T::AccountId,
            /// The previous reputation score
            old_score: u32,
            /// The new reputation score
            new_score: u32,
        },
    }

    /// Errors that can be returned by the Ghonity pallet
    #[pallet::error]
    pub enum Error<T> {
        /// The account is already following the target account
        AlreadyFollowing,
        /// The account is not following the target account
        NotFollowing,
        /// An account cannot follow itself
        CannotFollowSelf,
        /// The account has reached the maximum following limit
        MaxFollowingExceeded,
        /// Reputation score would overflow u32::MAX
        ReputationOverflow,
    }

    #[pallet::call]
    impl<T: Config> Pallet<T> {
        /// Follow another account
        ///
        /// Creates a follow relationship from the caller to the target account.
        /// Increments following count for caller and follower count for target.
        /// Enforces maximum following limit.
        ///
        /// # Parameters
        ///
        /// - `origin`: The account creating the follow relationship (must be signed)
        /// - `followee`: The account to follow
        ///
        /// # Errors
        ///
        /// - `CannotFollowSelf`: Cannot follow your own account
        /// - `AlreadyFollowing`: Already following this account
        /// - `MaxFollowingExceeded`: Following limit reached
        ///
        /// # Events
        ///
        /// - `Followed`: Emitted when follow relationship is created
        #[pallet::call_index(0)]
        #[pallet::weight(T::WeightInfo::follow())]
        pub fn follow(origin: OriginFor<T>, followee: T::AccountId) -> DispatchResult {
            let follower = ensure_signed(origin)?;

            // Validate no self-follow
            ensure!(follower != followee, Error::<T>::CannotFollowSelf);

            // Check not already following
            ensure!(
                !Follows::<T>::get(&follower, &followee),
                Error::<T>::AlreadyFollowing
            );

            // Check max following limit
            let current_following = FollowingCount::<T>::get(&follower);
            ensure!(
                current_following < T::MaxFollowing::get(),
                Error::<T>::MaxFollowingExceeded
            );

            // Create follow relationship
            Follows::<T>::insert(&follower, &followee, true);

            // Increment follower count for followee
            FollowerCount::<T>::mutate(&followee, |count| {
                *count = count.saturating_add(1);
            });

            // Increment following count for follower
            FollowingCount::<T>::mutate(&follower, |count| {
                *count = count.saturating_add(1);
            });

            // Emit event
            Self::deposit_event(Event::Followed { follower, followee });

            Ok(())
        }

        /// Unfollow an account
        ///
        /// Removes a follow relationship from the caller to the target account.
        /// Decrements following count for caller and follower count for target.
        ///
        /// # Parameters
        ///
        /// - `origin`: The account removing the follow relationship (must be signed)
        /// - `followee`: The account to unfollow
        ///
        /// # Errors
        ///
        /// - `NotFollowing`: Not currently following this account
        ///
        /// # Events
        ///
        /// - `Unfollowed`: Emitted when follow relationship is removed
        #[pallet::call_index(1)]
        #[pallet::weight(T::WeightInfo::unfollow())]
        pub fn unfollow(origin: OriginFor<T>, followee: T::AccountId) -> DispatchResult {
            let follower = ensure_signed(origin)?;

            // Validate currently following
            ensure!(
                Follows::<T>::get(&follower, &followee),
                Error::<T>::NotFollowing
            );

            // Remove follow relationship
            Follows::<T>::remove(&follower, &followee);

            // Decrement follower count for followee
            FollowerCount::<T>::mutate(&followee, |count| {
                *count = count.saturating_sub(1);
            });

            // Decrement following count for follower
            FollowingCount::<T>::mutate(&follower, |count| {
                *count = count.saturating_sub(1);
            });

            // Emit event
            Self::deposit_event(Event::Unfollowed { follower, followee });

            Ok(())
        }

        /// Update reputation score for an account
        ///
        /// Updates the reputation score for the specified account.
        /// This function is governance-controlled and requires Root origin.
        ///
        /// # Parameters
        ///
        /// - `origin`: Must be Root origin
        /// - `account`: The account to update reputation for
        /// - `score`: The new reputation score
        ///
        /// # Errors
        ///
        /// - `BadOrigin`: If origin is not Root
        ///
        /// # Events
        ///
        /// - `ReputationUpdated`: Emitted when reputation is updated
        #[pallet::call_index(2)]
        #[pallet::weight(T::WeightInfo::update_reputation())]
        pub fn update_reputation(
            origin: OriginFor<T>,
            account: T::AccountId,
            score: u32,
        ) -> DispatchResult {
            // Require Root or Sudo origin (governance-controlled)
            ensure_root(origin)?;

            // Get old score
            let old_score = ReputationScores::<T>::get(&account);

            // Update reputation score
            ReputationScores::<T>::insert(&account, score);

            // Emit event
            Self::deposit_event(Event::ReputationUpdated {
                account,
                old_score,
                new_score: score,
            });

            Ok(())
        }
    }

    /// Helper functions for querying social graph data
    impl<T: Config> Pallet<T> {
        /// Check if follower is following followee
        ///
        /// # Parameters
        ///
        /// - `follower`: The account that might be following
        /// - `followee`: The account that might be followed
        ///
        /// # Returns
        ///
        /// `true` if follower is following followee, `false` otherwise
        pub fn is_following(follower: &T::AccountId, followee: &T::AccountId) -> bool {
            Follows::<T>::get(follower, followee)
        }

        /// Get the number of followers for an account
        ///
        /// # Parameters
        ///
        /// - `account`: The account to get follower count for
        ///
        /// # Returns
        ///
        /// The number of followers
        pub fn get_follower_count(account: &T::AccountId) -> u32 {
            FollowerCount::<T>::get(account)
        }

        /// Get the number of accounts being followed by an account
        ///
        /// # Parameters
        ///
        /// - `account`: The account to get following count for
        ///
        /// # Returns
        ///
        /// The number of accounts being followed
        pub fn get_following_count(account: &T::AccountId) -> u32 {
            FollowingCount::<T>::get(account)
        }

        /// Get the reputation score for an account
        ///
        /// # Parameters
        ///
        /// - `account`: The account to get reputation for
        ///
        /// # Returns
        ///
        /// The reputation score (default: 0)
        pub fn get_reputation(account: &T::AccountId) -> u32 {
            ReputationScores::<T>::get(account)
        }
    }
}
