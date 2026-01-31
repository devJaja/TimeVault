// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AutomationManager is Ownable, ReentrancyGuard {
    struct RecurringDeposit {
        address vault;
        uint256 amount;
        uint256 frequency; // in seconds
        uint256 lastExecution;
        bool active;
    }
    
    mapping(address => mapping(uint256 => RecurringDeposit)) public recurringDeposits;
    mapping(address => uint256) public userDepositCount;
    
    event RecurringDepositCreated(address indexed user, uint256 indexed depositId, uint256 amount, uint256 frequency);
    event RecurringDepositExecuted(address indexed user, uint256 indexed depositId, uint256 amount);
    event RecurringDepositCancelled(address indexed user, uint256 indexed depositId);
    
    constructor() Ownable(msg.sender) {}
    
    function createRecurringDeposit(
        address _vault,
        uint256 _amount,
        uint256 _frequency
    ) external payable {
        require(_amount > 0, "Amount must be greater than 0");
        require(_frequency >= 86400, "Minimum frequency is 1 day");
        require(msg.value >= _amount, "Insufficient payment");
        
        uint256 depositId = userDepositCount[msg.sender]++;
        
        recurringDeposits[msg.sender][depositId] = RecurringDeposit({
            vault: _vault,
            amount: _amount,
            frequency: _frequency,
            lastExecution: block.timestamp,
            active: true
        });
        
        emit RecurringDepositCreated(msg.sender, depositId, _amount, _frequency);
    }
    
    function executeRecurringDeposit(address _user, uint256 _depositId) external {
        RecurringDeposit storage deposit = recurringDeposits[_user][_depositId];
        
        require(deposit.active, "Deposit not active");
        require(
            block.timestamp >= deposit.lastExecution + deposit.frequency,
            "Too early to execute"
        );
        
        deposit.lastExecution = block.timestamp;
        
        // Execute deposit to vault
        (bool success, ) = deposit.vault.call{value: deposit.amount}("");
        require(success, "Deposit failed");
        
        emit RecurringDepositExecuted(_user, _depositId, deposit.amount);
    }
    
    function cancelRecurringDeposit(uint256 _depositId) external {
        RecurringDeposit storage deposit = recurringDeposits[msg.sender][_depositId];
        require(deposit.active, "Deposit not active");
        
        deposit.active = false;
        emit RecurringDepositCancelled(msg.sender, _depositId);
    }
    
    function checkUpkeep(address _user, uint256 _depositId) external view returns (bool upkeepNeeded) {
        RecurringDeposit storage deposit = recurringDeposits[_user][_depositId];
        
        upkeepNeeded = deposit.active && 
                      (block.timestamp >= deposit.lastExecution + deposit.frequency);
    }
}
