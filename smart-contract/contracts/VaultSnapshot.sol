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
    uint256 public minSnapshotInterval = 3600; // 1 hour
    
    event SnapshotTaken(address indexed user, uint256 balance, uint256 timestamp);
    
    function takeSnapshot(address user, uint256 balance) external {
        require(user != address(0), "Invalid user");
        require(block.timestamp >= lastSnapshotTime[user] + minSnapshotInterval, "Too frequent");
        
        userSnapshots[user].push(Snapshot({
            timestamp: block.timestamp,
            balance: balance,
            blockNumber: block.number
        }));
        
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
    
    function getLatestSnapshot(address user) external view returns (uint256, uint256, uint256) {
        require(userSnapshots[user].length > 0, "No snapshots");
        Snapshot memory snapshot = userSnapshots[user][userSnapshots[user].length - 1];
        return (snapshot.timestamp, snapshot.balance, snapshot.blockNumber);
    }
}
