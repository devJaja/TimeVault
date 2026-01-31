// Sources flattened with hardhat v3.1.5 https://hardhat.org

// SPDX-License-Identifier: MIT

// File contracts/lib/Errors.sol

// Original license: SPDX_License_Identifier: MIT
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


// File contracts/lib/Events.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.24;

// --- Events for TimeVault.sol ---
event VaultDeposit(address indexed depositor, uint256 amount, uint256 newBalance);
event VaultWithdrawal(address indexed owner, uint256 amount, uint256 remainingBalance);
event EmergencyWithdrawal(address indexed owner, uint256 amount, uint256 penalty);
event EmergencyWithdrawalEnabled();


// File contracts/TimeVault.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.24;


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


// File contracts/VaultFactory.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.24;


contract VaultFactory {
    address[] public vaults;
    mapping(address => address[]) public userVaults;
    mapping(address => bool) public isVault;
    
    uint256 public totalVaults;
    address public owner;
    uint256 public protocolFee = 50; // 0.5% in basis points
    
    event VaultCreated(
        address indexed vault,
        address indexed owner,
        string name,
        uint256 unlockTime,
        uint256 goalAmount
    );
    
    event ProtocolFeeUpdated(uint256 oldFee, uint256 newFee);
    
    modifier onlyOwner() {
        if (msg.sender != owner) revert VaultFactory__NotOwner();
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function createVault(
        string memory _name,
        uint256 _unlockTime,
        uint256 _goalAmount
    ) external returns (address) {
        if (bytes(_name).length == 0) revert VaultFactory__EmptyName();
        if (_unlockTime <= block.timestamp) revert VaultFactory__InvalidUnlockTime();
        
        TimeVault vault = new TimeVault(
            _name,
            _unlockTime,
            _goalAmount,
            msg.sender,
            protocolFee
        );
        
        address vaultAddress = address(vault);
        
        vaults.push(vaultAddress);
        userVaults[msg.sender].push(vaultAddress);
        isVault[vaultAddress] = true;
        totalVaults++;
        
        emit VaultCreated(vaultAddress, msg.sender, _name, _unlockTime, _goalAmount);
        
        return vaultAddress;
    }
    
    function getUserVaults(address _user) external view returns (address[] memory) {
        return userVaults[_user];
    }
    
    function getAllVaults() external view returns (address[] memory) {
        return vaults;
    }
    
    function setProtocolFee(uint256 _newFee) external onlyOwner {
        if (_newFee > 1000) revert VaultFactory__FeeTooHigh(); // Max 10%
        
        uint256 oldFee = protocolFee;
        protocolFee = _newFee;
        
        emit ProtocolFeeUpdated(oldFee, _newFee);
    }
    
    function transferOwnership(address _newOwner) external onlyOwner {
        if (_newOwner == address(0)) revert VaultFactory__ZeroAddress();
        owner = _newOwner;
    }
}

