// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./lib/Events.sol";
import "./lib/Errors.sol";

contract Subscription {
    enum SubscriptionTier { Basic, Premium, Enterprise }
    
    struct SubscriptionPlan {
        SubscriptionTier tier;
        uint256 price;
        uint256 duration;
        uint256 maxVaults;
        bool yieldEnabled;
        bool automationEnabled;
    }
    
    struct UserSubscription {
        SubscriptionTier tier;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
    }
    
    mapping(SubscriptionTier => SubscriptionPlan) public plans;
    mapping(address => UserSubscription) public subscriptions;
    address public owner;
    
    modifier onlyOwner() {
        if (msg.sender != owner) revert TimeVault__NotOwner();
        _;
    }
    
    constructor() {
        owner = msg.sender;
        
        plans[SubscriptionTier.Basic] = SubscriptionPlan({
            tier: SubscriptionTier.Basic,
            price: 0.01 ether,
            duration: 30 days,
            maxVaults: 3,
            yieldEnabled: false,
            automationEnabled: false
        });
        
        plans[SubscriptionTier.Premium] = SubscriptionPlan({
            tier: SubscriptionTier.Premium,
            price: 0.05 ether,
            duration: 30 days,
            maxVaults: 10,
            yieldEnabled: true,
            automationEnabled: false
        });
        
        plans[SubscriptionTier.Enterprise] = SubscriptionPlan({
            tier: SubscriptionTier.Enterprise,
            price: 0.1 ether,
            duration: 30 days,
            maxVaults: 50,
            yieldEnabled: true,
            automationEnabled: true
        });
    }
    
    function subscribe(SubscriptionTier _tier) external payable {
        SubscriptionPlan memory plan = plans[_tier];
        if (msg.value < plan.price) revert TimeVault__InsufficientFunds();
        
        subscriptions[msg.sender] = UserSubscription({
            tier: _tier,
            startTime: block.timestamp,
            endTime: block.timestamp + plan.duration,
            isActive: true
        });
        
        emit SubscriptionActivated(msg.sender, uint8(_tier));
    }
    
    function isSubscriptionActive(address _user) external view returns (bool) {
        return subscriptions[_user].isActive && subscriptions[_user].endTime > block.timestamp;
    }
    
    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
