#!/usr/bin/env node

import { execSync } from 'child_process';
import { readFileSync, writeFileSync } from 'fs';
import { join } from 'path';

interface DeploymentConfig {
  network: string;
  deployDemo: boolean;
  demoOwner?: string;
  demoName?: string;
  demoUnlockTime?: number;
  demoGoalAmount?: string;
}

const defaultConfig: DeploymentConfig = {
  network: 'base-sepolia',
  deployDemo: false,
  demoName: 'Demo TimeVault',
  demoUnlockTime: Math.floor(Date.now() / 1000) + 86400 * 7, // 1 week from now
  demoGoalAmount: '1000000000000000000', // 1 ETH
};

async function deployContracts(config: DeploymentConfig) {
  console.log(`🚀 Deploying TimeVault contracts to ${config.network}...`);
  
  try {
    // Build the deployment command
    let deployCmd = `npx hardhat ignition deploy ignition/modules/VaultFactory.ts --network ${config.network}`;
    
    console.log('📦 Deploying VaultFactory...');
    const factoryResult = execSync(deployCmd, { encoding: 'utf8' });
    console.log(factoryResult);
    
    if (config.deployDemo && config.demoOwner) {
      console.log('📦 Deploying Demo TimeVault...');
      const demoCmd = `npx hardhat ignition deploy ignition/modules/TimeVault.ts --network ${config.network} --parameters '{"name":"${config.demoName}","unlockTime":${config.demoUnlockTime},"goalAmount":"${config.demoGoalAmount}","owner":"${config.demoOwner}","protocolFee":50}'`;
      
      const demoResult = execSync(demoCmd, { encoding: 'utf8' });
      console.log(demoResult);
    }
    
    console.log('✅ Deployment completed successfully!');
    
    // Save deployment info
    const deploymentInfo = {
      network: config.network,
      timestamp: new Date().toISOString(),
      config,
    };
    
    writeFileSync(
      join(process.cwd(), `deployment-${config.network}-${Date.now()}.json`),
      JSON.stringify(deploymentInfo, null, 2)
    );
    
  } catch (error) {
    console.error('❌ Deployment failed:', error);
    process.exit(1);
  }
}

// Parse command line arguments
const args = process.argv.slice(2);
const config = { ...defaultConfig };

for (let i = 0; i < args.length; i += 2) {
  const key = args[i]?.replace('--', '');
  const value = args[i + 1];
  
  switch (key) {
    case 'network':
      config.network = value;
      break;
    case 'deploy-demo':
      config.deployDemo = value === 'true';
      break;
    case 'demo-owner':
      config.demoOwner = value;
      break;
    case 'demo-name':
      config.demoName = value;
      break;
    case 'demo-unlock-time':
      config.demoUnlockTime = parseInt(value);
      break;
    case 'demo-goal-amount':
      config.demoGoalAmount = value;
      break;
  }
}

// Validate required parameters
if (config.deployDemo && !config.demoOwner) {
  console.error('❌ Error: --demo-owner is required when --deploy-demo is true');
  process.exit(1);
}

console.log('📋 Deployment Configuration:');
console.log(JSON.stringify(config, null, 2));
console.log('');

deployContracts(config);
