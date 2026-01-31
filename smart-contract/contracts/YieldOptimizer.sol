// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract YieldOptimizer is Ownable, ReentrancyGuard {
    struct YieldStrategy {
        address protocol;
        uint256 apy;
        uint256 tvl;
        bool active;
    }
    
    mapping(uint256 => YieldStrategy) public strategies;
    uint256 public strategyCount;
    
    event StrategyAdded(uint256 indexed id, address protocol, uint256 apy);
    event StrategyUpdated(uint256 indexed id, uint256 newApy);
    event OptimalStrategySelected(uint256 indexed strategyId, uint256 apy);
    
    constructor() Ownable(msg.sender) {}
    
    function addStrategy(address _protocol, uint256 _apy) external onlyOwner {
        strategies[strategyCount] = YieldStrategy({
            protocol: _protocol,
            apy: _apy,
            tvl: 0,
            active: true
        });
        
        emit StrategyAdded(strategyCount, _protocol, _apy);
        strategyCount++;
    }
    
    function updateStrategyApy(uint256 _strategyId, uint256 _newApy) external onlyOwner {
        require(_strategyId < strategyCount, "Invalid strategy");
        strategies[_strategyId].apy = _newApy;
        emit StrategyUpdated(_strategyId, _newApy);
    }
    
    function getOptimalStrategy() external view returns (uint256 bestStrategyId, uint256 bestApy) {
        bestApy = 0;
        bestStrategyId = 0;
        
        for (uint256 i = 0; i < strategyCount; i++) {
            if (strategies[i].active && strategies[i].apy > bestApy) {
                bestApy = strategies[i].apy;
                bestStrategyId = i;
            }
        }
    }
}
