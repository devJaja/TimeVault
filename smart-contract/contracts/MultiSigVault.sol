// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigVault {
    struct Transaction {
        address to;
        uint256 amount;
        bytes data;
        bool executed;
        uint256 confirmations;
    }
    
    address[] public owners;
    mapping(address => bool) public isOwner;
    mapping(uint256 => mapping(address => bool)) public confirmations;
    Transaction[] public transactions;
    
    uint256 public required;
    
    event Deposit(address indexed sender, uint256 amount);
    event TransactionSubmitted(uint256 indexed txId, address indexed to, uint256 amount);
    event TransactionConfirmed(uint256 indexed txId, address indexed owner);
    event TransactionExecuted(uint256 indexed txId);
    
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not owner");
        _;
    }
    
    modifier txExists(uint256 txId) {
        require(txId < transactions.length, "Transaction does not exist");
        _;
    }
    
    modifier notExecuted(uint256 txId) {
        require(!transactions[txId].executed, "Transaction already executed");
        _;
    }
    
    modifier notConfirmed(uint256 txId) {
        require(!confirmations[txId][msg.sender], "Transaction already confirmed");
        _;
    }
    
    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "Owners required");
        require(_required > 0 && _required <= _owners.length, "Invalid required number");
        
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Owner not unique");
            
            isOwner[owner] = true;
            owners.push(owner);
        }
        
        required = _required;
    }
    
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }
    
    function submitTransaction(address to, uint256 amount, bytes memory data) 
        external 
        onlyOwner 
        returns (uint256) 
    {
        uint256 txId = transactions.length;
        
        transactions.push(Transaction({
            to: to,
            amount: amount,
            data: data,
            executed: false,
            confirmations: 0
        }));
        
        emit TransactionSubmitted(txId, to, amount);
        return txId;
    }
    
    function confirmTransaction(uint256 txId) 
        external 
        onlyOwner 
        txExists(txId) 
        notExecuted(txId) 
        notConfirmed(txId) 
    {
        confirmations[txId][msg.sender] = true;
        transactions[txId].confirmations++;
        
        emit TransactionConfirmed(txId, msg.sender);
        
        if (transactions[txId].confirmations >= required) {
            executeTransaction(txId);
        }
    }
    
    function executeTransaction(uint256 txId) 
        public 
        txExists(txId) 
        notExecuted(txId) 
    {
        Transaction storage transaction = transactions[txId];
        require(transaction.confirmations >= required, "Not enough confirmations");
        
        transaction.executed = true;
        
        (bool success, ) = transaction.to.call{value: transaction.amount}(transaction.data);
        require(success, "Transaction failed");
        
        emit TransactionExecuted(txId);
    }
    
    function revokeConfirmation(uint256 txId) 
        external 
        onlyOwner 
        txExists(txId) 
        notExecuted(txId) 
    {
        require(confirmations[txId][msg.sender], "Transaction not confirmed");
        
        confirmations[txId][msg.sender] = false;
        transactions[txId].confirmations--;
    }
    
    function getOwners() external view returns (address[] memory) {
        return owners;
    }
    
    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }
    
    function getTransaction(uint256 txId) 
        external 
        view 
        returns (address to, uint256 amount, bytes memory data, bool executed, uint256 confirmationCount) 
    {
        Transaction storage transaction = transactions[txId];
        return (
            transaction.to,
            transaction.amount,
            transaction.data,
            transaction.executed,
            transaction.confirmations
        );
    }
}
