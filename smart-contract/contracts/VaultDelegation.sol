// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VaultDelegation {
    struct Delegation {
        address delegate;
        uint256 permissions;
        uint256 expiry;
        bool active;
    }
    
    // Permission flags
    uint256 constant DEPOSIT = 1;
    uint256 constant WITHDRAW = 2;
    uint256 constant TRANSFER = 4;
    uint256 constant ADMIN = 8;
    
    mapping(address => mapping(address => Delegation)) public delegations;
    mapping(address => address[]) public userDelegates;
    mapping(address => address[]) public delegateUsers;
    
    event DelegationGranted(address indexed owner, address indexed delegate, uint256 permissions, uint256 expiry);
    event DelegationRevoked(address indexed owner, address indexed delegate);
    event DelegationUsed(address indexed owner, address indexed delegate, uint256 permission);
    
    modifier onlyValidDelegation(address owner, uint256 permission) {
        require(
            msg.sender == owner || 
            (delegations[owner][msg.sender].active && 
             delegations[owner][msg.sender].expiry > block.timestamp &&
             (delegations[owner][msg.sender].permissions & permission) != 0),
            "Unauthorized"
        );
        _;
    }
    
    function grantDelegation(
        address delegate,
        uint256 permissions,
        uint256 duration
    ) external {
        require(delegate != address(0), "Invalid delegate");
        require(delegate != msg.sender, "Cannot delegate to self");
        require(permissions > 0, "No permissions");
        
        uint256 expiry = block.timestamp + duration;
        
        if (!delegations[msg.sender][delegate].active) {
            userDelegates[msg.sender].push(delegate);
            delegateUsers[delegate].push(msg.sender);
        }
        
        delegations[msg.sender][delegate] = Delegation({
            delegate: delegate,
            permissions: permissions,
            expiry: expiry,
            active: true
        });
        
        emit DelegationGranted(msg.sender, delegate, permissions, expiry);
    }
    
    function revokeDelegation(address delegate) external {
        require(delegations[msg.sender][delegate].active, "No active delegation");
        
        delegations[msg.sender][delegate].active = false;
        
        emit DelegationRevoked(msg.sender, delegate);
    }
    
    function useDelegation(address owner, uint256 permission) external {
        require(delegations[owner][msg.sender].active, "No active delegation");
        require(delegations[owner][msg.sender].expiry > block.timestamp, "Delegation expired");
        require((delegations[owner][msg.sender].permissions & permission) != 0, "Permission denied");
        
        emit DelegationUsed(owner, msg.sender, permission);
    }
    
    function hasPermission(address owner, address delegate, uint256 permission) 
        external 
        view 
        returns (bool) 
    {
        if (owner == delegate) return true;
        
        Delegation memory delegation = delegations[owner][delegate];
        return delegation.active && 
               delegation.expiry > block.timestamp &&
               (delegation.permissions & permission) != 0;
    }
    
    function getDelegation(address owner, address delegate) 
        external 
        view 
        returns (uint256 permissions, uint256 expiry, bool active) 
    {
        Delegation memory delegation = delegations[owner][delegate];
        return (delegation.permissions, delegation.expiry, delegation.active);
    }
    
    function getUserDelegates(address user) external view returns (address[] memory) {
        return userDelegates[user];
    }
    
    function getDelegateUsers(address delegate) external view returns (address[] memory) {
        return delegateUsers[delegate];
    }
    
    function isExpired(address owner, address delegate) external view returns (bool) {
        return delegations[owner][delegate].expiry <= block.timestamp;
    }
    
    // Helper functions for permission checking
    function canDeposit(address owner, address delegate) external view returns (bool) {
        return this.hasPermission(owner, delegate, DEPOSIT);
    }
    
    function canWithdraw(address owner, address delegate) external view returns (bool) {
        return this.hasPermission(owner, delegate, WITHDRAW);
    }
    
    function canTransfer(address owner, address delegate) external view returns (bool) {
        return this.hasPermission(owner, delegate, TRANSFER);
    }
    
    function canAdmin(address owner, address delegate) external view returns (bool) {
        return this.hasPermission(owner, delegate, ADMIN);
    }
}
