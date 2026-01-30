# TimeVault: A Decentralized Savings Protocol

**TimeVault** is a decentralized savings vault protocol built natively on the Base network. It allows users to create time-locked or goal-based savings vaults with transparent on-chain guarantees, bringing the reliability of traditional savings with the transparency of blockchain.

## Version
1.1.0

## License
MIT

## Network
Base (Chain ID: 8453)

## Solidity Version
^0.8.24

## Features

### Core Savings
- **Time-Locked Vaults**: Set unlock timestamps to enforce savings discipline.
- **Goal-Based Vaults**: Define savings goals that must be reached before withdrawal.
- **Vault Metadata**: Name and describe your vaults for easy identification.
- **Multiple Vaults**: Create unlimited vaults with different parameters.
- **Emergency Withdrawals**: Access funds early if absolutely needed.
- **Transparent Fees**: Clear 0.5% protocol fee on deposits (adjustable by owner).

### Yield Integration
- **Aave V3 Adapter**: Earn yield through Aave V3 deposits.
- **Compound V3 Adapter**: Alternative yield through Compound.
- **Auto-Strategy Selection**: Automatically routes to the best APY.
- **Yield Tracking**: Historical performance metrics.

### Automation
- **Recurring Deposits**: Chainlink Automation compatible scheduling.
- **Flexible Frequencies**: Daily, weekly, bi-weekly, or monthly.
- **Retry Logic**: Automatic retry on failed executions.

### Social & Gamification
- **Group Vaults**: Create shared savings with friends/family.
- **Savings Challenges**: Compete with others to reach goals.
- **Referral System**: Earn rewards for referrals with tiered badges.
- **Leaderboard**: Track top savers with achievement badges.

### NFT Receipts
- **Vault Receipt NFTs**: On-chain SVG NFTs for your vaults.
- **Tier Badges**: Bronze, Silver, Gold, Platinum tiers.
- **Dynamic Metadata**: Progress tracking embedded in the NFT.

## Getting Started

### Prerequisites
- Node.js
- Yarn or npm
- Git

### Installation
Clone the repository and install the dependencies:
```bash
git clone <repository-url>
cd TimeVault/smart-contract
npm install
```

### Compile Contracts
```bash
npx hardhat compile
```

### Run Tests
```bash
npx hardhat test
```

### Deploy
```bash
npx hardhat ignition deploy --network <your-network> ignition/modules/YourModule.ts
```

## Disclaimer
This is a proof of concept and should not be used in production without a full security audit.