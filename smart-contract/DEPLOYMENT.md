# TimeVault Smart Contracts Deployment Guide

This guide covers the deployment of TimeVault smart contracts to Base Sepolia testnet.

## Contracts Overview

### VaultFactory.sol
- Factory contract for creating new TimeVault instances
- Manages protocol fees and vault registry
- Tracks all created vaults and user-specific vaults

### TimeVault.sol
- Individual vault contract for time-locked savings
- Supports goal-based and time-based unlocking
- Emergency withdrawal functionality with penalties

## Prerequisites

1. **Node.js** (v18 or higher)
2. **Base Sepolia testnet ETH** for deployment
3. **Environment variables** configured

## Environment Setup

Create a `.env` file in the project root:

```bash
# Base Sepolia Configuration
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
BASE_SEPOLIA_PRIVATE_KEY=your_private_key_here

# Optional: Sepolia for testing
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/your_project_id
SEPOLIA_PRIVATE_KEY=your_private_key_here
```

## Installation

```bash
npm install
```

## Compilation

```bash
npx hardhat compile
```

## Testing

Run all tests:
```bash
npm run test
# or
npx tsx scripts/test.ts
```

Run specific test files:
```bash
npx hardhat test test/VaultFactory.test.ts
npx hardhat test test/TimeVault.test.ts
```

## Deployment

### Option 1: Using the deployment script

Deploy only VaultFactory:
```bash
npx tsx scripts/deploy.ts --network baseSepolia
```

Deploy VaultFactory with a demo TimeVault:
```bash
npx tsx scripts/deploy.ts --network baseSepolia --deploy-demo true --demo-owner 0xYourAddressHere
```

Custom demo vault parameters:
```bash
npx tsx scripts/deploy.ts \
  --network baseSepolia \
  --deploy-demo true \
  --demo-owner 0xYourAddressHere \
  --demo-name "My Custom Vault" \
  --demo-unlock-time 1735689600 \
  --demo-goal-amount "2000000000000000000"
```

### Option 2: Using Hardhat Ignition directly

Deploy VaultFactory:
```bash
npx hardhat ignition deploy ignition/modules/VaultFactory.ts --network baseSepolia
```

Deploy TimeVault (requires parameters):
```bash
npx hardhat ignition deploy ignition/modules/TimeVault.ts --network baseSepolia --parameters '{
  "name": "My Savings Vault",
  "unlockTime": 1735689600,
  "goalAmount": "1000000000000000000",
  "owner": "0xYourAddressHere",
  "protocolFee": 50
}'
```

## Network Configuration

The project is configured for the following networks:

- **baseSepolia**: Base Sepolia testnet (Chain ID: 84532)
- **sepolia**: Ethereum Sepolia testnet
- **hardhatMainnet**: Local Hardhat network (L1 simulation)
- **hardhatOp**: Local Hardhat network (Optimism simulation)

## Contract Verification

After deployment, verify contracts on Basescan:

```bash
npx hardhat verify --network baseSepolia DEPLOYED_CONTRACT_ADDRESS
```

For TimeVault verification with constructor arguments:
```bash
npx hardhat verify --network baseSepolia DEPLOYED_CONTRACT_ADDRESS "Vault Name" 1735689600 "1000000000000000000" "0xOwnerAddress" 50
```

## Usage Examples

### Creating a Vault via VaultFactory

```solidity
// Connect to deployed VaultFactory
VaultFactory factory = VaultFactory(FACTORY_ADDRESS);

// Create a new vault
address newVault = factory.createVault(
    "My Savings Goal",           // name
    block.timestamp + 86400 * 30, // unlock in 30 days
    1 ether                      // goal amount
);
```

### Interacting with TimeVault

```solidity
// Connect to vault
TimeVault vault = TimeVault(VAULT_ADDRESS);

// Deposit funds
vault.deposit{value: 0.5 ether}();

// Check vault info
(
    string memory name,
    uint256 unlockTime,
    uint256 goalAmount,
    address owner,
    uint256 balance,
    bool goalReached,
    bool emergencyEnabled
) = vault.getVaultInfo();

// Withdraw (after unlock time or goal reached)
vault.withdraw(0.3 ether);

// Emergency withdrawal (if enabled)
vault.enableEmergencyWithdrawal();
vault.emergencyWithdraw();
```

## Gas Estimates

Approximate gas costs on Base Sepolia:

- **VaultFactory deployment**: ~800,000 gas
- **TimeVault deployment**: ~600,000 gas
- **Create vault**: ~400,000 gas
- **Deposit**: ~50,000 gas
- **Withdraw**: ~30,000 gas
- **Emergency withdraw**: ~40,000 gas

## Security Considerations

1. **Private Keys**: Never commit private keys to version control
2. **Protocol Fees**: Maximum fee is capped at 10% (1000 basis points)
3. **Emergency Withdrawals**: Apply penalty fees to discourage misuse
4. **Access Control**: Only vault owners can deposit/withdraw
5. **Time Locks**: Cannot be bypassed except through emergency withdrawal

## Troubleshooting

### Common Issues

1. **Insufficient funds**: Ensure you have enough Base Sepolia ETH
2. **Network connection**: Verify RPC URL is correct and accessible
3. **Private key format**: Should be 64 characters (without 0x prefix)
4. **Gas estimation**: Increase gas limit if transactions fail

### Getting Base Sepolia ETH

1. Visit [Base Sepolia Faucet](https://www.coinbase.com/faucets/base-ethereum-sepolia-faucet)
2. Connect your wallet
3. Request test ETH

## Support

For issues and questions:
1. Check the contract tests for usage examples
2. Review the contract source code for detailed functionality
3. Ensure all prerequisites are met before deployment

## License

MIT License - see LICENSE file for details.
