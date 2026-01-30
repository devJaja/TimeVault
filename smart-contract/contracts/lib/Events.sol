// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// --- Events for TimeVault.sol ---
event VaultDeposit(address indexed depositor, uint256 amount, uint256 newBalance);
event VaultWithdrawal(address indexed owner, uint256 amount, uint256 remainingBalance);
event EmergencyWithdrawal(address indexed owner, uint256 amount, uint256 penalty);
event EmergencyWithdrawalEnabled();
