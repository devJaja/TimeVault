// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// --- Events for TimeVault.sol ---
event VaultDeposit(address indexed depositor, uint256 amount, uint256 newBalance);
event VaultWithdrawal(address indexed owner, uint256 amount, uint256 remainingBalance);
event EmergencyWithdrawal(address indexed owner, uint256 amount, uint256 penalty);
event EmergencyWithdrawalEnabled();

// --- Events for RegisterUser.sol ---
event UserRegistered(address indexed user, string username);

// --- Events for Dispute.sol ---
event DisputeCreated(uint256 indexed disputeId, address indexed complainant, address indexed respondent);
event DisputeResolved(uint256 indexed disputeId, bool inFavorOfComplainant);

// --- Events for Subscription.sol ---
event SubscriptionActivated(address indexed user, uint8 tier);

// --- Events for Governance.sol ---
event ProposalCreated(uint256 indexed proposalId, address indexed proposer);
event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
event ProposalExecuted(uint256 indexed proposalId);

// --- Events for Referral.sol ---
event ReferralSet(address indexed user, address indexed referrer);
event ReferralReward(address indexed referrer, address indexed user, uint256 reward);

// --- Events for Insurance.sol ---
event InsurancePurchased(uint256 indexed policyId, address indexed holder, uint256 coverage);
event ClaimFiled(uint256 indexed claimId, uint256 indexed policyId, address indexed claimant, uint256 amount);
event ClaimApproved(uint256 indexed claimId, uint256 amount);

// --- Events for Staking.sol ---
event Staked(address indexed user, uint256 amount, uint256 lockPeriod);
event Unstaked(address indexed user, uint256 amount, uint256 reward);

// --- Events for Analytics.sol ---
event MetricsUpdated(uint256 totalVaults, uint256 totalValueLocked, uint256 totalUsers);
