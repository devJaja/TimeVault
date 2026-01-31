import 'dotenv/config';
import { exec } from 'child_process';
import { promisify } from 'util';
import * as fs from 'fs';

const execAsync = promisify(exec);

async function verifyContract(contractName: string, address: string, constructorArgs: any[] = []) {
  console.log(`Verifying ${contractName} at ${address}...`);
  
  const argsString = constructorArgs.length > 0 ? 
    `--constructor-args ${constructorArgs.map(arg => `"${arg}"`).join(' ')}` : '';
  
  const command = `npx hardhat verify --network base-mainnet ${address} ${argsString}`;
  
  try {
    const { stdout, stderr } = await execAsync(command);
    console.log(`✅ ${contractName} verified successfully!`);
    console.log(stdout);
    return true;
  } catch (error: any) {
    if (error.message.includes('Already Verified')) {
      console.log(`✅ ${contractName} already verified!`);
      return true;
    }
    console.error(`❌ Failed to verify ${contractName}:`, error.message);
    return false;
  }
}

async function main() {
  try {
    // Read deployment info
    const deploymentInfo = JSON.parse(fs.readFileSync('deployment-mainnet.json', 'utf8'));
    
    // Verify VaultFactory
    await verifyContract(
      'VaultFactory',
      deploymentInfo.contracts.VaultFactory.address
    );
    
    console.log('\n🎉 All contracts verified!');
    
  } catch (error) {
    console.error('Verification failed:', error);
    process.exit(1);
  }
}

main();
