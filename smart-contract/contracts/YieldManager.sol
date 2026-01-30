// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract YieldManager {
    struct YieldStrategy {
        address strategyAddress;
        string name;
        uint256 apy;
        uint256 totalDeposited;
        bool active;
    }
    
    mapping(uint256 => YieldStrategy) public strategies;
    mapping(address => mapping(uint256 => uint256)) public userDeposits;
    mapping(address => uint256) public userRewards;
    uint256 public strategyCount;
    address public owner;
    
    event StrategyAdded(uint256 indexed strategyId, string name, uint256 apy);
    event Deposited(address indexed user, uint256 indexed strategyId, uint256 amount);
    event Withdrawn(address indexed user, uint256 indexed strategyId, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function addStrategy(address strategyAddress, string memory name, uint256 apy) external onlyOwner {
        require(strategyAddress != address(0), "Invalid address");
        require(bytes(name).length > 0, "Name required");
        
        strategies[strategyCount] = YieldStrategy({
            strategyAddress: strategyAddress,
            name: name,
            apy: apy,
            totalDeposited: 0,
            active: true
        });
        
        emit StrategyAdded(strategyCount, name, apy);
        strategyCount++;
    }
    
    function deposit(uint256 strategyId, uint256 amount) external payable {
        require(strategies[strategyId].active, "Strategy not active");
        require(amount > 0, "Amount must be positive");
        require(msg.value == amount, "Value mismatch");
        
        userDeposits[msg.sender][strategyId] += amount;
        strategies[strategyId].totalDeposited += amount;
        
        emit Deposited(msg.sender, strategyId, amount);
    }
    
    function withdraw(uint256 strategyId, uint256 amount) external {
        require(userDeposits[msg.sender][strategyId] >= amount, "Insufficient balance");
        
        userDeposits[msg.sender][strategyId] -= amount;
        strategies[strategyId].totalDeposited -= amount;
        
        payable(msg.sender).transfer(amount);
        emit Withdrawn(msg.sender, strategyId, amount);
    }
    
    function calculateRewards(address user, uint256 strategyId) external view returns (uint256) {
        uint256 deposit = userDeposits[user][strategyId];
        uint256 apy = strategies[strategyId].apy;
        return (deposit * apy) / 10000; // Simple APY calculation
    }
    
    function deactivateStrategy(uint256 strategyId) external onlyOwner {
        require(strategyId < strategyCount, "Invalid strategy");
        strategies[strategyId].active = false;
    }
    
    function getStrategy(uint256 strategyId) external view returns (YieldStrategy memory) {
        return strategies[strategyId];
    }
}
