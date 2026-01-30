# TimeVault Smart Contracts

## Overview
TimeVault is a comprehensive DeFi savings platform with advanced vault management features.

## Contracts

### Core Contracts
- **LeaderboardTracker.sol** - Tracks top savers and achievements
- **MultiSigVault.sol** - Multi-signature vault for secure withdrawals
- **VaultDelegation.sol** - Delegation system for vault management
- **ChainlinkPriceFeed.sol** - Price oracle integration
- **VaultPriceManager.sol** - USD value calculations

### Features
- Achievement system with milestone rewards
- Multi-signature security for large withdrawals
- Granular permission delegation
- Real-time price feeds via Chainlink
- Gas-optimized leaderboard system

## Deployment
Use Hardhat for compilation and deployment:
```bash
npx hardhat compile
npx hardhat deploy
```
