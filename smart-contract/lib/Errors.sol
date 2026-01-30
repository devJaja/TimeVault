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
