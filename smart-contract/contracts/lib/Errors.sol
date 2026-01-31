// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// --- Custom Errors for SocialVault.sol ---
error SocialVault__ZeroAddress();
error SocialVault__AlreadyMember();
error SocialVault__CannotRemoveOwner();
error SocialVault__MemberHasFunds();
error SocialVault__ZeroAmount();
error SocialVault__InsufficientVaultBalance();
error SocialVault__InvalidWithdrawalRequestID();
error SocialVault__WithdrawalAlreadyExecuted();
error SocialVault__AlreadyApprovedWithdrawal();
error SocialVault__NotEnoughApprovals();
error SocialVault__EtherTransferFailed();
error SocialVault__CallerNotMember();

// --- Custom Errors for SavingsChallenge.sol ---
error SavingsChallenge__EmptyName();
error SavingsChallenge__ZeroGoalAmount();
error SavingsChallenge__ZeroParticipationFee();
error SavingsChallenge__ZeroDuration();
error SavingsChallenge__DeadlineOverflow();
error SavingsChallenge__ChallengeDoesNotExist();
error SavingsChallenge__ChallengeNotOpen();
error SavingsChallenge__JoiningDeadlinePassed();
error SavingsChallenge__AlreadyJoinedChallenge();
error SavingsChallenge__IncorrectParticipationFee();
error SavingsChallenge__ContributionDeadlinePassed();
error SavingsChallenge__NotParticipant();
error SavingsChallenge__ZeroContributionAmount();
error SavingsChallenge__ChallengeNotEnded();
error SavingsChallenge__ChallengeNotResolved();
error SavingsChallenge__ParticipantDidNotMeetGoal();
error SavingsChallenge__RewardAlreadyClaimed();
error SavingsChallenge__NoWinners();
error SavingsChallenge__OnlyCreatorCanCancel();
error SavingsChallenge__CannotCancelAfterDeadline();
error SavingsChallenge__EtherTransferFailed();

// --- Custom Errors for VaultFactory.sol ---
error VaultFactory__NotOwner();
error VaultFactory__EmptyName();
error VaultFactory__InvalidUnlockTime();
error VaultFactory__FeeTooHigh();
error VaultFactory__ZeroAddress();

// --- Custom Errors for TimeVault.sol ---
error TimeVault__NotOwner();
error TimeVault__ZeroAmount();
error TimeVault__VaultLocked();
error TimeVault__InsufficientBalance();
error TimeVault__TransferFailed();
error TimeVault__EmergencyNotEnabled();

// --- Custom Errors for New Contracts ---
error TimeVault__UserNotRegistered();
error TimeVault__UserAlreadyRegistered();
error TimeVault__UsernameExists();
error TimeVault__InvalidState();
error TimeVault__InsufficientFunds();
error TimeVault__ExceedsCoverage();
error TimeVault__AlreadyApproved();
error TimeVault__VotingEnded();
error TimeVault__AlreadyVoted();
error TimeVault__VotingActive();
error TimeVault__AlreadyExecuted();
error TimeVault__ProposalRejected();
error TimeVault__ReferrerAlreadySet();
error TimeVault__SelfReferral();
error TimeVault__InvalidLockPeriod();
error TimeVault__AlreadyWithdrawn();
error TimeVault__StakeLocked();
error TimeVault__NotAuthorized();
