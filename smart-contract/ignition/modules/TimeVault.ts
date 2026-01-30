import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const TimeVaultModule = buildModule("TimeVaultModule", (m) => {
  // Parameters for the TimeVault deployment
  const name = m.getParameter("name", "Demo Savings Vault");
  const unlockTime = m.getParameter("unlockTime", Math.floor(Date.now() / 1000) + 86400); // 1 day from now
  const goalAmount = m.getParameter("goalAmount", "1000000000000000000"); // 1 ETH in wei
  const owner = m.getParameter("owner", "0x0000000000000000000000000000000000000000"); // Must be provided
  const protocolFee = m.getParameter("protocolFee", 50); // 0.5%

  const timeVault = m.contract("TimeVault", [
    name,
    unlockTime,
    goalAmount,
    owner,
    protocolFee,
  ]);

  return { timeVault };
});

export default TimeVaultModule;
