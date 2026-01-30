import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const TimeVaultDeploymentModule = buildModule("TimeVaultDeploymentModule", (m) => {
  // Deploy VaultFactory first
  const vaultFactory = m.contract("VaultFactory");

  // Optional: Deploy a demo TimeVault for testing
  const demoName = m.getParameter("demoName", "Demo TimeVault");
  const demoUnlockTime = m.getParameter("demoUnlockTime", Math.floor(Date.now() / 1000) + 86400 * 7); // 1 week from now
  const demoGoalAmount = m.getParameter("demoGoalAmount", "1000000000000000000"); // 1 ETH
  const demoOwner = m.getParameter("demoOwner");
  const protocolFee = m.getParameter("protocolFee", 50); // 0.5%

  // Only deploy demo vault if owner is provided
  const demoTimeVault = m.contractAt("TimeVault", m.getParameter("deployDemo", false) ? 
    m.contract("TimeVault", [
      demoName,
      demoUnlockTime,
      demoGoalAmount,
      demoOwner,
      protocolFee,
    ]).address : "0x0000000000000000000000000000000000000000"
  );

  return { 
    vaultFactory,
    demoTimeVault: m.getParameter("deployDemo", false) ? demoTimeVault : undefined
  };
});

export default TimeVaultDeploymentModule;
