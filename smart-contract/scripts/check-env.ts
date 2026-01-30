#!/usr/bin/env node

import hre from "hardhat";

async function checkHardhatEnvironment() {
  console.log("🔍 Checking Hardhat environment...\n");
  
  console.log("Available properties in hre:");
  console.log(Object.keys(hre));
  
  if (hre.viem) {
    console.log("\n✅ hre.viem is available");
    console.log("Available methods in hre.viem:");
    console.log(Object.keys(hre.viem));
  } else {
    console.log("\n❌ hre.viem is not available");
  }
  
  if (hre.ethers) {
    console.log("\n✅ hre.ethers is available");
  } else {
    console.log("\n❌ hre.ethers is not available");
  }
}

checkHardhatEnvironment();
