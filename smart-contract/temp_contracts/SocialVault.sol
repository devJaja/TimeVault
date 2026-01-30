// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../lib/Errors.sol";

contract SocialVault is Ownable {

    struct WithdrawalRequest {
        address proposer;
        uint256 amount;
        string reason;
        mapping(address => bool) approvals; // Members who have approved this request
        uint256 approvedCount;             // Number of approvals
        bool executed;                     // True if the withdrawal has been executed
    }

    mapping(address => bool) public isMember;
    mapping(address => uint256) public contributions;
    address[] private _members; // To iterate over members if needed, otherwise use isMember mapping

    uint256 public totalVaultBalance;
    uint256 public memberCount;
    uint256 public nextWithdrawalRequestId;

    // Stores all withdrawal requests by their ID
    mapping(uint256 => WithdrawalRequest) public withdrawalRequests;

    // Events
    event MemberAdded(address indexed _member);
    event MemberRemoved(address indexed _member);
    event Deposited(address indexed _from, uint256 _amount);
    event WithdrawalProposed(uint256 indexed _requestId, address indexed _proposer, uint256 _amount, string _reason);
    event WithdrawalApproved(uint256 indexed _requestId, address indexed _approver);
    event WithdrawalExecuted(uint256 indexed _requestId, address indexed _to, uint256 _amount);
    event EmergencyWithdrawalExecuted(address indexed _to, uint256 _amount);


    // Modifiers
            modifier onlyMember() {
                if (!isMember[msg.sender]) revert SocialVault__CallerNotMember();
                _;
            }
            modifier onlyMemberAddress(address _addr) {
                if (!isMember[_addr]) revert SocialVault__CallerNotMember(); // Using same error for consistency
                _;
            }
    constructor() Ownable(msg.sender) {
        // Owner is automatically a member
        _addMember(msg.sender);
    }

    /**
     * @dev Adds a new member to the social vault. Only the owner can call this.
     * @param _newMember The address of the new member.
     */
    function addMember(address _newMember) public onlyOwner {
        if (_newMember == address(0)) revert SocialVault__ZeroAddress();
        if (isMember[_newMember]) revert SocialVault__AlreadyMember();
        _addMember(_newMember);
        emit MemberAdded(_newMember);
    }

    function _addMember(address _newMember) private {
        isMember[_newMember] = true;
        _members.push(_newMember);
        memberCount++;
    }

    /**
     * @dev Removes a member from the social vault. Only the owner can call this.
     *      Requires the member's contribution to be zero before removal.
     * @param _memberToRemove The address of the member to remove.
     */
    function removeMember(address _memberToRemove) public onlyOwner onlyMemberAddress(_memberToRemove) {
        if (_memberToRemove == owner()) revert SocialVault__CannotRemoveOwner();
        if (contributions[_memberToRemove] != 0) revert SocialVault__MemberHasFunds();

        isMember[_memberToRemove] = false;
        // Efficient way to remove from a dynamic array if order doesn't matter (move last element to current position)
        for (uint i = 0; i < _members.length; i++) {
            if (_members[i] == _memberToRemove) {
                _members[i] = _members[_members.length - 1];
                _members.pop();
                break;
            }
        }
        memberCount--;
        emit MemberRemoved(_memberToRemove);
    }

    /**
     * @dev Allows any member to deposit funds into the vault.
     */
    function deposit() public payable onlyMember {
        if (msg.value == 0) revert SocialVault__ZeroAmount();
        contributions[msg.sender] += msg.value;
        totalVaultBalance += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @dev Proposes a withdrawal of funds from the vault. Any member can propose.
     * @param _amount The amount of funds to withdraw.
     * @param _reason A description for the withdrawal.
     */
    function proposeWithdrawal(uint256 _amount, string memory _reason) public onlyMember {
        if (_amount == 0) revert SocialVault__ZeroAmount();
        if (_amount > totalVaultBalance) revert SocialVault__InsufficientVaultBalance();

        uint256 requestId = nextWithdrawalRequestId++;
        WithdrawalRequest storage newRequest = withdrawalRequests[requestId];
        newRequest.proposer = msg.sender;
        newRequest.amount = _amount;
        newRequest.reason = _reason;
        newRequest.executed = false;

        // Proposer automatically approves their own request
        _approveWithdrawal(requestId); // This will increment approvedCount and add to approvals mapping

        emit WithdrawalProposed(requestId, msg.sender, _amount, _reason);
    }

    /**
     * @dev Approves a proposed withdrawal. Any member can approve.
     * @param _requestId The ID of the withdrawal request to approve.
     */
    function approveWithdrawal(uint256 _requestId) public onlyMember {
        WithdrawalRequest storage request = withdrawalRequests[_requestId];
        if (request.proposer == address(0)) revert SocialVault__InvalidWithdrawalRequestID();
        if (request.executed) revert SocialVault__WithdrawalAlreadyExecuted();
        if (request.approvals[msg.sender]) revert SocialVault__AlreadyApprovedWithdrawal();

        _approveWithdrawal(_requestId);

        emit WithdrawalApproved(_requestId, msg.sender);
    }

    function _approveWithdrawal(uint256 _requestId) private {
        WithdrawalRequest storage request = withdrawalRequests[_requestId];
        request.approvals[msg.sender] = true;
        request.approvedCount++;
    }

    /**
     * @dev Executes a withdrawal request once a majority of members have approved it.
     *      Any member can call this to trigger execution.
     * @param _requestId The ID of the withdrawal request to execute.
     */
    function executeWithdrawal(uint256 _requestId) public onlyMember {
        WithdrawalRequest storage request = withdrawalRequests[_requestId];
        if (request.proposer == address(0)) revert SocialVault__InvalidWithdrawalRequestID();
        if (request.executed) revert SocialVault__WithdrawalAlreadyExecuted();
        if (request.approvedCount * 2 <= memberCount) revert SocialVault__NotEnoughApprovals();

        request.executed = true;
        totalVaultBalance -= request.amount;

        // Send funds to the proposer. Or should it be configurable?
        // For simplicity, let's send to proposer for now.
        // In a real scenario, the recipient should be part of the proposal.
        (bool success,) = request.proposer.call{value: request.amount}("");
        if (!success) revert SocialVault__EtherTransferFailed();

        emit WithdrawalExecuted(_requestId, request.proposer, request.amount);
    }

    /**
     * @dev Allows the owner to withdraw funds in an emergency.
     *      This bypasses the approval process. Use with extreme caution.
     * @param _amount The amount to withdraw.
     * @param _to The address to send the funds to.
     */
    function emergencyWithdraw(uint256 _amount, address _to) public onlyOwner {
        if (_amount == 0) revert SocialVault__ZeroAmount();
        if (_amount > totalVaultBalance) revert SocialVault__InsufficientVaultBalance();
        if (_to == address(0)) revert SocialVault__ZeroAddress();

        totalVaultBalance -= _amount;
        (bool success,) = _to.call{value: _amount}("");
        if (!success) revert SocialVault__EtherTransferFailed();

        emit EmergencyWithdrawalExecuted(_to, _amount);
    }

    // --- Getter Functions ---

    /**
     * @dev Returns the current contribution of a specific member.
     * @param _member The address of the member.
     * @return The amount contributed by the member.
     */
    function getMemberContribution(address _member) public view returns (uint256) {
        return contributions[_member];
    }

    /**
     * @dev Returns the total balance of the vault.
     * @return The total Ether held in the vault.
     */
    function getVaultBalance() public view returns (uint256) {
        return totalVaultBalance;
    }

    /**
     * @dev Returns the number of active members in the vault.
     * @return The count of members.
     */
    function getMemberCount() public view returns (uint256) {
        return memberCount;
    }

    /**
     * @dev Returns an array of all active member addresses.
     *      Note: This can be expensive for large number of members.
     * @return An array of member addresses.
     */
    function getMembers() public view returns (address[] memory) {
        return _members;
    }

    // Fallback function to receive Ether
    receive() external payable {
        deposit();
    }
}
