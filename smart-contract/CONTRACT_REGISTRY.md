# ContractRegistry Documentation

## Overview
The ContractRegistry contract serves as a central registry for all protocol contracts, providing comprehensive management and discovery capabilities.

## Core Features

### Contract Management
- **Registration**: Register new contracts with version and category
- **Updates**: Update existing contracts with new addresses/versions
- **Deactivation**: Safely deactivate contracts
- **Reactivation**: Reactivate previously deactivated contracts

### Query Functions
- **By Name**: Get contract by name
- **By Category**: Filter contracts by category
- **By Version**: Find contracts with specific versions
- **By Deployment Time**: Query contracts deployed in time ranges

### Administrative Features
- **Ownership Management**: Transfer or renounce ownership
- **Emergency Controls**: Emergency pause all contracts
- **Batch Operations**: Register multiple contracts at once

### Version Tracking
- Complete version history for each contract
- Latest version queries
- Version-based filtering

## Usage Examples

```solidity
// Register a contract
registry.registerContract("TimeVault", vaultAddress, "1.0.0", "vault");

// Get contract address
address vault = registry.getContract("TimeVault");

// Get contracts by category
string[] memory vaults = registry.getContractsByCategory("vault");

// Check if contract exists
bool exists = registry.hasContract("TimeVault");
```

## Security Features
- Owner-only administrative functions
- Input validation for all parameters
- Emergency pause functionality
- Comprehensive event logging
