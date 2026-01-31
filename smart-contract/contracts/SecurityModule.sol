// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SecurityModule is Ownable {
    struct SecuritySettings {
        bool multiSigRequired;
        uint256 dailyWithdrawLimit;
        uint256 lastWithdrawTime;
        uint256 withdrawnToday;
        address[] authorizedSigners;
        mapping(bytes32 => uint256) pendingTransactions;
    }
    
    mapping(address => SecuritySettings) public userSettings;
    
    event SecuritySettingsUpdated(address indexed user, bool multiSig, uint256 dailyLimit);
    event WithdrawLimitExceeded(address indexed user, uint256 attempted, uint256 limit);
    event MultiSigTransactionCreated(address indexed user, bytes32 txHash);
    
    constructor() Ownable(msg.sender) {}
    
    function updateSecuritySettings(
        bool _multiSigRequired,
        uint256 _dailyWithdrawLimit,
        address[] memory _authorizedSigners
    ) external {
        SecuritySettings storage settings = userSettings[msg.sender];
        settings.multiSigRequired = _multiSigRequired;
        settings.dailyWithdrawLimit = _dailyWithdrawLimit;
        
        // Clear existing signers
        delete settings.authorizedSigners;
        
        // Add new signers
        for (uint256 i = 0; i < _authorizedSigners.length; i++) {
            settings.authorizedSigners.push(_authorizedSigners[i]);
        }
        
        emit SecuritySettingsUpdated(msg.sender, _multiSigRequired, _dailyWithdrawLimit);
    }
    
    function checkWithdrawLimit(address _user, uint256 _amount) external returns (bool allowed) {
        SecuritySettings storage settings = userSettings[_user];
        
        // Reset daily counter if new day
        if (block.timestamp >= settings.lastWithdrawTime + 86400) {
            settings.withdrawnToday = 0;
            settings.lastWithdrawTime = block.timestamp;
        }
        
        if (settings.withdrawnToday + _amount > settings.dailyWithdrawLimit) {
            emit WithdrawLimitExceeded(_user, _amount, settings.dailyWithdrawLimit);
            return false;
        }
        
        settings.withdrawnToday += _amount;
        return true;
    }
    
    function createMultiSigTransaction(
        address _to,
        uint256 _amount,
        bytes memory _data
    ) external returns (bytes32 txHash) {
        require(userSettings[msg.sender].multiSigRequired, "MultiSig not required");
        
        txHash = keccak256(abi.encodePacked(_to, _amount, _data, block.timestamp));
        userSettings[msg.sender].pendingTransactions[txHash] = block.timestamp;
        
        emit MultiSigTransactionCreated(msg.sender, txHash);
    }
    
    function getAuthorizedSigners(address _user) external view returns (address[] memory) {
        return userSettings[_user].authorizedSigners;
    }
}
