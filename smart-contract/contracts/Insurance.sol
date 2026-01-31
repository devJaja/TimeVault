// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./lib/Events.sol";
import "./lib/Errors.sol";

contract Insurance {
    struct Policy {
        uint256 id;
        address holder;
        uint256 coverage;
        uint256 premium;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        bool claimed;
    }
    
    struct Claim {
        uint256 policyId;
        address claimant;
        uint256 amount;
        string reason;
        bool approved;
        uint256 timestamp;
    }
    
    mapping(uint256 => Policy) public policies;
    mapping(uint256 => Claim) public claims;
    mapping(address => uint256[]) public userPolicies;
    uint256 public policyCounter;
    uint256 public claimCounter;
    uint256 public totalPool;
    address public admin;
    
    modifier onlyAdmin() {
        if (msg.sender != admin) revert TimeVault__NotOwner();
        _;
    }
    
    constructor() {
        admin = msg.sender;
    }
    
    function buyInsurance(uint256 _coverage, uint256 _duration) external payable {
        uint256 premium = (_coverage * 5) / 100; // 5% of coverage as premium
        if (msg.value < premium) revert TimeVault__InsufficientFunds();
        
        policyCounter++;
        policies[policyCounter] = Policy({
            id: policyCounter,
            holder: msg.sender,
            coverage: _coverage,
            premium: premium,
            startTime: block.timestamp,
            endTime: block.timestamp + _duration,
            isActive: true,
            claimed: false
        });
        
        userPolicies[msg.sender].push(policyCounter);
        totalPool += premium;
        
        emit InsurancePurchased(policyCounter, msg.sender, _coverage);
    }
    
    function fileClaim(uint256 _policyId, uint256 _amount, string memory _reason) external {
        Policy storage policy = policies[_policyId];
        if (policy.holder != msg.sender) revert TimeVault__NotOwner();
        if (!policy.isActive || policy.claimed) revert TimeVault__InvalidState();
        if (_amount > policy.coverage) revert TimeVault__ExceedsCoverage();
        
        claimCounter++;
        claims[claimCounter] = Claim({
            policyId: _policyId,
            claimant: msg.sender,
            amount: _amount,
            reason: _reason,
            approved: false,
            timestamp: block.timestamp
        });
        
        emit ClaimFiled(claimCounter, _policyId, msg.sender, _amount);
    }
    
    function approveClaim(uint256 _claimId) external onlyAdmin {
        Claim storage claim = claims[_claimId];
        Policy storage policy = policies[claim.policyId];
        
        if (claim.approved) revert TimeVault__AlreadyApproved();
        if (totalPool < claim.amount) revert TimeVault__InsufficientFunds();
        
        claim.approved = true;
        policy.claimed = true;
        totalPool -= claim.amount;
        
        payable(claim.claimant).transfer(claim.amount);
        emit ClaimApproved(_claimId, claim.amount);
    }
}
