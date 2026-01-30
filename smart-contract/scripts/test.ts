#!/usr/bin/env node

import { execSync } from 'child_process';

console.log('🧪 Running TimeVault contract tests...\n');

try {
  // Compile contracts first
  console.log('📦 Compiling contracts...');
  execSync('npx hardhat compile', { stdio: 'inherit' });
  
  console.log('\n🧪 Running VaultFactory tests...');
  execSync('npx hardhat test test/VaultFactory.test.ts', { stdio: 'inherit' });
  
  console.log('\n🧪 Running TimeVault tests...');
  execSync('npx hardhat test test/TimeVault.test.ts', { stdio: 'inherit' });
  
  console.log('\n✅ All tests completed successfully!');
  
} catch (error) {
  console.error('\n❌ Tests failed:', error);
  process.exit(1);
}
