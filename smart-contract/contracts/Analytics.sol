// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./lib/Events.sol";
import "./lib/Errors.sol";

contract Analytics {
    struct VaultMetrics {
        uint256 totalVaults;
        uint256 totalValueLocked;
        uint256 totalUsers;
        uint256 averageVaultSize;
        uint256 totalWithdrawals;
    }
    
    struct UserMetrics {
        uint256 vaultCount;
        uint256 totalDeposited;
        uint256 totalWithdrawn;
        uint256 averageHoldTime;
        uint256 successfulVaults;
    }
    
    mapping(address => UserMetrics) public userMetrics;
    VaultMetrics public globalMetrics;
    mapping(uint256 => uint256) public dailyDeposits; // timestamp => amount
    mapping(uint256 => uint256) public dailyWithdrawals;
    
    address public dataProvider;
    
    modifier onlyDataProvider() {
        if (msg.sender != dataProvider) revert TimeVault__NotAuthorized();
        _;
    }
    
    constructor() {
        dataProvider = msg.sender;
    }
    
    function updateGlobalMetrics(
        uint256 _totalVaults,
        uint256 _totalValueLocked,
        uint256 _totalUsers,
        uint256 _totalWithdrawals
    ) external onlyDataProvider {
        globalMetrics.totalVaults = _totalVaults;
        globalMetrics.totalValueLocked = _totalValueLocked;
        globalMetrics.totalUsers = _totalUsers;
        globalMetrics.totalWithdrawals = _totalWithdrawals;
        
        if (_totalVaults > 0) {
            globalMetrics.averageVaultSize = _totalValueLocked / _totalVaults;
        }
        
        emit MetricsUpdated(_totalVaults, _totalValueLocked, _totalUsers);
    }
    
    function updateUserMetrics(
        address _user,
        uint256 _vaultCount,
        uint256 _totalDeposited,
        uint256 _totalWithdrawn,
        uint256 _successfulVaults
    ) external onlyDataProvider {
        userMetrics[_user] = UserMetrics({
            vaultCount: _vaultCount,
            totalDeposited: _totalDeposited,
            totalWithdrawn: _totalWithdrawn,
            averageHoldTime: 0, // Calculate separately
            successfulVaults: _successfulVaults
        });
    }
    
    function recordDailyActivity(uint256 _day, uint256 _deposits, uint256 _withdrawals) external onlyDataProvider {
        dailyDeposits[_day] = _deposits;
        dailyWithdrawals[_day] = _withdrawals;
    }
    
    function getGrowthRate(uint256 _days) external view returns (uint256) {
        uint256 currentDay = block.timestamp / 1 days;
        uint256 pastDay = currentDay - _days;
        
        uint256 currentDeposits = dailyDeposits[currentDay];
        uint256 pastDeposits = dailyDeposits[pastDay];
        
        if (pastDeposits == 0) return 0;
        return ((currentDeposits - pastDeposits) * 10000) / pastDeposits; // Basis points
    }
    
    function getUserSuccessRate(address _user) external view returns (uint256) {
        UserMetrics memory metrics = userMetrics[_user];
        if (metrics.vaultCount == 0) return 0;
        return (metrics.successfulVaults * 10000) / metrics.vaultCount; // Basis points
    }
}
