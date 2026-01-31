import 'dotenv/config';
import { createPublicClient, createWalletClient, http, parseEther } from 'viem';
import { base } from 'viem/chains';
import { privateKeyToAccount } from 'viem/accounts';
import * as fs from 'fs';
import * as path from 'path';

const rawKey = process.env.ACCOUNT_PRIVATE_KEY?.replace(/['"]/g, '').replace(/^0x/, '');
if (!rawKey || rawKey.length !== 64) {
  throw new Error('Invalid private key format. Expected 64 hex characters.');
}

const PRIVATE_KEY = `0x${rawKey}` as `0x${string}`;
const RPC_URL = process.env.MAINNET_RPC_URL!;

const account = privateKeyToAccount(PRIVATE_KEY);

const publicClient = createPublicClient({
  chain: base,
  transport: http(RPC_URL),
});

const walletClient = createWalletClient({
  account,
  chain: base,
  transport: http(RPC_URL),
});

async function deployContract(contractName: string, args: any[] = []) {
  const artifactPath = path.join(process.cwd(), 'artifacts', 'contracts', `${contractName}.sol`, `${contractName}.json`);
  const artifact = JSON.parse(fs.readFileSync(artifactPath, 'utf8'));
  
  console.log(`Deploying ${contractName}...`);
  
  const hash = await walletClient.deployContract({
    abi: artifact.abi,
    bytecode: artifact.bytecode,
    args,
  });
  
  console.log(`Transaction hash: ${hash}`);
  
  const receipt = await publicClient.waitForTransactionReceipt({ hash });
  console.log(`${contractName} deployed at: ${receipt.contractAddress}`);
  
  return {
    address: receipt.contractAddress,
    abi: artifact.abi,
    transactionHash: hash,
  };
}

async function main() {
  try {
    console.log('🚀 Deploying Enhanced TimeVault Ecosystem...\n');
    
    // Deploy core contracts
    const vaultFactory = await deployContract('VaultFactory');
    const timeVault = await deployContract('TimeVault', [
      'Demo TimeVault',
      Math.floor(Date.now() / 1000) + 86400 * 7,
      parseEther('1'),
      account.address,
      50
    ]);
    
    // Deploy user management
    const registerUser = await deployContract('RegisterUser');
    
    // Deploy governance and dispute
    const governance = await deployContract('Governance');
    const dispute = await deployContract('Dispute');
    
    // Deploy subscription system
    const subscription = await deployContract('Subscription');
    
    // Deploy referral system
    const referral = await deployContract('Referral');
    
    // Deploy insurance
    const insurance = await deployContract('Insurance');
    
    // Deploy staking
    const staking = await deployContract('Staking');
    
    // Deploy analytics
    const analytics = await deployContract('Analytics');
    
    // Save deployment info
    const deploymentInfo = {
      network: 'base-mainnet',
      chainId: 8453,
      timestamp: new Date().toISOString(),
      contracts: {
        VaultFactory: {
          address: vaultFactory.address,
          transactionHash: vaultFactory.transactionHash,
        },
        TimeVault: {
          address: timeVault.address,
          transactionHash: timeVault.transactionHash,
        },
        RegisterUser: {
          address: registerUser.address,
          transactionHash: registerUser.transactionHash,
        },
        Governance: {
          address: governance.address,
          transactionHash: governance.transactionHash,
        },
        Dispute: {
          address: dispute.address,
          transactionHash: dispute.transactionHash,
        },
        Subscription: {
          address: subscription.address,
          transactionHash: subscription.transactionHash,
        },
        Referral: {
          address: referral.address,
          transactionHash: referral.transactionHash,
        },
        Insurance: {
          address: insurance.address,
          transactionHash: insurance.transactionHash,
        },
        Staking: {
          address: staking.address,
          transactionHash: staking.transactionHash,
        },
        Analytics: {
          address: analytics.address,
          transactionHash: analytics.transactionHash,
        },
      },
    };
    
    fs.writeFileSync(
      'deployment-enhanced-mainnet.json',
      JSON.stringify(deploymentInfo, null, 2)
    );
    
    console.log('\n✅ Enhanced TimeVault Ecosystem Deployment Completed!');
    console.log('\n📋 Contract Addresses:');
    console.log('VaultFactory:', vaultFactory.address);
    console.log('TimeVault:', timeVault.address);
    console.log('RegisterUser:', registerUser.address);
    console.log('Governance:', governance.address);
    console.log('Dispute:', dispute.address);
    console.log('Subscription:', subscription.address);
    console.log('Referral:', referral.address);
    console.log('Insurance:', insurance.address);
    console.log('Staking:', staking.address);
    console.log('Analytics:', analytics.address);
    console.log('\n💾 Deployment info saved to deployment-enhanced-mainnet.json');
    
  } catch (error) {
    console.error('❌ Deployment failed:', error);
    process.exit(1);
  }
}

main();
