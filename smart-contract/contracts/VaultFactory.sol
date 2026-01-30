// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./TimeVault.sol";
import "./lib/Errors.sol";

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
