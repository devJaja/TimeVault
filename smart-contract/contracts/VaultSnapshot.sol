// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VaultSnapshot {
    struct Snapshot {
        uint256 timestamp;
        uint256 balance;
        uint256 blockNumber;
    }
    
    mapping(address => Snapshot[]) public userSnapshots;
    mapping(address => uint256) public lastSnapshotTime;
    mapping(address => uint256) public maxSnapshots;
    uint256 public minSnapshotInterval = 900; // 15 minutes
    uint256 public defaultMaxSnapshots = 500;
    
    event SnapshotTaken(address indexed user, uint256 balance, uint256 timestamp);
    event SnapshotLimitUpdated(address indexed user, uint256 newLimit);
    event SnapshotsCleared(address indexed user);
    
    function takeSnapshot(address user, uint256 balance) external {
        require(user != address(0), "Invalid user");
        require(balance > 0, "Balance must be positive");
        require(block.timestamp >= lastSnapshotTime[user] + minSnapshotInterval, "Too frequent");
        
        uint256 userMaxSnapshots = maxSnapshots[user] == 0 ? defaultMaxSnapshots : maxSnapshots[user];
        
        // Optimize gas by avoiding array shifts for large arrays
        if (userSnapshots[user].length >= userMaxSnapshots) {
            if (userMaxSnapshots > 100) {
                // For large arrays, just replace oldest
                userSnapshots[user][0] = Snapshot({
                    timestamp: block.timestamp,
                    balance: balance,
                    blockNumber: block.number
                });
            } else {
                // For small arrays, shift elements
                for (uint256 i = 0; i < userSnapshots[user].length - 1; i++) {
                    userSnapshots[user][i] = userSnapshots[user][i + 1];
                }
                userSnapshots[user][userSnapshots[user].length - 1] = Snapshot({
                    timestamp: block.timestamp,
                    balance: balance,
                    blockNumber: block.number
                });
            }
        } else {
            userSnapshots[user].push(Snapshot({
                timestamp: block.timestamp,
                balance: balance,
                blockNumber: block.number
            }));
        }
        
        lastSnapshotTime[user] = block.timestamp;
        emit SnapshotTaken(user, balance, block.timestamp);
    }
    
    function getSnapshot(address user, uint256 index) external view returns (uint256, uint256, uint256) {
        require(index < userSnapshots[user].length, "Invalid index");
        Snapshot memory snapshot = userSnapshots[user][index];
        return (snapshot.timestamp, snapshot.balance, snapshot.blockNumber);
    }
    
    function getSnapshotCount(address user) external view returns (uint256) {
        return userSnapshots[user].length;
    }
    
    function getSnapshotsByTimeRange(address user, uint256 startTime, uint256 endTime) 
        external 
        view 
        returns (Snapshot[] memory) 
    {
        require(startTime <= endTime, "Invalid time range");
        require(endTime <= block.timestamp, "End time cannot be in future");
        
        Snapshot[] memory allSnapshots = userSnapshots[user];
        uint256 count = 0;
        
        for (uint256 i = 0; i < allSnapshots.length; i++) {
            if (allSnapshots[i].timestamp >= startTime && allSnapshots[i].timestamp <= endTime) {
                count++;
            }
        }
        
        Snapshot[] memory result = new Snapshot[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < allSnapshots.length; i++) {
            if (allSnapshots[i].timestamp >= startTime && allSnapshots[i].timestamp <= endTime) {
                result[index] = allSnapshots[i];
                index++;
            }
        }
        
        return result;
    }
    
    function setMaxSnapshots(address user, uint256 max) external {
        require(max > 0 && max <= 10000, "Invalid max snapshots");
        maxSnapshots[user] = max;
        emit SnapshotLimitUpdated(user, max);
    }
    
    function getBalanceAtTime(address user, uint256 targetTime) external view returns (uint256) {
        Snapshot[] memory snapshots = userSnapshots[user];
        require(snapshots.length > 0, "No snapshots available");
        
        if (targetTime <= snapshots[0].timestamp) {
            return snapshots[0].balance;
        }
        
        if (targetTime >= snapshots[snapshots.length - 1].timestamp) {
            return snapshots[snapshots.length - 1].balance;
        }
        
        for (uint256 i = 1; i < snapshots.length; i++) {
            if (snapshots[i].timestamp >= targetTime) {
                return snapshots[i - 1].balance;
            }
        }
        
        return snapshots[snapshots.length - 1].balance;
    }
    
    function getGrowthRate(address user, uint256 days) external view returns (int256) {
        require(days > 0, "Days must be positive");
        Snapshot[] memory snapshots = userSnapshots[user];
        require(snapshots.length >= 2, "Need at least 2 snapshots");
        
        uint256 targetTime = block.timestamp - (days * 86400);
        uint256 oldBalance = this.getBalanceAtTime(user, targetTime);
        uint256 currentBalance = snapshots[snapshots.length - 1].balance;
        
        if (oldBalance == 0) return 0;
        
        return int256((currentBalance * 10000) / oldBalance) - 10000; // Return as basis points
    }
    
    function getMinBalance(address user, uint256 days) external view returns (uint256) {
        require(days > 0, "Days must be positive");
        Snapshot[] memory snapshots = userSnapshots[user];
        require(snapshots.length > 0, "No snapshots available");
        
        uint256 targetTime = block.timestamp - (days * 86400);
        uint256 minBalance = type(uint256).max;
        bool found = false;
        
        for (uint256 i = 0; i < snapshots.length; i++) {
            if (snapshots[i].timestamp >= targetTime) {
                if (snapshots[i].balance < minBalance) {
                    minBalance = snapshots[i].balance;
                }
                found = true;
            }
        }
        
        return found ? minBalance : 0;
    }
    
    function getMaxBalance(address user, uint256 days) external view returns (uint256) {
        require(days > 0, "Days must be positive");
        Snapshot[] memory snapshots = userSnapshots[user];
        require(snapshots.length > 0, "No snapshots available");
        
        uint256 targetTime = block.timestamp - (days * 86400);
        uint256 maxBalance = 0;
        
        for (uint256 i = 0; i < snapshots.length; i++) {
            if (snapshots[i].timestamp >= targetTime && snapshots[i].balance > maxBalance) {
                maxBalance = snapshots[i].balance;
            }
        }
        
        return maxBalance;
    }
    
    function getAverageBalance(address user, uint256 days) external view returns (uint256) {
        require(days > 0, "Days must be positive");
        Snapshot[] memory snapshots = userSnapshots[user];
        require(snapshots.length > 0, "No snapshots available");
        
        uint256 targetTime = block.timestamp - (days * 86400);
        uint256 sum = 0;
        uint256 count = 0;
        
        for (uint256 i = 0; i < snapshots.length; i++) {
            if (snapshots[i].timestamp >= targetTime) {
                sum += snapshots[i].balance;
                count++;
            }
        }
        
        return count > 0 ? sum / count : 0;
    }
    
    function clearSnapshots(address user) external {
        require(user != address(0), "Invalid user");
        delete userSnapshots[user];
        lastSnapshotTime[user] = 0;
        emit SnapshotsCleared(user);
    }
    
    function isSnapshotDue(address user) external view returns (bool) {
        return block.timestamp >= lastSnapshotTime[user] + minSnapshotInterval;
    }
    
    function getLatestSnapshot(address user) external view returns (uint256, uint256, uint256) {
        require(userSnapshots[user].length > 0, "No snapshots");
        Snapshot memory snapshot = userSnapshots[user][userSnapshots[user].length - 1];
        return (snapshot.timestamp, snapshot.balance, snapshot.blockNumber);
    }
}
