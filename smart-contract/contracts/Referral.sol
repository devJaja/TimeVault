// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./lib/Events.sol";
import "./lib/Errors.sol";

contract Referral {
    struct ReferralData {
        address referrer;
        uint256 totalReferred;
        uint256 totalEarned;
        uint256 tier;
    }
    
    mapping(address => ReferralData) public referrals;
    mapping(address => address) public referredBy;
    uint256[] public tierRewards = [100, 200, 500, 1000]; // Basis points (1%, 2%, 5%, 10%)
    uint256[] public tierThresholds = [5, 15, 50, 100]; // Number of referrals needed
    
    function setReferrer(address _referrer) external {
        if (referredBy[msg.sender] != address(0)) revert TimeVault__ReferrerAlreadySet();
        if (_referrer == msg.sender) revert TimeVault__SelfReferral();
        
        referredBy[msg.sender] = _referrer;
        referrals[_referrer].totalReferred++;
        
        // Update tier based on total referrals
        updateTier(_referrer);
        
        emit ReferralSet(msg.sender, _referrer);
    }
    
    function processReferralReward(address _user, uint256 _amount) external {
        address referrer = referredBy[_user];
        if (referrer == address(0)) return;
        
        uint256 tier = referrals[referrer].tier;
        uint256 reward = (_amount * tierRewards[tier]) / 10000;
        
        referrals[referrer].totalEarned += reward;
        payable(referrer).transfer(reward);
        
        emit ReferralReward(referrer, _user, reward);
    }
    
    function updateTier(address _user) internal {
        uint256 totalReferred = referrals[_user].totalReferred;
        
        for (uint256 i = tierThresholds.length; i > 0; i--) {
            if (totalReferred >= tierThresholds[i - 1]) {
                referrals[_user].tier = i - 1;
                break;
            }
        }
    }
    
    function getReferralInfo(address _user) external view returns (address, uint256, uint256, uint256) {
        ReferralData memory data = referrals[_user];
        return (data.referrer, data.totalReferred, data.totalEarned, data.tier);
    }
}
