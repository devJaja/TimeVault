// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ContractRegistry {
    struct ContractInfo {
        address contractAddress;
        string version;
        uint256 deployedAt;
        bool active;
    }
    
    mapping(string => ContractInfo) public contracts;
    mapping(address => bool) public isRegistered;
    string[] public contractNames;
    address public owner;
    
    event ContractRegistered(string indexed name, address indexed contractAddress, string version);
    event ContractUpdated(string indexed name, address indexed oldAddress, address indexed newAddress);
    event ContractDeactivated(string indexed name, address indexed contractAddress);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function registerContract(string memory name, address contractAddress, string memory version) external onlyOwner {
        require(contractAddress != address(0), "Invalid address");
        require(bytes(name).length > 0, "Name required");
        require(!contracts[name].active, "Contract already registered");
        
        contracts[name] = ContractInfo({
            contractAddress: contractAddress,
            version: version,
            deployedAt: block.timestamp,
            active: true
        });
        
        isRegistered[contractAddress] = true;
        contractNames.push(name);
        
        emit ContractRegistered(name, contractAddress, version);
    }
    
    function getContract(string memory name) external view returns (address) {
        require(contracts[name].active, "Contract not found");
        return contracts[name].contractAddress;
    }
    
    function updateContract(string memory name, address newAddress, string memory newVersion) external onlyOwner {
        require(contracts[name].active, "Contract not found");
        require(newAddress != address(0), "Invalid address");
        
        address oldAddress = contracts[name].contractAddress;
        isRegistered[oldAddress] = false;
        
        contracts[name].contractAddress = newAddress;
        contracts[name].version = newVersion;
        contracts[name].deployedAt = block.timestamp;
        
        isRegistered[newAddress] = true;
        
        emit ContractUpdated(name, oldAddress, newAddress);
    }
    
    function deactivateContract(string memory name) external onlyOwner {
        require(contracts[name].active, "Contract not found");
        
        contracts[name].active = false;
        isRegistered[contracts[name].contractAddress] = false;
        
        emit ContractDeactivated(name, contracts[name].contractAddress);
    }
    
    function getAllContracts() external view returns (string[] memory) {
        return contractNames;
    }
}
