// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./lib/Events.sol";
import "./lib/Errors.sol";

contract Governance {
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 endTime;
        bool executed;
        mapping(address => bool) hasVoted;
    }
    
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public votingPower;
    uint256 public proposalCounter;
    uint256 public constant VOTING_PERIOD = 7 days;
    uint256 public constant MIN_VOTING_POWER = 1000;
    
    function setVotingPower(address _user, uint256 _power) external {
        votingPower[_user] = _power;
    }
    
    function createProposal(string memory _description) external {
        if (votingPower[msg.sender] < MIN_VOTING_POWER) revert TimeVault__InsufficientFunds();
        
        proposalCounter++;
        Proposal storage proposal = proposals[proposalCounter];
        proposal.id = proposalCounter;
        proposal.proposer = msg.sender;
        proposal.description = _description;
        proposal.endTime = block.timestamp + VOTING_PERIOD;
        
        emit ProposalCreated(proposalCounter, msg.sender);
    }
    
    function vote(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        if (block.timestamp > proposal.endTime) revert TimeVault__VotingEnded();
        if (proposal.hasVoted[msg.sender]) revert TimeVault__AlreadyVoted();
        
        proposal.hasVoted[msg.sender] = true;
        
        if (_support) {
            proposal.votesFor += votingPower[msg.sender];
        } else {
            proposal.votesAgainst += votingPower[msg.sender];
        }
        
        emit VoteCast(_proposalId, msg.sender, _support);
    }
    
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        if (block.timestamp <= proposal.endTime) revert TimeVault__VotingActive();
        if (proposal.executed) revert TimeVault__AlreadyExecuted();
        if (proposal.votesFor <= proposal.votesAgainst) revert TimeVault__ProposalRejected();
        
        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }
}
