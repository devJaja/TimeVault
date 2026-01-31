import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';

async function verifyOnBasescan(contractAddress: string, contractName: string, sourceCode: string, constructorArgs: string = '') {
  const apiKey = process.env.BASESCAN_API_KEY;
  const apiUrl = 'https://api.basescan.org/api';
  
  const params = new URLSearchParams({
    module: 'contract',
    action: 'verifysourcecode',
    contractaddress: contractAddress,
    sourceCode: sourceCode,
    codeformat: 'solidity-single-file',
    contractname: contractName,
    compilerversion: 'v0.8.28+commit.7893614a',
    optimizationUsed: '1',
    runs: '200',
    constructorArguements: constructorArgs,
    apikey: apiKey!,
  });

  try {
    const response = await fetch(apiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: params,
    });

    const result = await response.json();
    console.log(`Verification result for ${contractName}:`, result);
    
    if (result.status === '1') {
      console.log(`✅ ${contractName} verification submitted successfully!`);
      console.log(`GUID: ${result.result}`);
      return result.result;
    } else {
      console.error(`❌ Failed to verify ${contractName}:`, result.result);
      return null;
    }
  } catch (error) {
    console.error(`❌ Error verifying ${contractName}:`, error);
    return null;
  }
}

async function checkVerificationStatus(guid: string) {
  const apiKey = process.env.BASESCAN_API_KEY;
  const apiUrl = 'https://api.basescan.org/api';
  
  const params = new URLSearchParams({
    module: 'contract',
    action: 'checkverifystatus',
    guid: guid,
    apikey: apiKey!,
  });

  try {
    const response = await fetch(`${apiUrl}?${params}`);
    const result = await response.json();
    return result;
  } catch (error) {
    console.error('Error checking verification status:', error);
    return null;
  }
}

async function main() {
  try {
    // Read deployment info
    const deploymentInfo = JSON.parse(fs.readFileSync('deployment-mainnet.json', 'utf8'));
    
    // Read VaultFactory source code
    const vaultFactoryPath = path.join(process.cwd(), 'contracts', 'VaultFactory.sol');
    const vaultFactorySource = fs.readFileSync(vaultFactoryPath, 'utf8');
    
    // Verify VaultFactory
    const guid = await verifyOnBasescan(
      deploymentInfo.contracts.VaultFactory.address,
      'VaultFactory',
      vaultFactorySource
    );
    
    if (guid) {
      console.log('\nChecking verification status...');
      setTimeout(async () => {
        const status = await checkVerificationStatus(guid);
        console.log('Verification status:', status);
      }, 10000); // Wait 10 seconds before checking
    }
    
  } catch (error) {
    console.error('Verification failed:', error);
    process.exit(1);
  }
}

main();
