// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract EnhancedTimeVault is Ownable, ReentrancyGuard {
    struct Vault {
        string name;
        uint256 unlockTime;
        uint256 goalAmount;
        uint256 balance;
        bool goalReached;
        bool emergencyWithdrawalEnabled;
        uint256 yieldEarned;
        address yieldStrategy;
        uint256 createdAt;
        VaultType vaultType;
    }
    
    enum VaultType { PERSONAL, JOINT, BUSINESS, CHARITY }
    
    mapping(address => Vault[]) public userVaults;
    mapping(address => uint256) public totalUserBalance;
    
    uint256 public protocolFee = 50; // 0.5%
    address public feeRecipient;
    uint256 public totalValueLocked;
    
    event VaultCreated(address indexed user, uint256 vaultIndex, string name, VaultType vaultType);
    event VaultDeposit(address indexed user, uint256 vaultIndex, uint256 amount);
    event VaultWithdrawal(address indexed user, uint256 vaultIndex, uint256 amount);
    event YieldEarned(address indexed user, uint256 vaultIndex, uint256 yield);
    event EmergencyWithdrawal(address indexed user, uint256 vaultIndex, uint256 amount, uint256 penalty);
    
    constructor(address _feeRecipient) Ownable(msg.sender) {
        feeRecipient = _feeRecipient;
    }
    
    function createVault(
        string memory _name,
        uint256 _unlockTime,
        uint256 _goalAmount,
        VaultType _vaultType
    ) external payable returns (uint256) {
        require(_unlockTime > block.timestamp, "Unlock time must be in future");
        require(bytes(_name).length > 0, "Name cannot be empty");
        
        Vault memory newVault = Vault({
            name: _name,
            unlockTime: _unlockTime,
            goalAmount: _goalAmount,
            balance: msg.value,
            goalReached: msg.value >= _goalAmount && _goalAmount > 0,
            emergencyWithdrawalEnabled: false,
            yieldEarned: 0,
            yieldStrategy: address(0),
            createdAt: block.timestamp,
            vaultType: _vaultType
        });
        
        userVaults[msg.sender].push(newVault);
        uint256 vaultIndex = userVaults[msg.sender].length - 1;
        
        totalUserBalance[msg.sender] += msg.value;
        totalValueLocked += msg.value;
        
        emit VaultCreated(msg.sender, vaultIndex, _name, _vaultType);
        
        if (msg.value > 0) {
            emit VaultDeposit(msg.sender, vaultIndex, msg.value);
        }
        
        return vaultIndex;
    }
    
    function depositToVault(uint256 _vaultIndex) external payable nonReentrant {
        require(_vaultIndex < userVaults[msg.sender].length, "Invalid vault index");
        require(msg.value > 0, "Amount must be greater than 0");
        
        Vault storage vault = userVaults[msg.sender][_vaultIndex];
        vault.balance += msg.value;
        
        if (vault.goalAmount > 0 && vault.balance >= vault.goalAmount) {
            vault.goalReached = true;
        }
        
        totalUserBalance[msg.sender] += msg.value;
        totalValueLocked += msg.value;
        
        emit VaultDeposit(msg.sender, _vaultIndex, msg.value);
    }
    
    function withdrawFromVault(uint256 _vaultIndex, uint256 _amount) external nonReentrant {
        require(_vaultIndex < userVaults[msg.sender].length, "Invalid vault index");
        
        Vault storage vault = userVaults[msg.sender][_vaultIndex];
        require(_amount <= vault.balance, "Insufficient balance");
        require(
            block.timestamp >= vault.unlockTime || vault.goalReached,
            "Vault is still locked"
        );
        
        vault.balance -= _amount;
        totalUserBalance[msg.sender] -= _amount;
        totalValueLocked -= _amount;
        
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Transfer failed");
        
        emit VaultWithdrawal(msg.sender, _vaultIndex, _amount);
    }
    
    function emergencyWithdraw(uint256 _vaultIndex) external nonReentrant {
        require(_vaultIndex < userVaults[msg.sender].length, "Invalid vault index");
        
        Vault storage vault = userVaults[msg.sender][_vaultIndex];
        require(vault.emergencyWithdrawalEnabled, "Emergency withdrawal not enabled");
        require(vault.balance > 0, "No balance to withdraw");
        
        uint256 penalty = (vault.balance * protocolFee) / 10000;
        uint256 withdrawAmount = vault.balance - penalty;
        
        vault.balance = 0;
        totalUserBalance[msg.sender] -= (withdrawAmount + penalty);
        totalValueLocked -= (withdrawAmount + penalty);
        
        // Transfer penalty to fee recipient
        if (penalty > 0) {
            (bool feeSuccess, ) = payable(feeRecipient).call{value: penalty}("");
            require(feeSuccess, "Fee transfer failed");
        }
        
        // Transfer remaining amount to user
        (bool success, ) = payable(msg.sender).call{value: withdrawAmount}("");
        require(success, "Transfer failed");
        
        emit EmergencyWithdrawal(msg.sender, _vaultIndex, withdrawAmount, penalty);
    }
    
    function enableEmergencyWithdrawal(uint256 _vaultIndex) external {
        require(_vaultIndex < userVaults[msg.sender].length, "Invalid vault index");
        userVaults[msg.sender][_vaultIndex].emergencyWithdrawalEnabled = true;
    }
    
    function getUserVaults(address _user) external view returns (Vault[] memory) {
        return userVaults[_user];
    }
    
    function getVaultCount(address _user) external view returns (uint256) {
        return userVaults[_user].length;
    }
    
    function updateProtocolFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= 1000, "Fee cannot exceed 10%"); // Max 10%
        protocolFee = _newFee;
    }
    
    function updateFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "Invalid recipient");
        feeRecipient = _newRecipient;
    }
}
