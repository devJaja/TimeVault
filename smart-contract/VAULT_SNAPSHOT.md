# VaultSnapshot Contract

## Overview
The VaultSnapshot contract provides comprehensive historical balance tracking for vault users with advanced analytics capabilities.

## Features

### Core Functionality
- **Automatic Snapshot Management**: Configurable intervals and limits
- **Historical Balance Queries**: Point-in-time balance lookups
- **Time Range Analysis**: Query snapshots within specific periods
- **Growth Rate Calculations**: Track balance growth over time

### Analytics Functions
- `getBalanceAtTime()` - Get balance at specific timestamp
- `getGrowthRate()` - Calculate growth rate over period
- `getAverageBalance()` - Average balance over time period
- `getMaxBalance()` - Peak balance in time period
- `getMinBalance()` - Lowest balance in time period

### Configuration
- Minimum snapshot interval: 15 minutes
- Default maximum snapshots: 500 per user
- Automatic oldest snapshot removal when limit reached

## Usage
```solidity
// Take a snapshot
vaultSnapshot.takeSnapshot(userAddress, currentBalance);

// Get balance 30 days ago
uint256 oldBalance = vaultSnapshot.getBalanceAtTime(user, block.timestamp - 30 days);

// Calculate 7-day growth rate
int256 growth = vaultSnapshot.getGrowthRate(user, 7);
```
