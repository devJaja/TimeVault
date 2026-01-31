// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SocialVault is Ownable {
    struct GroupVault {
        string name;
        address[] members;
        uint256 totalBalance;
        uint256 goalAmount;
        uint256 unlockTime;
        mapping(address => uint256) contributions;
        bool active;
    }
    
    struct Challenge {
        string name;
        uint256 targetAmount;
        uint256 duration;
        uint256 startTime;
        address[] participants;
        mapping(address => uint256) deposits;
        address winner;
        bool completed;
    }
    
    mapping(uint256 => GroupVault) public groupVaults;
    mapping(uint256 => Challenge) public challenges;
    uint256 public nextVaultId;
    uint256 public nextChallengeId;
    
    event GroupVaultCreated(uint256 indexed vaultId, string name, address[] members);
    event ChallengeCreated(uint256 indexed challengeId, string name, uint256 targetAmount);
    event ChallengeWinner(uint256 indexed challengeId, address winner, uint256 amount);
    
    constructor() Ownable(msg.sender) {}
    
    function createGroupVault(
        string memory _name,
        address[] memory _members,
        uint256 _goalAmount,
        uint256 _unlockTime
    ) external returns (uint256) {
        uint256 vaultId = nextVaultId++;
        
        GroupVault storage vault = groupVaults[vaultId];
        vault.name = _name;
        vault.members = _members;
        vault.goalAmount = _goalAmount;
        vault.unlockTime = _unlockTime;
        vault.active = true;
        
        emit GroupVaultCreated(vaultId, _name, _members);
        return vaultId;
    }
    
    function contributeToGroupVault(uint256 _vaultId) external payable {
        GroupVault storage vault = groupVaults[_vaultId];
        require(vault.active, "Vault not active");
        require(_isMember(_vaultId, msg.sender), "Not a member");
        
        vault.contributions[msg.sender] += msg.value;
        vault.totalBalance += msg.value;
    }
    
    function createChallenge(
        string memory _name,
        uint256 _targetAmount,
        uint256 _duration
    ) external returns (uint256) {
        uint256 challengeId = nextChallengeId++;
        
        Challenge storage challenge = challenges[challengeId];
        challenge.name = _name;
        challenge.targetAmount = _targetAmount;
        challenge.duration = _duration;
        challenge.startTime = block.timestamp;
        
        emit ChallengeCreated(challengeId, _name, _targetAmount);
        return challengeId;
    }
    
    function joinChallenge(uint256 _challengeId) external payable {
        Challenge storage challenge = challenges[_challengeId];
        require(!challenge.completed, "Challenge completed");
        require(block.timestamp < challenge.startTime + challenge.duration, "Challenge expired");
        
        if (challenge.deposits[msg.sender] == 0) {
            challenge.participants.push(msg.sender);
        }
        
        challenge.deposits[msg.sender] += msg.value;
        
        // Check if challenge is won
        if (challenge.deposits[msg.sender] >= challenge.targetAmount) {
            challenge.winner = msg.sender;
            challenge.completed = true;
            emit ChallengeWinner(_challengeId, msg.sender, challenge.deposits[msg.sender]);
        }
    }
    
    function _isMember(uint256 _vaultId, address _user) internal view returns (bool) {
        GroupVault storage vault = groupVaults[_vaultId];
        for (uint256 i = 0; i < vault.members.length; i++) {
            if (vault.members[i] == _user) {
                return true;
            }
        }
        return false;
    }
    
    function getGroupVaultMembers(uint256 _vaultId) external view returns (address[] memory) {
        return groupVaults[_vaultId].members;
    }
    
    function getChallengeParticipants(uint256 _challengeId) external view returns (address[] memory) {
        return challenges[_challengeId].participants;
    }
}
