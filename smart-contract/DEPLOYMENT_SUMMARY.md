# TimeVault Deployment Summary - Base Mainnet

## Deployment Details
- **Network**: Base Mainnet (Chain ID: 8453)
- **Date**: January 31, 2026
- **Deployer**: 0x... (from private key)

## Deployed Contracts

### VaultFactory
- **Address**: `0xdf96b793277c6c30194381335f358f32162c8522`
- **Transaction**: `0xe669ccdcdf2ac5f8fd19e3c5277d5cc2dbcb355d76f18cacf7b3bd567de48289`
- **Basescan**: https://basescan.org/address/0xdf96b793277c6c30194381335f358f32162c8522

### Demo TimeVault
- **Address**: `0x3cb2b5799c2d8c799594dd440ef9c5bc352ff504`
- **Transaction**: `0x3cf7356c80be728773c5f89693befb0818f77d6394ff6194150419f46da2f0f4`
- **Basescan**: https://basescan.org/address/0x3cb2b5799c2d8c799594dd440ef9c5bc352ff504
- **Parameters**:
  - Name: "Demo TimeVault"
  - Unlock Time: 1 week from deployment
  - Goal Amount: 1 ETH
  - Owner: Deployer address
  - Protocol Fee: 0.5%

## Verification

### Manual Verification Steps
1. Go to Basescan contract verification page
2. Use the flattened contract files:
   - `VaultFactory_flattened.sol` for VaultFactory
   - `TimeVault_flattened.sol` for TimeVault
3. Compiler version: `0.8.28`
4. Optimization: Enabled (200 runs)
5. For TimeVault, include constructor arguments:
   - _name: "Demo TimeVault"
   - _unlockTime: [calculated timestamp]
   - _goalAmount: 1000000000000000000 (1 ETH in wei)
   - _owner: [deployer address]
   - _protocolFee: 50

## Next Steps
1. Verify contracts on Basescan using the flattened files
2. Test contract functionality
3. Set up frontend integration
4. Deploy additional yield adapters if needed

## Files Generated
- `deployment-mainnet.json` - Deployment details
- `VaultFactory_flattened.sol` - Flattened VaultFactory for verification
- `TimeVault_flattened.sol` - Flattened TimeVault for verification
