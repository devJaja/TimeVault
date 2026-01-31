import 'dotenv/config';
import { createPublicClient, createWalletClient, http, parseEther } from 'viem';
import { base } from 'viem/chains';
import { privateKeyToAccount } from 'viem/accounts';
import * as fs from 'fs';
import * as path from 'path';

const rawKey = process.env.ACCOUNT_PRIVATE_KEY?.replace(/['"]/g, '').replace(/^0x/, '');
console.log('Raw key length:', rawKey?.length);
console.log('Raw key:', rawKey);

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
    // Deploy VaultFactory
    const vaultFactory = await deployContract('VaultFactory');
    
    // Deploy a demo TimeVault
    const demoTimeVault = await deployContract('TimeVault', [
      'Demo TimeVault',
      Math.floor(Date.now() / 1000) + 86400 * 7, // 1 week from now
      parseEther('1'), // 1 ETH goal
      account.address,
      50 // 0.5% protocol fee
    ]);
    
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
          address: demoTimeVault.address,
          transactionHash: demoTimeVault.transactionHash,
        },
      },
    };
    
    fs.writeFileSync(
      'deployment-mainnet.json',
      JSON.stringify(deploymentInfo, null, 2)
    );
    
    console.log('\nDeployment completed!');
    console.log('VaultFactory:', vaultFactory.address);
    console.log('Demo TimeVault:', demoTimeVault.address);
    console.log('\nDeployment info saved to deployment-mainnet.json');
    
  } catch (error) {
    console.error('Deployment failed:', error);
    process.exit(1);
  }
}

main();
