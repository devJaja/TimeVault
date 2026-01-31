// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./lib/Events.sol";
import "./lib/Errors.sol";

contract Dispute {
    enum DisputeStatus { Open, InReview, Resolved, Rejected }
    
    struct DisputeCase {
        uint256 id;
        address complainant;
        address respondent;
        string description;
        uint256 amount;
        DisputeStatus status;
        uint256 createdAt;
        uint256 resolvedAt;
        address resolver;
    }
    
    mapping(uint256 => DisputeCase) public disputes;
    mapping(address => uint256[]) public userDisputes;
    uint256 public disputeCounter;
    address public admin;
    
    modifier onlyAdmin() {
        if (msg.sender != admin) revert TimeVault__NotOwner();
        _;
    }
    
    constructor() {
        admin = msg.sender;
    }
    
    function createDispute(address _respondent, string memory _description, uint256 _amount) external {
        disputeCounter++;
        
        disputes[disputeCounter] = DisputeCase({
            id: disputeCounter,
            complainant: msg.sender,
            respondent: _respondent,
            description: _description,
            amount: _amount,
            status: DisputeStatus.Open,
            createdAt: block.timestamp,
            resolvedAt: 0,
            resolver: address(0)
        });
        
        userDisputes[msg.sender].push(disputeCounter);
        userDisputes[_respondent].push(disputeCounter);
        
        emit DisputeCreated(disputeCounter, msg.sender, _respondent);
    }
    
    function resolveDispute(uint256 _disputeId, bool _inFavorOfComplainant) external onlyAdmin {
        DisputeCase storage dispute = disputes[_disputeId];
        if (dispute.status != DisputeStatus.Open) revert TimeVault__InvalidState();
        
        dispute.status = _inFavorOfComplainant ? DisputeStatus.Resolved : DisputeStatus.Rejected;
        dispute.resolvedAt = block.timestamp;
        dispute.resolver = msg.sender;
        
        emit DisputeResolved(_disputeId, _inFavorOfComplainant);
    }
}
