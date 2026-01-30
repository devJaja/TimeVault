import { expect } from "chai";
import hre from "hardhat";

describe("VaultFactory", function () {
  let vaultFactory: any;
  let owner: any;
  let user1: any;
  let user2: any;

  beforeEach(async function () {
    [owner, user1, user2] = await hre.viem.getWalletClients();
    vaultFactory = await hre.viem.deployContract("VaultFactory");
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      const factoryOwner = await vaultFactory.read.owner();
      expect(factoryOwner.toLowerCase()).to.equal(owner.account.address.toLowerCase());
    });

    it("Should set initial protocol fee to 0.5%", async function () {
      const fee = await vaultFactory.read.protocolFee();
      expect(fee).to.equal(50n);
    });

    it("Should initialize total vaults to 0", async function () {
      const totalVaults = await vaultFactory.read.totalVaults();
      expect(totalVaults).to.equal(0n);
    });
  });

  describe("Vault Creation", function () {
    it("Should create a new vault successfully", async function () {
      const name = "My Savings Vault";
      const unlockTime = BigInt(Math.floor(Date.now() / 1000) + 86400); // 1 day from now
      const goalAmount = BigInt("1000000000000000000"); // 1 ETH in wei

      const hash = await vaultFactory.write.createVault([name, unlockTime, goalAmount], {
        account: user1.account,
      });

      const receipt = await hre.viem.getPublicClient().waitForTransactionReceipt({ hash });
      
      expect(receipt.status).to.equal("success");
      
      const totalVaults = await vaultFactory.read.totalVaults();
      expect(totalVaults).to.equal(1n);
      
      const userVaults = await vaultFactory.read.getUserVaults([user1.account.address]);
      expect(userVaults).to.have.length(1);
    });

    it("Should revert with empty name", async function () {
      const unlockTime = BigInt(Math.floor(Date.now() / 1000) + 86400);
      const goalAmount = BigInt("1000000000000000000");

      try {
        await vaultFactory.write.createVault(["", unlockTime, goalAmount], {
          account: user1.account,
        });
        expect.fail("Should have reverted");
      } catch (error: any) {
        expect(error.message).to.include("VaultFactory__EmptyName");
      }
    });

    it("Should revert with past unlock time", async function () {
      const name = "My Vault";
      const unlockTime = BigInt(Math.floor(Date.now() / 1000) - 86400); // 1 day ago
      const goalAmount = BigInt("1000000000000000000");

      try {
        await vaultFactory.write.createVault([name, unlockTime, goalAmount], {
          account: user1.account,
        });
        expect.fail("Should have reverted");
      } catch (error: any) {
        expect(error.message).to.include("VaultFactory__InvalidUnlockTime");
      }
    });
  });

  describe("Protocol Fee Management", function () {
    it("Should allow owner to update protocol fee", async function () {
      const newFee = 100n; // 1%

      await vaultFactory.write.setProtocolFee([newFee], {
        account: owner.account,
      });

      const fee = await vaultFactory.read.protocolFee();
      expect(fee).to.equal(newFee);
    });

    it("Should revert if non-owner tries to update fee", async function () {
      const newFee = 100n;

      try {
        await vaultFactory.write.setProtocolFee([newFee], {
          account: user1.account,
        });
        expect.fail("Should have reverted");
      } catch (error: any) {
        expect(error.message).to.include("VaultFactory__NotOwner");
      }
    });

    it("Should revert if fee is too high", async function () {
      const newFee = 1001n; // 10.01%

      try {
        await vaultFactory.write.setProtocolFee([newFee], {
          account: owner.account,
        });
        expect.fail("Should have reverted");
      } catch (error: any) {
        expect(error.message).to.include("VaultFactory__FeeTooHigh");
      }
    });
  });

  describe("View Functions", function () {
    beforeEach(async function () {
      const unlockTime = BigInt(Math.floor(Date.now() / 1000) + 86400);
      const goalAmount = BigInt("1000000000000000000");

      await vaultFactory.write.createVault(["Vault 1", unlockTime, goalAmount], {
        account: user1.account,
      });
      
      await vaultFactory.write.createVault(["Vault 2", unlockTime, goalAmount], {
        account: user2.account,
      });
    });

    it("Should return all vaults", async function () {
      const allVaults = await vaultFactory.read.getAllVaults();
      expect(allVaults).to.have.length(2);
    });

    it("Should return user-specific vaults", async function () {
      const user1Vaults = await vaultFactory.read.getUserVaults([user1.account.address]);
      const user2Vaults = await vaultFactory.read.getUserVaults([user2.account.address]);

      expect(user1Vaults).to.have.length(1);
      expect(user2Vaults).to.have.length(1);
    });
  });
});
