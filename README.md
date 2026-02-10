# TimeVault

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-^0.8.24-363636)](https://soliditylang.org/)

A decentralized savings protocol built on Base that enables time-locked vaults, automated yield optimization, and goal-based savings.

## Overview

TimeVault is a DeFi savings protocol that combines time-locked vaults with yield optimization strategies. The protocol supports multiple vault types, automated deposits, and integrates with established DeFi protocols for yield generation.

### Key Features

- Time-locked and goal-based savings vaults
- Automated yield optimization across multiple protocols
- Multi-signature support and security controls
- Recurring deposit automation
- NFT-based vault receipts
- Governance and analytics modules

## Architecture

### Core Contracts

| Contract | Purpose |
|----------|---------|
| `TimeVault.sol` | Main vault logic with time-locks and goal tracking |
| `VaultFactory.sol` | Standardized vault deployment and fee management |
| `YieldOptimizer.sol` | Multi-protocol yield strategies and auto-rebalancing |
| `AutomationManager.sol` | Recurring deposit automation via Chainlink |
| `SecurityModule.sol` | Multi-signature and daily withdrawal limits |
| `VaultNFT.sol` | NFT-based vault receipts with dynamic metadata |
| `Governance.sol` | Protocol governance and treasury management |
| `Analytics.sol` | Performance tracking and yield history |

## Quick Start

## Quick Start

### Prerequisites

- Node.js (v18+)
- npm or yarn
- Git
- Hardhat development environment

### Installation

```bash
git clone https://github.com/your-org/TimeVault.git
cd TimeVault
npm install
cp .env.example .env
```

### Environment Setup

```bash
# .env file
PRIVATE_KEY=your_private_key_here
BASE_RPC_URL=https://mainnet.base.org
BASESCAN_API_KEY=your_basescan_api_key
```

### Compilation & Testing

```bash
npm run compile
npm run test
npm run coverage
npm run deploy:testnet
```

## Development

### Contract Deployment

```typescript
const vaultFactory = await ethers.deployContract("VaultFactory", [
  protocolFeePercent,
  feeRecipient
]);

const tx = await vaultFactory.createVault(
  "My Savings Goal",
  unlockTimestamp,
  goalAmountInWei,
  { value: initialDepositAmount }
);
```

### Integration Examples

```typescript
// Recurring deposits
const automationManager = await ethers.getContractAt("AutomationManager", address);
await automationManager.createRecurringDeposit(
  vaultAddress,
  depositAmount,
  frequency,
  { value: totalPayment }
);

// Yield optimization
const yieldOptimizer = await ethers.getContractAt("YieldOptimizer", address);
const optimalStrategy = await yieldOptimizer.getOptimalStrategy();
```

## Testing

```bash
npm run test
npx hardhat test test/TimeVault.test.ts
npm run coverage
```

## Deployment

### Supported Networks

| Network | Chain ID | Status |
|---------|----------|--------|
| Base Mainnet | 8453 | Live |
| Base Sepolia | 84532 | Testnet |

## Security

- OpenZeppelin integration for battle-tested security patterns
- Multi-signature support for access control
- Daily withdrawal limits
- Emergency pause functionality
- Complete audit trail

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

## Disclaimer

TimeVault is experimental DeFi software. Smart contracts carry inherent risks. Users should never invest more than they can afford to lose and should understand the risks of DeFi protocols.

**This software is provided "as is" without warranty of any kind.**
