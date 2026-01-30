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
    mapping(string => string[]) public contractVersionHistory;
    mapping(string => string) public contractCategories;
    string[] public contractNames;
    address public owner;
    
    event ContractRegistered(string indexed name, address indexed contractAddress, string version);
    event ContractUpdated(string indexed name, address indexed oldAddress, address indexed newAddress);
    event ContractDeactivated(string indexed name, address indexed contractAddress);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event CategoryUpdated(string indexed name, string oldCategory, string newCategory);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function registerContract(string memory name, address contractAddress, string memory version, string memory category) external onlyOwner {
        require(contractAddress != address(0), "Invalid address");
        require(bytes(name).length > 0, "Name required");
        require(bytes(name).length <= 32, "Name too long");
        require(bytes(version).length > 0, "Version required");
        require(bytes(version).length <= 16, "Version too long");
        require(bytes(category).length <= 16, "Category too long");
        require(!contracts[name].active, "Contract already registered");
        
        contracts[name] = ContractInfo({
            contractAddress: contractAddress,
            version: version,
            deployedAt: block.timestamp,
            active: true
        });
        
        isRegistered[contractAddress] = true;
        contractNames.push(name);
        contractVersionHistory[name].push(version);
        contractCategories[name] = category;
        
        emit ContractRegistered(name, contractAddress, version);
    }
    
    function getContract(string memory name) external view returns (address) {
        require(contracts[name].active, "Contract not found");
        return contracts[name].contractAddress;
    }
    
    function updateContract(string memory name, address newAddress, string memory newVersion) external onlyOwner {
        require(contracts[name].active, "Contract not found");
        require(newAddress != address(0), "Invalid address");
        require(bytes(newVersion).length > 0, "Version required");
        require(bytes(newVersion).length <= 16, "Version too long");
        
        address oldAddress = contracts[name].contractAddress;
        isRegistered[oldAddress] = false;
        
        contracts[name].contractAddress = newAddress;
        contracts[name].version = newVersion;
        contracts[name].deployedAt = block.timestamp;
        
        isRegistered[newAddress] = true;
        contractVersionHistory[name].push(newVersion);
        
        emit ContractUpdated(name, oldAddress, newAddress);
    }
    
    function deactivateContract(string memory name) external onlyOwner {
        require(contracts[name].active, "Contract not found");
        
        contracts[name].active = false;
        isRegistered[contracts[name].contractAddress] = false;
        
        emit ContractDeactivated(name, contracts[name].contractAddress);
    }
    
    function getContractInfo(string memory name) external view returns (address, string memory, uint256, bool) {
        ContractInfo memory info = contracts[name];
        return (info.contractAddress, info.version, info.deployedAt, info.active);
    }
    
    function getVersionHistory(string memory name) external view returns (string[] memory) {
        return contractVersionHistory[name];
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner");
        require(newOwner != owner, "Same owner");
        
        address previousOwner = owner;
        owner = newOwner;
        
        emit OwnershipTransferred(previousOwner, newOwner);
    }
    
    function getActiveContracts() external view returns (string[] memory) {
        uint256 activeCount = 0;
        
        for (uint256 i = 0; i < contractNames.length; i++) {
            if (contracts[contractNames[i]].active) {
                activeCount++;
            }
        }
        
        string[] memory activeContracts = new string[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < contractNames.length; i++) {
            if (contracts[contractNames[i]].active) {
                activeContracts[index] = contractNames[i];
                index++;
            }
        }
        
        return activeContracts;
    }
    
    function isContractActive(string memory name) external view returns (bool) {
        return contracts[name].active;
    }
    
    function getContractCount() external view returns (uint256 total, uint256 active) {
        total = contractNames.length;
        active = 0;
        
        for (uint256 i = 0; i < contractNames.length; i++) {
            if (contracts[contractNames[i]].active) {
                active++;
            }
        }
    }
    
    function reactivateContract(string memory name) external onlyOwner {
        require(bytes(name).length > 0, "Name required");
        require(contracts[name].contractAddress != address(0), "Contract never registered");
        require(!contracts[name].active, "Contract already active");
        
        contracts[name].active = true;
        isRegistered[contracts[name].contractAddress] = true;
        
        emit ContractRegistered(name, contracts[name].contractAddress, contracts[name].version);
    }
    
    function getContractsByCategory(string memory category) external view returns (string[] memory) {
        uint256 count = 0;
        
        for (uint256 i = 0; i < contractNames.length; i++) {
            if (keccak256(bytes(contractCategories[contractNames[i]])) == keccak256(bytes(category)) && 
                contracts[contractNames[i]].active) {
                count++;
            }
        }
        
        string[] memory categoryContracts = new string[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < contractNames.length; i++) {
            if (keccak256(bytes(contractCategories[contractNames[i]])) == keccak256(bytes(category)) && 
                contracts[contractNames[i]].active) {
                categoryContracts[index] = contractNames[i];
                index++;
            }
        }
        
        return categoryContracts;
    }
    
    function setContractCategory(string memory name, string memory category) external onlyOwner {
        require(contracts[name].contractAddress != address(0), "Contract not found");
        string memory oldCategory = contractCategories[name];
        contractCategories[name] = category;
        emit CategoryUpdated(name, oldCategory, category);
    }
    
    function getContractCategory(string memory name) external view returns (string memory) {
        return contractCategories[name];
    }
    
    function batchRegisterContracts(
        string[] memory names,
        address[] memory addresses,
        string[] memory versions,
        string[] memory categories
    ) external onlyOwner {
        require(names.length == addresses.length, "Array length mismatch");
        require(names.length == versions.length, "Array length mismatch");
        require(names.length == categories.length, "Array length mismatch");
        require(names.length <= 10, "Too many contracts");
        
        for (uint256 i = 0; i < names.length; i++) {
            this.registerContract(names[i], addresses[i], versions[i], categories[i]);
        }
    }
    
    function getContractsByVersion(string memory version) external view returns (string[] memory) {
        uint256 count = 0;
        
        for (uint256 i = 0; i < contractNames.length; i++) {
            if (keccak256(bytes(contracts[contractNames[i]].version)) == keccak256(bytes(version)) && 
                contracts[contractNames[i]].active) {
                count++;
            }
        }
        
        string[] memory versionContracts = new string[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < contractNames.length; i++) {
            if (keccak256(bytes(contracts[contractNames[i]].version)) == keccak256(bytes(version)) && 
                contracts[contractNames[i]].active) {
                versionContracts[index] = contractNames[i];
                index++;
            }
        }
        
        return versionContracts;
    }
    
    function getContractsByDeploymentTime(uint256 startTime, uint256 endTime) external view returns (string[] memory) {
        require(startTime <= endTime, "Invalid time range");
        uint256 count = 0;
        
        for (uint256 i = 0; i < contractNames.length; i++) {
            uint256 deployTime = contracts[contractNames[i]].deployedAt;
            if (deployTime >= startTime && deployTime <= endTime && contracts[contractNames[i]].active) {
                count++;
            }
        }
        
        string[] memory timeContracts = new string[](count);
        uint256 index = 0;
        
        for (uint256 i = 0; i < contractNames.length; i++) {
            uint256 deployTime = contracts[contractNames[i]].deployedAt;
            if (deployTime >= startTime && deployTime <= endTime && contracts[contractNames[i]].active) {
                timeContracts[index] = contractNames[i];
                index++;
            }
        }
        
        return timeContracts;
    }
    
    function emergencyPause() external onlyOwner {
        // Deactivate all contracts in emergency
        for (uint256 i = 0; i < contractNames.length; i++) {
            if (contracts[contractNames[i]].active) {
                contracts[contractNames[i]].active = false;
                isRegistered[contracts[contractNames[i]].contractAddress] = false;
                emit ContractDeactivated(contractNames[i], contracts[contractNames[i]].contractAddress);
            }
        }
    }
    
    function getLatestVersion(string memory name) external view returns (string memory) {
        string[] memory versions = contractVersionHistory[name];
        require(versions.length > 0, "No versions found");
        return versions[versions.length - 1];
    }
    
    function hasContract(string memory name) external view returns (bool) {
        return contracts[name].contractAddress != address(0);
    }
    
    function getContractAddress(string memory name) external view returns (address) {
        return contracts[name].contractAddress;
    }
    
    function renounceOwnership() external onlyOwner {
        address previousOwner = owner;
        owner = address(0);
        emit OwnershipTransferred(previousOwner, address(0));
    }
    
    function getContractVersion(string memory name) external view returns (string memory) {
        return contracts[name].version;
    }
    
    function getContractDeploymentTime(string memory name) external view returns (uint256) {
        return contracts[name].deployedAt;
    }
    
    function isAddressRegistered(address contractAddress) external view returns (bool) {
        return isRegistered[contractAddress];
    }
    
    function getRegistryStats() external view returns (
        uint256 totalContracts,
        uint256 activeContracts,
        uint256 totalVersions
    ) {
        totalContracts = contractNames.length;
        activeContracts = 0;
        totalVersions = 0;
        
        for (uint256 i = 0; i < contractNames.length; i++) {
            if (contracts[contractNames[i]].active) {
                activeContracts++;
            }
            totalVersions += contractVersionHistory[contractNames[i]].length;
        }
    }
    
    function getAllContracts() external view returns (string[] memory) {
        return contractNames;
    }
}
