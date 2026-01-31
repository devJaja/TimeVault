// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Leaderboard is Ownable {
    struct UserStats {
        uint256 totalSaved;
        uint256 vaultCount;
        uint256 streakDays;
        uint256 lastDepositTime;
        string[] badges;
        uint256 referralCount;
    }
    
    struct LeaderboardEntry {
        address user;
        uint256 score;
        string category;
    }
    
    mapping(address => UserStats) public userStats;
    mapping(string => LeaderboardEntry[]) public leaderboards;
    
    string[] public categories = ["totalSaved", "streakDays", "vaultCount", "referrals"];
    
    event BadgeEarned(address indexed user, string badge);
    event LeaderboardUpdated(string category, address user, uint256 newScore);
    event StreakUpdated(address indexed user, uint256 newStreak);
    
    constructor() Ownable(msg.sender) {}
    
    function updateUserStats(
        address _user,
        uint256 _depositAmount,
        bool _newVault
    ) external onlyOwner {
        UserStats storage stats = userStats[_user];
        
        // Update total saved
        stats.totalSaved += _depositAmount;
        
        // Update vault count
        if (_newVault) {
            stats.vaultCount++;
        }
        
        // Update streak
        _updateStreak(_user);
        
        // Check for new badges
        _checkBadges(_user);
        
        // Update leaderboards
        _updateLeaderboards(_user);
    }
    
    function _updateStreak(address _user) internal {
        UserStats storage stats = userStats[_user];
        
        if (stats.lastDepositTime == 0) {
            stats.streakDays = 1;
        } else {
            uint256 daysSinceLastDeposit = (block.timestamp - stats.lastDepositTime) / 86400;
            
            if (daysSinceLastDeposit == 1) {
                stats.streakDays++;
            } else if (daysSinceLastDeposit > 1) {
                stats.streakDays = 1;
            }
        }
        
        stats.lastDepositTime = block.timestamp;
        emit StreakUpdated(_user, stats.streakDays);
    }
    
    function _checkBadges(address _user) internal {
        UserStats storage stats = userStats[_user];
        
        // First Deposit Badge
        if (stats.totalSaved > 0 && !_hasBadge(_user, "First Deposit")) {
            stats.badges.push("First Deposit");
            emit BadgeEarned(_user, "First Deposit");
        }
        
        // Consistent Saver Badge (7 day streak)
        if (stats.streakDays >= 7 && !_hasBadge(_user, "Consistent Saver")) {
            stats.badges.push("Consistent Saver");
            emit BadgeEarned(_user, "Consistent Saver");
        }
        
        // High Roller Badge (10 ETH saved)
        if (stats.totalSaved >= 10 ether && !_hasBadge(_user, "High Roller")) {
            stats.badges.push("High Roller");
            emit BadgeEarned(_user, "High Roller");
        }
        
        // Vault Master Badge (5 vaults)
        if (stats.vaultCount >= 5 && !_hasBadge(_user, "Vault Master")) {
            stats.badges.push("Vault Master");
            emit BadgeEarned(_user, "Vault Master");
        }
    }
    
    function _hasBadge(address _user, string memory _badge) internal view returns (bool) {
        string[] memory badges = userStats[_user].badges;
        for (uint256 i = 0; i < badges.length; i++) {
            if (keccak256(bytes(badges[i])) == keccak256(bytes(_badge))) {
                return true;
            }
        }
        return false;
    }
    
    function _updateLeaderboards(address _user) internal {
        UserStats storage stats = userStats[_user];
        
        // Update total saved leaderboard
        _updateLeaderboard("totalSaved", _user, stats.totalSaved);
        
        // Update streak leaderboard
        _updateLeaderboard("streakDays", _user, stats.streakDays);
        
        // Update vault count leaderboard
        _updateLeaderboard("vaultCount", _user, stats.vaultCount);
        
        // Update referral leaderboard
        _updateLeaderboard("referrals", _user, stats.referralCount);
    }
    
    function _updateLeaderboard(string memory _category, address _user, uint256 _score) internal {
        LeaderboardEntry[] storage board = leaderboards[_category];
        
        // Find existing entry or add new one
        bool found = false;
        for (uint256 i = 0; i < board.length; i++) {
            if (board[i].user == _user) {
                board[i].score = _score;
                found = true;
                break;
            }
        }
        
        if (!found) {
            board.push(LeaderboardEntry({
                user: _user,
                score: _score,
                category: _category
            }));
        }
        
        // Sort leaderboard (simple bubble sort for small arrays)
        _sortLeaderboard(_category);
        
        emit LeaderboardUpdated(_category, _user, _score);
    }
    
    function _sortLeaderboard(string memory _category) internal {
        LeaderboardEntry[] storage board = leaderboards[_category];
        
        for (uint256 i = 0; i < board.length; i++) {
            for (uint256 j = i + 1; j < board.length; j++) {
                if (board[i].score < board[j].score) {
                    LeaderboardEntry memory temp = board[i];
                    board[i] = board[j];
                    board[j] = temp;
                }
            }
        }
    }
    
    function getTopUsers(string memory _category, uint256 _limit) 
        external 
        view 
        returns (LeaderboardEntry[] memory) 
    {
        LeaderboardEntry[] storage board = leaderboards[_category];
        uint256 length = board.length > _limit ? _limit : board.length;
        
        LeaderboardEntry[] memory result = new LeaderboardEntry[](length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = board[i];
        }
        
        return result;
    }
    
    function getUserBadges(address _user) external view returns (string[] memory) {
        return userStats[_user].badges;
    }
    
    function addReferral(address _user) external onlyOwner {
        userStats[_user].referralCount++;
        _updateLeaderboard("referrals", _user, userStats[_user].referralCount);
    }
}
