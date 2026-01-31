import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const EnhancedTimeVaultModule = buildModule("EnhancedTimeVaultModule", (m) => {
  // Deploy core contracts
  const vaultFactory = m.contract("VaultFactory");
  
  // Deploy user management
  const registerUser = m.contract("RegisterUser");
  
  // Deploy governance and dispute resolution
  const governance = m.contract("Governance");
  const dispute = m.contract("Dispute");
  
  // Deploy subscription system
  const subscription = m.contract("Subscription");
  
  // Deploy referral system
  const referral = m.contract("Referral");
  
  // Deploy insurance
  const insurance = m.contract("Insurance");
  
  // Deploy staking
  const staking = m.contract("Staking");
  
  // Deploy analytics
  const analytics = m.contract("Analytics");

  return { 
    vaultFactory,
    registerUser,
    governance,
    dispute,
    subscription,
    referral,
    insurance,
    staking,
    analytics
  };
});

export default EnhancedTimeVaultModule;
