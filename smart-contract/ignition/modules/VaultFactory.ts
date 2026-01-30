import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const VaultFactoryModule = buildModule("VaultFactoryModule", (m) => {
  const vaultFactory = m.contract("VaultFactory");

  return { vaultFactory };
});

export default VaultFactoryModule;
