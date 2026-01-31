// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./lib/Events.sol";
import "./lib/Errors.sol";

contract Staking {
    struct StakeInfo {
        uint256 amount;
        uint256 startTime;
        uint256 lockPeriod;
        uint256 rewardRate;
        bool withdrawn;
    }
    
    mapping(address => StakeInfo[]) public stakes;
    mapping(uint256 => uint256) public lockPeriodRates; // lock period => reward rate (basis points)
    uint256 public totalStaked;
    uint256 public rewardPool;
    address public owner;
    
    modifier onlyOwner() {
        if (msg.sender != owner) revert TimeVault__NotOwner();
        _;
    }
    
    constructor() {
        owner = msg.sender;
        lockPeriodRates[30 days] = 500;   // 5% APY
        lockPeriodRates[90 days] = 800;   // 8% APY
        lockPeriodRates[180 days] = 1200; // 12% APY
        lockPeriodRates[365 days] = 1500; // 15% APY
    }
    
    function stake(uint256 _lockPeriod) external payable {
        if (msg.value == 0) revert TimeVault__ZeroAmount();
        if (lockPeriodRates[_lockPeriod] == 0) revert TimeVault__InvalidLockPeriod();
        
        stakes[msg.sender].push(StakeInfo({
            amount: msg.value,
            startTime: block.timestamp,
            lockPeriod: _lockPeriod,
            rewardRate: lockPeriodRates[_lockPeriod],
            withdrawn: false
        }));
        
        totalStaked += msg.value;
        emit Staked(msg.sender, msg.value, _lockPeriod);
    }
    
    function unstake(uint256 _stakeIndex) external {
        StakeInfo storage stakeInfo = stakes[msg.sender][_stakeIndex];
        if (stakeInfo.withdrawn) revert TimeVault__AlreadyWithdrawn();
        if (block.timestamp < stakeInfo.startTime + stakeInfo.lockPeriod) revert TimeVault__StakeLocked();
        
        uint256 reward = calculateReward(msg.sender, _stakeIndex);
        uint256 totalAmount = stakeInfo.amount + reward;
        
        stakeInfo.withdrawn = true;
        totalStaked -= stakeInfo.amount;
        rewardPool -= reward;
        
        payable(msg.sender).transfer(totalAmount);
        emit Unstaked(msg.sender, stakeInfo.amount, reward);
    }
    
    function calculateReward(address _user, uint256 _stakeIndex) public view returns (uint256) {
        StakeInfo memory stakeInfo = stakes[_user][_stakeIndex];
        if (stakeInfo.withdrawn) return 0;
        
        uint256 timeStaked = block.timestamp - stakeInfo.startTime;
        if (timeStaked < stakeInfo.lockPeriod) return 0;
        
        return (stakeInfo.amount * stakeInfo.rewardRate * timeStaked) / (10000 * 365 days);
    }
    
    function addRewards() external payable onlyOwner {
        rewardPool += msg.value;
    }
}
