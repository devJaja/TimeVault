import { expect } from "chai";
import hre from "hardhat";
import { getAddress, parseEther } from "viem";

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
      expect(await vaultFactory.read.owner()).to.equal(getAddress(owner.account.address));
    });

    it("Should set initial protocol fee to 0.5%", async function () {
      expect(await vaultFactory.read.protocolFee()).to.equal(50n);
    });

    it("Should initialize total vaults to 0", async function () {
      expect(await vaultFactory.read.totalVaults()).to.equal(0n);
    });
  });

  describe("Vault Creation", function () {
    it("Should create a new vault successfully", async function () {
      const name = "My Savings Vault";
      const unlockTime = BigInt(Math.floor(Date.now() / 1000) + 86400); // 1 day from now
      const goalAmount = parseEther("1");

      const hash = await vaultFactory.write.createVault([name, unlockTime, goalAmount], {
        account: user1.account,
      });

      const receipt = await viem.getPublicClient().waitForTransactionReceipt({ hash });
      
      expect(receipt.status).to.equal("success");
      expect(await vaultFactory.read.totalVaults()).to.equal(1n);
      
      const userVaults = await vaultFactory.read.getUserVaults([user1.account.address]);
      expect(userVaults).to.have.length(1);
    });

    it("Should revert with empty name", async function () {
      const unlockTime = BigInt(Math.floor(Date.now() / 1000) + 86400);
      const goalAmount = parseEther("1");

      await expect(
        vaultFactory.write.createVault(["", unlockTime, goalAmount], {
          account: user1.account,
        })
      ).to.be.rejectedWith("VaultFactory__EmptyName");
    });

    it("Should revert with past unlock time", async function () {
      const name = "My Vault";
      const unlockTime = BigInt(Math.floor(Date.now() / 1000) - 86400); // 1 day ago
      const goalAmount = parseEther("1");

      await expect(
        vaultFactory.write.createVault([name, unlockTime, goalAmount], {
          account: user1.account,
        })
      ).to.be.rejectedWith("VaultFactory__InvalidUnlockTime");
    });

    it("Should emit VaultCreated event", async function () {
      const name = "Test Vault";
      const unlockTime = BigInt(Math.floor(Date.now() / 1000) + 86400);
      const goalAmount = parseEther("1");

      const hash = await vaultFactory.write.createVault([name, unlockTime, goalAmount], {
        account: user1.account,
      });

      const receipt = await viem.getPublicClient().waitForTransactionReceipt({ hash });
      const logs = await viem.getPublicClient().getLogs({
        address: vaultFactory.address,
        fromBlock: receipt.blockNumber,
        toBlock: receipt.blockNumber,
      });

      expect(logs).to.have.length.greaterThan(0);
    });

    it("Should track multiple vaults for same user", async function () {
      const unlockTime = BigInt(Math.floor(Date.now() / 1000) + 86400);
      const goalAmount = parseEther("1");

      await vaultFactory.write.createVault(["Vault 1", unlockTime, goalAmount], {
        account: user1.account,
      });
      
      await vaultFactory.write.createVault(["Vault 2", unlockTime, goalAmount], {
        account: user1.account,
      });

      const userVaults = await vaultFactory.read.getUserVaults([user1.account.address]);
      expect(userVaults).to.have.length(2);
      expect(await vaultFactory.read.totalVaults()).to.equal(2n);
    });
  });

  describe("Protocol Fee Management", function () {
    it("Should allow owner to update protocol fee", async function () {
      const newFee = 100n; // 1%

      await vaultFactory.write.setProtocolFee([newFee], {
        account: owner.account,
      });

      expect(await vaultFactory.read.protocolFee()).to.equal(newFee);
    });

    it("Should revert if non-owner tries to update fee", async function () {
      const newFee = 100n;

      await expect(
        vaultFactory.write.setProtocolFee([newFee], {
          account: user1.account,
        })
      ).to.be.rejectedWith("VaultFactory__NotOwner");
    });

    it("Should revert if fee is too high", async function () {
      const newFee = 1001n; // 10.01%

      await expect(
        vaultFactory.write.setProtocolFee([newFee], {
          account: owner.account,
        })
      ).to.be.rejectedWith("VaultFactory__FeeTooHigh");
    });

    it("Should emit ProtocolFeeUpdated event", async function () {
      const newFee = 100n;

      const hash = await vaultFactory.write.setProtocolFee([newFee], {
        account: owner.account,
      });

      const receipt = await viem.getPublicClient().waitForTransactionReceipt({ hash });
      expect(receipt.status).to.equal("success");
    });
  });

  describe("Ownership Management", function () {
    it("Should allow owner to transfer ownership", async function () {
      await vaultFactory.write.transferOwnership([user1.account.address], {
        account: owner.account,
      });

      expect(await vaultFactory.read.owner()).to.equal(getAddress(user1.account.address));
    });

    it("Should revert if non-owner tries to transfer ownership", async function () {
      await expect(
        vaultFactory.write.transferOwnership([user2.account.address], {
          account: user1.account,
        })
      ).to.be.rejectedWith("VaultFactory__NotOwner");
    });

    it("Should revert if transferring to zero address", async function () {
      await expect(
        vaultFactory.write.transferOwnership(["0x0000000000000000000000000000000000000000"], {
          account: owner.account,
        })
      ).to.be.rejectedWith("VaultFactory__ZeroAddress");
    });
  });

  describe("View Functions", function () {
    beforeEach(async function () {
      const unlockTime = BigInt(Math.floor(Date.now() / 1000) + 86400);
      const goalAmount = parseEther("1");

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

    it("Should correctly identify vault addresses", async function () {
      const allVaults = await vaultFactory.read.getAllVaults();
      
      for (const vaultAddress of allVaults) {
        expect(await vaultFactory.read.isVault([vaultAddress])).to.be.true;
      }
    });
  });
});
