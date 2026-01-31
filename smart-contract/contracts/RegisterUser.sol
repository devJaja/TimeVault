// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./lib/Events.sol";
import "./lib/Errors.sol";

contract RegisterUser {
    struct User {
        address userAddress;
        string username;
        string email;
        uint256 registrationTime;
        bool isActive;
        uint256 totalVaults;
        uint256 totalSaved;
    }
    
    mapping(address => User) public users;
    mapping(string => address) public usernameToAddress;
    address[] public userList;
    
    modifier onlyRegistered() {
        if (!users[msg.sender].isActive) revert TimeVault__UserNotRegistered();
        _;
    }
    
    function registerUser(string memory _username, string memory _email) external {
        if (users[msg.sender].isActive) revert TimeVault__UserAlreadyRegistered();
        if (usernameToAddress[_username] != address(0)) revert TimeVault__UsernameExists();
        
        users[msg.sender] = User({
            userAddress: msg.sender,
            username: _username,
            email: _email,
            registrationTime: block.timestamp,
            isActive: true,
            totalVaults: 0,
            totalSaved: 0
        });
        
        usernameToAddress[_username] = msg.sender;
        userList.push(msg.sender);
        
        emit UserRegistered(msg.sender, _username);
    }
    
    function updateUserStats(address _user, uint256 _vaultCount, uint256 _totalSaved) external {
        if (!users[_user].isActive) revert TimeVault__UserNotRegistered();
        users[_user].totalVaults = _vaultCount;
        users[_user].totalSaved = _totalSaved;
    }
    
    function getUserCount() external view returns (uint256) {
        return userList.length;
    }
}
