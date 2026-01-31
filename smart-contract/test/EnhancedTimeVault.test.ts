import { expect } from "chai";
import { ethers } from "hardhat";
import { EnhancedTimeVault } from "../typechain-types";

describe("EnhancedTimeVault", function () {
  let vault: EnhancedTimeVault;
  let owner: any;
  let user1: any;
  let user2: any;
  let feeRecipient: any;

  beforeEach(async function () {
    [owner, user1, user2, feeRecipient] = await ethers.getSigners();
    
    const VaultFactory = await ethers.getContractFactory("EnhancedTimeVault");
    vault = await VaultFactory.deploy(feeRecipient.address);
  });

  describe("Vault Creation", function () {
    it("Should create a vault with correct parameters", async function () {
      const unlockTime = Math.floor(Date.now() / 1000) + 86400; // 1 day from now
      const goalAmount = ethers.parseEther("1");
      const depositAmount = ethers.parseEther("0.5");

      await expect(
        vault.connect(user1).createVault(
          "My Savings Goal",
          unlockTime,
          goalAmount,
          0, // PERSONAL
          { value: depositAmount }
        )
      ).to.emit(vault, "VaultCreated");

      const userVaults = await vault.getUserVaults(user1.address);
      expect(userVaults.length).to.equal(1);
      expect(userVaults[0].name).to.equal("My Savings Goal");
      expect(userVaults[0].balance).to.equal(depositAmount);
    });

    it("Should reject vault creation with past unlock time", async function () {
      const pastTime = Math.floor(Date.now() / 1000) - 86400; // 1 day ago
      
      await expect(
        vault.connect(user1).createVault(
          "Invalid Vault",
          pastTime,
          ethers.parseEther("1"),
          0
        )
      ).to.be.revertedWith("Unlock time must be in future");
    });
  });

  describe("Deposits", function () {
    it("Should allow deposits to existing vault", async function () {
      const unlockTime = Math.floor(Date.now() / 1000) + 86400;
      
      await vault.connect(user1).createVault(
        "Test Vault",
        unlockTime,
        ethers.parseEther("2"),
        0,
        { value: ethers.parseEther("1") }
      );

      await expect(
        vault.connect(user1).depositToVault(0, { value: ethers.parseEther("0.5") })
      ).to.emit(vault, "VaultDeposit");

      const userVaults = await vault.getUserVaults(user1.address);
      expect(userVaults[0].balance).to.equal(ethers.parseEther("1.5"));
    });

    it("Should mark goal as reached when deposit meets goal", async function () {
      const unlockTime = Math.floor(Date.now() / 1000) + 86400;
      
      await vault.connect(user1).createVault(
        "Goal Vault",
        unlockTime,
        ethers.parseEther("1"),
        0,
        { value: ethers.parseEther("0.5") }
      );

      await vault.connect(user1).depositToVault(0, { value: ethers.parseEther("0.5") });

      const userVaults = await vault.getUserVaults(user1.address);
      expect(userVaults[0].goalReached).to.be.true;
    });
  });

  describe("Withdrawals", function () {
    it("Should allow withdrawal after unlock time", async function () {
      const unlockTime = Math.floor(Date.now() / 1000) + 1; // 1 second from now
      
      await vault.connect(user1).createVault(
        "Test Vault",
        unlockTime,
        0,
        0,
        { value: ethers.parseEther("1") }
      );

      // Wait for unlock time
      await new Promise(resolve => setTimeout(resolve, 2000));

      await expect(
        vault.connect(user1).withdrawFromVault(0, ethers.parseEther("0.5"))
      ).to.emit(vault, "VaultWithdrawal");
    });

    it("Should allow withdrawal when goal is reached", async function () {
      const unlockTime = Math.floor(Date.now() / 1000) + 86400; // 1 day from now
      
      await vault.connect(user1).createVault(
        "Goal Vault",
        unlockTime,
        ethers.parseEther("1"),
        0,
        { value: ethers.parseEther("1") }
      );

      await expect(
        vault.connect(user1).withdrawFromVault(0, ethers.parseEther("0.5"))
      ).to.emit(vault, "VaultWithdrawal");
    });

    it("Should reject withdrawal before unlock time and goal not reached", async function () {
      const unlockTime = Math.floor(Date.now() / 1000) + 86400;
      
      await vault.connect(user1).createVault(
        "Locked Vault",
        unlockTime,
        ethers.parseEther("2"),
        0,
        { value: ethers.parseEther("1") }
      );

      await expect(
        vault.connect(user1).withdrawFromVault(0, ethers.parseEther("0.5"))
      ).to.be.revertedWith("Vault is still locked");
    });
  });

  describe("Emergency Withdrawal", function () {
    it("Should allow emergency withdrawal with penalty", async function () {
      const unlockTime = Math.floor(Date.now() / 1000) + 86400;
      
      await vault.connect(user1).createVault(
        "Emergency Vault",
        unlockTime,
        0,
        0,
        { value: ethers.parseEther("1") }
      );

      await vault.connect(user1).enableEmergencyWithdrawal(0);

      const initialBalance = await ethers.provider.getBalance(user1.address);
      
      await expect(
        vault.connect(user1).emergencyWithdraw(0)
      ).to.emit(vault, "EmergencyWithdrawal");

      // Check that penalty was applied (user receives less than deposited)
      const finalBalance = await ethers.provider.getBalance(user1.address);
      expect(finalBalance).to.be.lt(initialBalance + ethers.parseEther("1"));
    });

    it("Should reject emergency withdrawal if not enabled", async function () {
      const unlockTime = Math.floor(Date.now() / 1000) + 86400;
      
      await vault.connect(user1).createVault(
        "No Emergency Vault",
        unlockTime,
        0,
        0,
        { value: ethers.parseEther("1") }
      );

      await expect(
        vault.connect(user1).emergencyWithdraw(0)
      ).to.be.revertedWith("Emergency withdrawal not enabled");
    });
  });

  describe("Protocol Management", function () {
    it("Should allow owner to update protocol fee", async function () {
      await vault.connect(owner).updateProtocolFee(100); // 1%
      // No direct getter, but we can test through emergency withdrawal
    });

    it("Should reject fee update above maximum", async function () {
      await expect(
        vault.connect(owner).updateProtocolFee(1001) // 10.01%
      ).to.be.revertedWith("Fee cannot exceed 10%");
    });

    it("Should allow owner to update fee recipient", async function () {
      await vault.connect(owner).updateFeeRecipient(user2.address);
    });

    it("Should reject invalid fee recipient", async function () {
      await expect(
        vault.connect(owner).updateFeeRecipient(ethers.ZeroAddress)
      ).to.be.revertedWith("Invalid recipient");
    });
  });
});
