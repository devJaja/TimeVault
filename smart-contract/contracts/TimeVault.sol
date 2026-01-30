// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./lib/Errors.sol";
import "./lib/Events.sol";

contract TimeVault {
    string public name;
    uint256 public unlockTime;
    uint256 public goalAmount;
    address public owner;
    uint256 public balance;
    uint256 public protocolFee;
    bool public goalReached;
    bool public emergencyWithdrawalEnabled;
    
    modifier onlyOwner() {
        if (msg.sender != owner) revert TimeVault__NotOwner();
        _;
    }
    
    modifier onlyAfterUnlock() {
        if (block.timestamp < unlockTime && !goalReached) revert TimeVault__VaultLocked();
        _;
    }
    
    constructor(
        string memory _name,
        uint256 _unlockTime,
        uint256 _goalAmount,
        address _owner,
        uint256 _protocolFee
    ) {
        name = _name;
        unlockTime = _unlockTime;
        goalAmount = _goalAmount;
        owner = _owner;
        protocolFee = _protocolFee;
    }
    
    function deposit() external payable onlyOwner {
        if (msg.value == 0) revert TimeVault__ZeroAmount();
        
        balance += msg.value;
        
        if (goalAmount > 0 && balance >= goalAmount) {
            goalReached = true;
        }
        
        emit VaultDeposit(msg.sender, msg.value, balance);
    }
    
    function withdraw(uint256 _amount) external onlyOwner onlyAfterUnlock {
        if (_amount == 0) revert TimeVault__ZeroAmount();
        if (_amount > balance) revert TimeVault__InsufficientBalance();
        
        balance -= _amount;
        
        (bool success, ) = payable(owner).call{value: _amount}("");
        if (!success) revert TimeVault__TransferFailed();
        
        emit VaultWithdrawal(owner, _amount, balance);
    }
    
    function emergencyWithdraw() external onlyOwner {
        if (!emergencyWithdrawalEnabled) revert TimeVault__EmergencyNotEnabled();
        
        uint256 amount = balance;
        balance = 0;
        
        // Apply penalty fee
        uint256 penalty = (amount * protocolFee) / 10000;
        uint256 withdrawAmount = amount - penalty;
        
        (bool success, ) = payable(owner).call{value: withdrawAmount}("");
        if (!success) revert TimeVault__TransferFailed();
        
        emit EmergencyWithdrawal(owner, withdrawAmount, penalty);
    }
    
    function enableEmergencyWithdrawal() external onlyOwner {
        emergencyWithdrawalEnabled = true;
        emit EmergencyWithdrawalEnabled();
    }
    
    function getVaultInfo() external view returns (
        string memory _name,
        uint256 _unlockTime,
        uint256 _goalAmount,
        address _owner,
        uint256 _balance,
        bool _goalReached,
        bool _emergencyEnabled
    ) {
        return (name, unlockTime, goalAmount, owner, balance, goalReached, emergencyWithdrawalEnabled);
    }
    
    receive() external payable {
        if (msg.sender != owner) revert TimeVault__NotOwner();
        balance += msg.value;
        
        if (goalAmount > 0 && balance >= goalAmount) {
            goalReached = true;
        }
        
        emit VaultDeposit(msg.sender, msg.value, balance);
    }
}
