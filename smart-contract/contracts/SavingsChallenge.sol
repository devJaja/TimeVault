// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../lib/Errors.sol";

contract SavingsChallenge is Ownable {

    enum ChallengeStatus {
        Open,       // Challenge is active, people can join and save
        Ended,      // Deadline passed, waiting for resolution logic to be run
        Resolved,   // Rewards distributed, challenge finalized
        Canceled    // Challenge was canceled by creator
    }

    struct Participant {
        bool joined;
        uint256 contributedAmount; // How much they've saved towards *their* goal
        bool hasMetGoal;           // If individual goalAmount is met
        bool hasClaimedReward;
    }

    struct Challenge {
        address creator;
        string name;
        uint256 goalAmount;         // Individual goal for each participant
        uint256 participationFee;   // Amount to deposit to join, contributes to reward pool
        uint256 deadline;           // Timestamp when the challenge ends
        ChallengeStatus status;
        uint256 rewardPool;         // Total funds accumulated for winners (participation fees + forfeited amounts)
        mapping(address => Participant) participants;
        address[] participantAddresses; // To iterate over participants for resolution/cancellation
        uint256 winnerCount;        // Number of participants who met their goal
    }

    uint256 public nextChallengeId;
    mapping(uint256 => Challenge) public challenges;

    // Events
    event ChallengeCreated(uint256 indexed challengeId, address indexed creator, string name, uint256 goalAmount, uint256 participationFee, uint256 deadline);
    event ChallengeJoined(uint256 indexed challengeId, address indexed participant);
    event ContributionMade(uint256 indexed challengeId, address indexed participant, uint256 amount, uint256 currentContribution);
    event ChallengeResolved(uint256 indexed challengeId, uint256 totalRewardPool, uint256 winnerCount);
    event RewardClaimed(uint256 indexed challengeId, address indexed winner, uint256 amount);
    event ChallengeCanceled(uint256 indexed challengeId, address indexed canceller);

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Creates a new savings challenge.
     * @param _name A unique name for the challenge.
     * @param _goalAmount The individual savings goal for each participant in wei.
     * @param _participationFee The fee required to join the challenge in wei. This contributes to the reward pool.
     * @param _duration The duration of the challenge in seconds.
     */
    function createChallenge(
        string memory _name,
        uint256 _goalAmount,
        uint256 _participationFee,
        uint256 _duration
    ) public {
        if (bytes(_name).length == 0) revert SavingsChallenge__EmptyName();
        if (_goalAmount == 0) revert SavingsChallenge__ZeroGoalAmount();
        if (_participationFee == 0) revert SavingsChallenge__ZeroParticipationFee();
        if (_duration == 0) revert SavingsChallenge__ZeroDuration();
        if (block.timestamp + _duration <= block.timestamp) revert SavingsChallenge__DeadlineOverflow(); // Check for overflow

        uint256 challengeId = nextChallengeId++;
        challenges[challengeId].creator = msg.sender;
        challenges[challengeId].name = _name;
        challenges[challengeId].goalAmount = _goalAmount;
        challenges[challengeId].participationFee = _participationFee;
        challenges[challengeId].deadline = block.timestamp + _duration;
        challenges[challengeId].status = ChallengeStatus.Open;

        emit ChallengeCreated(challengeId, msg.sender, _name, _goalAmount, _participationFee, challenges[challengeId].deadline);
    }

    /**
     * @dev Allows a user to join an open challenge by paying the participation fee.
     * @param _challengeId The ID of the challenge to join.
     */
    function joinChallenge(uint256 _challengeId) public payable {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.creator == address(0)) revert SavingsChallenge__ChallengeDoesNotExist();
        if (challenge.status != ChallengeStatus.Open) revert SavingsChallenge__ChallengeNotOpen();
        if (block.timestamp >= challenge.deadline) revert SavingsChallenge__JoiningDeadlinePassed();
        if (challenge.participants[msg.sender].joined) revert SavingsChallenge__AlreadyJoinedChallenge();
        if (msg.value != challenge.participationFee) revert SavingsChallenge__IncorrectParticipationFee();

        challenge.participants[msg.sender].joined = true;
        challenge.participantAddresses.push(msg.sender);
        challenge.rewardPool += msg.value;

        emit ChallengeJoined(_challengeId, msg.sender);
    }

    /**
     * @dev Allows a participant to contribute funds towards their individual goal.
     * @param _challengeId The ID of the challenge.
     */
    function contributeToChallenge(uint256 _challengeId) public payable {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.creator == address(0)) revert SavingsChallenge__ChallengeDoesNotExist();
        if (challenge.status != ChallengeStatus.Open) revert SavingsChallenge__ChallengeNotOpen();
        if (block.timestamp >= challenge.deadline) revert SavingsChallenge__ContributionDeadlinePassed();
        if (!challenge.participants[msg.sender].joined) revert SavingsChallenge__NotParticipant();
        if (msg.value == 0) revert SavingsChallenge__ZeroContributionAmount();

        Participant storage participant = challenge.participants[msg.sender];
        participant.contributedAmount += msg.value;

        // Check if participant met their goal
        if (participant.contributedAmount >= challenge.goalAmount && !participant.hasMetGoal) {
            participant.hasMetGoal = true;
            challenge.winnerCount++;
        }

        emit ContributionMade(_challengeId, msg.sender, msg.value, participant.contributedAmount);
    }

    /**
     * @dev Resolves the challenge after its deadline. Determines winners and finalizes the reward pool.
     *      Anyone can call this function after the deadline.
     * @param _challengeId The ID of the challenge to resolve.
     */
                    function resolveChallenge(uint256 _challengeId) public {
                        Challenge storage challenge = challenges[_challengeId];
                        if (challenge.creator == address(0)) revert SavingsChallenge__ChallengeDoesNotExist();
                        if (challenge.status != ChallengeStatus.Open) revert SavingsChallenge__ChallengeNotOpen();
                        if (block.timestamp < challenge.deadline) revert SavingsChallenge__ChallengeNotEnded();
                        
                        challenge.status = ChallengeStatus.Ended; // Intermediate status before resolved
                
                        uint256 totalForfeitedContributions = 0;
                        for (uint i = 0; i < challenge.participantAddresses.length; i++) {
                            address participantAddress = challenge.participantAddresses[i];
                            Participant storage participant = challenge.participants[participantAddress];
                
                            if (participant.joined && !participant.hasMetGoal) {
                                // Participant failed to meet goal, their contributions are forfeited to the reward pool
                                totalForfeitedContributions += participant.contributedAmount;
                            }
                        }
                        challenge.rewardPool += totalForfeitedContributions;
                
                        if (challenge.winnerCount == 0) {
                            // No winners, return reward pool to owner
                            (bool success, ) = owner().call{value: challenge.rewardPool}("");
                            if (!success) revert SavingsChallenge__EtherTransferFailed();
                            challenge.rewardPool = 0; // Clear pool after transfer
                        }
                        
                        challenge.status = ChallengeStatus.Resolved;
                        emit ChallengeResolved(_challengeId, challenge.rewardPool, challenge.winnerCount);
                    }
                    
                            /**
     * @dev Allows a winner to claim their reward after the challenge has been resolved.
     * @param _challengeId The ID of the challenge.
     */
    function claimReward(uint256 _challengeId) public {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.creator == address(0)) revert SavingsChallenge__ChallengeDoesNotExist();
        if (challenge.status != ChallengeStatus.Resolved) revert SavingsChallenge__ChallengeNotResolved();

        Participant storage participant = challenge.participants[msg.sender];
        if (!participant.joined) revert SavingsChallenge__NotParticipant();
        if (!participant.hasMetGoal) revert SavingsChallenge__ParticipantDidNotMeetGoal();
        if (participant.hasClaimedReward) revert SavingsChallenge__RewardAlreadyClaimed();
        if (challenge.winnerCount == 0) revert SavingsChallenge__NoWinners();

        uint256 rewardAmount = challenge.rewardPool / challenge.winnerCount;
        participant.hasClaimedReward = true;

        (bool success, ) = msg.sender.call{value: rewardAmount}("");
        if (!success) revert SavingsChallenge__EtherTransferFailed();

        emit RewardClaimed(_challengeId, msg.sender, rewardAmount);
    }                                /**
     * @dev Allows the challenge creator to cancel an open challenge before its deadline.
     *      Participation fees are refunded. Contributions are refunded.
     * @param _challengeId The ID of the challenge to cancel.
     */
                function cancelChallenge(uint256 _challengeId) public {
                    Challenge storage challenge = challenges[_challengeId];
                    if (challenge.creator == address(0)) revert SavingsChallenge__ChallengeDoesNotExist();
                    if (msg.sender != challenge.creator) revert SavingsChallenge__OnlyCreatorCanCancel();
                    if (challenge.status != ChallengeStatus.Open) revert SavingsChallenge__ChallengeNotOpen();
                    if (block.timestamp >= challenge.deadline) revert SavingsChallenge__CannotCancelAfterDeadline();
            
                    challenge.status = ChallengeStatus.Canceled;
            
                    for (uint i = 0; i < challenge.participantAddresses.length; i++) {
                        address participantAddress = challenge.participantAddresses[i];
                        Participant storage participant = challenge.participants[participantAddress];
            
                        if (participant.joined) {
                            uint256 refundAmount = challenge.participationFee + participant.contributedAmount;
                            if (refundAmount > 0) {
                                (bool success, ) = participantAddress.call{value: refundAmount}("");
                                if (!success) revert SavingsChallenge__EtherTransferFailed();
                            }
                        }
                    }
                    challenge.rewardPool = 0; // All funds refunded
                    emit ChallengeCanceled(_challengeId, msg.sender);
                }
                
                // --- Getter Functions ---

    /**
     * @dev Returns details of a specific challenge.
     * @param _challengeId The ID of the challenge.
     * @return creator, name, goalAmount, participationFee, deadline, status, rewardPool, participantCount, winnerCount.
     */
    function getChallengeDetails(uint256 _challengeId)
        public view
        returns (
            address creator,
            string memory name,
            uint256 goalAmount,
            uint256 participationFee,
            uint256 deadline,
            ChallengeStatus status,
            uint256 rewardPool,
            uint256 currentParticipantCount, // Renamed to avoid collision with struct member
            uint256 winnerCount
        )
    {
        Challenge storage challenge = challenges[_challengeId];
        return (
            challenge.creator,
            challenge.name,
            challenge.goalAmount,
            challenge.participationFee,
            challenge.deadline,
            challenge.status,
            challenge.rewardPool,
            challenge.participantAddresses.length, // Using array length for current count
            challenge.winnerCount
        );
    }

    /**
     * @dev Returns the progress of a specific participant in a challenge.
     * @param _challengeId The ID of the challenge.
     * @param _participant The address of the participant.
     * @return joined, contributedAmount, hasMetGoal, hasClaimedReward.
     */
    function getParticipantProgress(uint256 _challengeId, address _participant)
        public view
        returns (
            bool joined,
            uint256 contributedAmount,
            bool hasMetGoal,
            bool hasClaimedReward
        )
    {
        Challenge storage challenge = challenges[_challengeId];
        Participant storage participant = challenge.participants[_participant];
        return (
            participant.joined,
            participant.contributedAmount,
            participant.hasMetGoal,
            participant.hasClaimedReward
        );
    }

    /**
     * @dev Returns the list of all participant addresses for a given challenge.
     * @param _challengeId The ID of the challenge.
     * @return An array of participant addresses.
     */
    function getParticipantAddresses(uint256 _challengeId) public view returns (address[] memory) {
        Challenge storage challenge = challenges[_challengeId];
        return challenge.participantAddresses;
    }
}