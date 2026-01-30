import { expect } from "chai";
import { viem } from "hardhat";
import { getAddress, parseEther } from "viem";

describe("TimeVault", function () {
  let timeVault: any;
  let owner: any;
  let user1: any;
  let user2: any;

  const vaultName = "Test Savings Vault";
  const unlockTime = BigInt(Math.floor(Date.now() / 1000) + 86400); // 1 day from now
  const goalAmount = parseEther("2");
  const protocolFee = 50n; // 0.5%

  beforeEach(async function () {
    [owner, user1, user2] = await viem.getWalletClients();
    
    timeVault = await viem.deployContract("TimeVault", [
      vaultName,
      unlockTime,
      goalAmount,
      owner.account.address,
      protocolFee,
    ]);
  });

  describe("Deployment", function () {
    it("Should set the correct initial values", async function () {
      expect(await timeVault.read.name()).to.equal(vaultName);
      expect(await timeVault.read.unlockTime()).to.equal(unlockTime);
      expect(await timeVault.read.goalAmount()).to.equal(goalAmount);
      expect(await timeVault.read.owner()).to.equal(getAddress(owner.account.address));
      expect(await timeVault.read.protocolFee()).to.equal(protocolFee);
      expect(await timeVault.read.balance()).to.equal(0n);
      expect(await timeVault.read.goalReached()).to.be.false;
      expect(await timeVault.read.emergencyWithdrawalEnabled()).to.be.false;
    });
  });

  describe("Deposits", function () {
    it("Should allow owner to deposit", async function () {
      const depositAmount = parseEther("1");

      const hash = await timeVault.write.deposit({
        account: owner.account,
        value: depositAmount,
      });

      const receipt = await viem.getPublicClient().waitForTransactionReceipt({ hash });
      expect(receipt.status).to.equal("success");
      expect(await timeVault.read.balance()).to.equal(depositAmount);
    });

    it("Should revert if non-owner tries to deposit", async function () {
      const depositAmount = parseEther("1");

      await expect(
        timeVault.write.deposit({
          account: user1.account,
          value: depositAmount,
        })
      ).to.be.rejectedWith("TimeVault__NotOwner");
    });

    it("Should revert with zero deposit amount", async function () {
      await expect(
        timeVault.write.deposit({
          account: owner.account,
          value: 0n,
        })
      ).to.be.rejectedWith("TimeVault__ZeroAmount");
    });

    it("Should mark goal as reached when deposit meets goal", async function () {
      await timeVault.write.deposit({
        account: owner.account,
        value: goalAmount,
      });

      expect(await timeVault.read.goalReached()).to.be.true;
    });

    it("Should accept deposits via receive function", async function () {
      const depositAmount = parseEther("1");

      const hash = await owner.sendTransaction({
        to: timeVault.address,
        value: depositAmount,
      });

      const receipt = await viem.getPublicClient().waitForTransactionReceipt({ hash });
      expect(receipt.status).to.equal("success");
      expect(await timeVault.read.balance()).to.equal(depositAmount);
    });

    it("Should revert receive from non-owner", async function () {
      const depositAmount = parseEther("1");

      await expect(
        user1.sendTransaction({
          to: timeVault.address,
          value: depositAmount,
        })
      ).to.be.rejectedWith("TimeVault__NotOwner");
    });

    it("Should emit VaultDeposit event", async function () {
      const depositAmount = parseEther("1");

      const hash = await timeVault.write.deposit({
        account: owner.account,
        value: depositAmount,
      });

      const receipt = await viem.getPublicClient().waitForTransactionReceipt({ hash });
      const logs = await viem.getPublicClient().getLogs({
        address: timeVault.address,
        fromBlock: receipt.blockNumber,
        toBlock: receipt.blockNumber,
      });

      expect(logs).to.have.length.greaterThan(0);
    });
  });

  describe("Withdrawals", function () {
    beforeEach(async function () {
      // Deposit some funds first
      await timeVault.write.deposit({
        account: owner.account,
        value: parseEther("1"),
      });
    });

    it("Should revert withdrawal before unlock time", async function () {
      const withdrawAmount = parseEther("0.5");

      await expect(
        timeVault.write.withdraw([withdrawAmount], {
          account: owner.account,
        })
      ).to.be.rejectedWith("TimeVault__VaultLocked");
    });

    it("Should allow withdrawal when goal is reached", async function () {
      // Deposit more to reach goal
      await timeVault.write.deposit({
        account: owner.account,
        value: parseEther("1"),
      });

      const withdrawAmount = parseEther("0.5");
      const initialBalance = await viem.getPublicClient().getBalance({
        address: owner.account.address,
      });

      const hash = await timeVault.write.withdraw([withdrawAmount], {
        account: owner.account,
      });

      const receipt = await viem.getPublicClient().waitForTransactionReceipt({ hash });
      expect(receipt.status).to.equal("success");
      expect(await timeVault.read.balance()).to.equal(parseEther("1.5"));
    });

    it("Should revert if non-owner tries to withdraw", async function () {
      // Make goal reached
      await timeVault.write.deposit({
        account: owner.account,
        value: parseEther("1"),
      });

      const withdrawAmount = parseEther("0.5");

      await expect(
        timeVault.write.withdraw([withdrawAmount], {
          account: user1.account,
        })
      ).to.be.rejectedWith("TimeVault__NotOwner");
    });

    it("Should revert with zero withdrawal amount", async function () {
      // Make goal reached
      await timeVault.write.deposit({
        account: owner.account,
        value: parseEther("1"),
      });

      await expect(
        timeVault.write.withdraw([0n], {
          account: owner.account,
        })
      ).to.be.rejectedWith("TimeVault__ZeroAmount");
    });

    it("Should revert if withdrawal amount exceeds balance", async function () {
      // Make goal reached
      await timeVault.write.deposit({
        account: owner.account,
        value: parseEther("1"),
      });

      const withdrawAmount = parseEther("3");

      await expect(
        timeVault.write.withdraw([withdrawAmount], {
          account: owner.account,
        })
      ).to.be.rejectedWith("TimeVault__InsufficientBalance");
    });
  });

  describe("Emergency Withdrawal", function () {
    beforeEach(async function () {
      // Deposit some funds and enable emergency withdrawal
      await timeVault.write.deposit({
        account: owner.account,
        value: parseEther("1"),
      });
      
      await timeVault.write.enableEmergencyWithdrawal({
        account: owner.account,
      });
    });

    it("Should allow emergency withdrawal with penalty", async function () {
      const initialBalance = await viem.getPublicClient().getBalance({
        address: owner.account.address,
      });

      const hash = await timeVault.write.emergencyWithdraw({
        account: owner.account,
      });

      const receipt = await viem.getPublicClient().waitForTransactionReceipt({ hash });
      expect(receipt.status).to.equal("success");
      expect(await timeVault.read.balance()).to.equal(0n);
    });

    it("Should revert emergency withdrawal if not enabled", async function () {
      // Deploy new vault without enabling emergency withdrawal
      const newVault = await viem.deployContract("TimeVault", [
        vaultName,
        unlockTime,
        goalAmount,
        owner.account.address,
        protocolFee,
      ]);

      await newVault.write.deposit({
        account: owner.account,
        value: parseEther("1"),
      });

      await expect(
        newVault.write.emergencyWithdraw({
          account: owner.account,
        })
      ).to.be.rejectedWith("TimeVault__EmergencyNotEnabled");
    });

    it("Should revert if non-owner tries emergency withdrawal", async function () {
      await expect(
        timeVault.write.emergencyWithdraw({
          account: user1.account,
        })
      ).to.be.rejectedWith("TimeVault__NotOwner");
    });

    it("Should emit EmergencyWithdrawal event", async function () {
      const hash = await timeVault.write.emergencyWithdraw({
        account: owner.account,
      });

      const receipt = await viem.getPublicClient().waitForTransactionReceipt({ hash });
      const logs = await viem.getPublicClient().getLogs({
        address: timeVault.address,
        fromBlock: receipt.blockNumber,
        toBlock: receipt.blockNumber,
      });

      expect(logs).to.have.length.greaterThan(0);
    });
  });

  describe("Emergency Withdrawal Enable", function () {
    it("Should allow owner to enable emergency withdrawal", async function () {
      const hash = await timeVault.write.enableEmergencyWithdrawal({
        account: owner.account,
      });

      const receipt = await viem.getPublicClient().waitForTransactionReceipt({ hash });
      expect(receipt.status).to.equal("success");
      expect(await timeVault.read.emergencyWithdrawalEnabled()).to.be.true;
    });

    it("Should revert if non-owner tries to enable emergency withdrawal", async function () {
      await expect(
        timeVault.write.enableEmergencyWithdrawal({
          account: user1.account,
        })
      ).to.be.rejectedWith("TimeVault__NotOwner");
    });

    it("Should emit EmergencyWithdrawalEnabled event", async function () {
      const hash = await timeVault.write.enableEmergencyWithdrawal({
        account: owner.account,
      });

      const receipt = await viem.getPublicClient().waitForTransactionReceipt({ hash });
      const logs = await viem.getPublicClient().getLogs({
        address: timeVault.address,
        fromBlock: receipt.blockNumber,
        toBlock: receipt.blockNumber,
      });

      expect(logs).to.have.length.greaterThan(0);
    });
  });

  describe("View Functions", function () {
    beforeEach(async function () {
      await timeVault.write.deposit({
        account: owner.account,
        value: parseEther("1.5"),
      });
    });

    it("Should return correct vault info", async function () {
      const vaultInfo = await timeVault.read.getVaultInfo();

      expect(vaultInfo[0]).to.equal(vaultName); // name
      expect(vaultInfo[1]).to.equal(unlockTime); // unlockTime
      expect(vaultInfo[2]).to.equal(goalAmount); // goalAmount
      expect(vaultInfo[3]).to.equal(getAddress(owner.account.address)); // owner
      expect(vaultInfo[4]).to.equal(parseEther("1.5")); // balance
      expect(vaultInfo[5]).to.be.false; // goalReached
      expect(vaultInfo[6]).to.be.false; // emergencyEnabled
    });

    it("Should show goal reached when balance meets goal", async function () {
      await timeVault.write.deposit({
        account: owner.account,
        value: parseEther("0.5"),
      });

      const vaultInfo = await timeVault.read.getVaultInfo();
      expect(vaultInfo[5]).to.be.true; // goalReached
    });
  });
});
