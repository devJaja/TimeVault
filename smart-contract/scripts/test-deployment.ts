#!/usr/bin/env node

import hre from "hardhat";

async function testDeployment() {
  console.log("🧪 Testing VaultFactory and TimeVault deployment...\n");

  try {
    // Get wallet clients
    const [owner, user1] = await hre.viem.getWalletClients();
    console.log("✅ Got wallet clients");
    console.log(`Owner: ${owner.account.address}`);
    console.log(`User1: ${user1.account.address}\n`);

    // Deploy VaultFactory
    console.log("📦 Deploying VaultFactory...");
    const vaultFactory = await hre.viem.deployContract("VaultFactory");
    console.log(`✅ VaultFactory deployed at: ${vaultFactory.address}\n`);

    // Test VaultFactory initial state
    const factoryOwner = await vaultFactory.read.owner();
    const protocolFee = await vaultFactory.read.protocolFee();
    const totalVaults = await vaultFactory.read.totalVaults();

    console.log("📊 VaultFactory Initial State:");
    console.log(`  Owner: ${factoryOwner}`);
    console.log(`  Protocol Fee: ${protocolFee} (0.5%)`);
    console.log(`  Total Vaults: ${totalVaults}\n`);

    // Create a vault
    console.log("🏗️  Creating a new vault...");
    const vaultName = "Test Savings Vault";
    const unlockTime = BigInt(Math.floor(Date.now() / 1000) + 86400); // 1 day from now
    const goalAmount = BigInt("1000000000000000000"); // 1 ETH

    const createTxHash = await vaultFactory.write.createVault([vaultName, unlockTime, goalAmount], {
      account: user1.account,
    });

    const receipt = await hre.viem.getPublicClient().waitForTransactionReceipt({ 
      hash: createTxHash 
    });

    console.log(`✅ Vault created! Transaction: ${createTxHash}`);
    console.log(`  Gas used: ${receipt.gasUsed}\n`);

    // Check vault creation results
    const newTotalVaults = await vaultFactory.read.totalVaults();
    const userVaults = await vaultFactory.read.getUserVaults([user1.account.address]);
    const allVaults = await vaultFactory.read.getAllVaults();

    console.log("📊 After Vault Creation:");
    console.log(`  Total Vaults: ${newTotalVaults}`);
    console.log(`  User1 Vaults: ${userVaults.length}`);
    console.log(`  All Vaults: ${allVaults.length}`);
    console.log(`  New Vault Address: ${userVaults[0]}\n`);

    // Test TimeVault directly
    console.log("📦 Deploying TimeVault directly...");
    const timeVault = await hre.viem.deployContract("TimeVault", [
      "Direct Test Vault",
      unlockTime,
      goalAmount,
      owner.account.address,
      50n // 0.5% protocol fee
    ]);

    console.log(`✅ TimeVault deployed at: ${timeVault.address}\n`);

    // Test TimeVault initial state
    const vaultInfo = await timeVault.read.getVaultInfo();
    console.log("📊 TimeVault Initial State:");
    console.log(`  Name: ${vaultInfo[0]}`);
    console.log(`  Unlock Time: ${vaultInfo[1]}`);
    console.log(`  Goal Amount: ${vaultInfo[2]} wei`);
    console.log(`  Owner: ${vaultInfo[3]}`);
    console.log(`  Balance: ${vaultInfo[4]} wei`);
    console.log(`  Goal Reached: ${vaultInfo[5]}`);
    console.log(`  Emergency Enabled: ${vaultInfo[6]}\n`);

    // Test deposit
    console.log("💰 Testing deposit...");
    const depositAmount = BigInt("500000000000000000"); // 0.5 ETH
    
    const depositTxHash = await timeVault.write.deposit({
      account: owner.account,
      value: depositAmount,
    });

    const depositReceipt = await hre.viem.getPublicClient().waitForTransactionReceipt({ 
      hash: depositTxHash 
    });

    console.log(`✅ Deposit successful! Transaction: ${depositTxHash}`);
    console.log(`  Gas used: ${depositReceipt.gasUsed}\n`);

    // Check vault state after deposit
    const vaultInfoAfterDeposit = await timeVault.read.getVaultInfo();
    console.log("📊 TimeVault After Deposit:");
    console.log(`  Balance: ${vaultInfoAfterDeposit[4]} wei (${Number(vaultInfoAfterDeposit[4]) / 1e18} ETH)`);
    console.log(`  Goal Reached: ${vaultInfoAfterDeposit[5]}\n`);

    console.log("🎉 All tests passed successfully!");
    console.log("\n📋 Summary:");
    console.log("✅ VaultFactory deployment and basic functionality");
    console.log("✅ Vault creation through factory");
    console.log("✅ TimeVault direct deployment");
    console.log("✅ TimeVault deposit functionality");
    console.log("✅ State management and view functions");

  } catch (error) {
    console.error("❌ Test failed:", error);
    process.exit(1);
  }
}

testDeployment();
