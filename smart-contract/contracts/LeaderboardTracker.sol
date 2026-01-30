// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LeaderboardTracker {
    struct Saver {
        address user;
        uint256 totalSaved;
    }
    
    struct Achievement {
        string name;
        uint256 threshold;
        bool active;
    }
    
    Saver[] public topSavers;
    mapping(address => uint256) public userSavings;
    mapping(address => mapping(uint256 => bool)) public userAchievements;
    Achievement[] public achievements;
    
    event SavingsUpdated(address indexed user, uint256 amount, uint256 total);
    event AchievementUnlocked(address indexed user, uint256 achievementId);
    
    constructor() {
        achievements.push(Achievement("First Save", 1 ether, true));
        achievements.push(Achievement("Big Saver", 10 ether, true));
        achievements.push(Achievement("Whale", 100 ether, true));
    }
    
    function updateSavings(address user, uint256 amount) external {
        userSavings[user] += amount;
        _updateLeaderboard(user);
        _checkAchievements(user);
        emit SavingsUpdated(user, amount, userSavings[user]);
    }
    
    function _updateLeaderboard(address user) internal {
        uint256 userTotal = userSavings[user];
        
        // Find user in leaderboard or add if not exists
        int256 userIndex = -1;
        for (uint256 i = 0; i < topSavers.length; i++) {
            if (topSavers[i].user == user) {
                userIndex = int256(i);
                break;
            }
        }
        
        if (userIndex == -1) {
            topSavers.push(Saver(user, userTotal));
            userIndex = int256(topSavers.length - 1);
        } else {
            topSavers[uint256(userIndex)].totalSaved = userTotal;
        }
        
        // Bubble sort to maintain order
        for (uint256 i = uint256(userIndex); i > 0; i--) {
            if (topSavers[i].totalSaved > topSavers[i-1].totalSaved) {
                Saver memory temp = topSavers[i];
                topSavers[i] = topSavers[i-1];
                topSavers[i-1] = temp;
            } else {
                break;
            }
        }
    }
    
    function _checkAchievements(address user) internal {
        uint256 userTotal = userSavings[user];
        
        for (uint256 i = 0; i < achievements.length; i++) {
            if (achievements[i].active && 
                userTotal >= achievements[i].threshold && 
                !userAchievements[user][i]) {
                userAchievements[user][i] = true;
                emit AchievementUnlocked(user, i);
            }
        }
    }
    
    function getTopSavers(uint256 count) external view returns (Saver[] memory) {
        uint256 length = count > topSavers.length ? topSavers.length : count;
        Saver[] memory result = new Saver[](length);
        
        for (uint256 i = 0; i < length; i++) {
            result[i] = topSavers[i];
        }
        
        return result;
    }
    
    function getUserAchievements(address user) external view returns (bool[] memory) {
        bool[] memory result = new bool[](achievements.length);
        
        for (uint256 i = 0; i < achievements.length; i++) {
            result[i] = userAchievements[user][i];
        }
        
        return result;
    }
    
    function getAchievementsCount() external view returns (uint256) {
        return achievements.length;
    }
}
