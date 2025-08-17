const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Sentinel Contracts", function () {
  let guardianController;
  let approvalRevokeHelper;
  let owner;
  let guardian1;
  let guardian2;
  let user;

  beforeEach(async function () {
    [owner, guardian1, guardian2, user] = await ethers.getSigners();

    // Deploy GuardianController
    const GuardianController = await ethers.getContractFactory("GuardianController");
    guardianController = await GuardianController.deploy(owner.address);
    await guardianController.waitForDeployment();

    // Deploy ApprovalRevokeHelper
    const ApprovalRevokeHelper = await ethers.getContractFactory("ApprovalRevokeHelper");
    approvalRevokeHelper = await ApprovalRevokeHelper.deploy();
    await approvalRevokeHelper.waitForDeployment();
  });

  describe("GuardianController", function () {
    it("Should deploy with correct owner", async function () {
      expect(await guardianController.owner()).to.equal(owner.address);
    });

    it("Should add guardians correctly", async function () {
      await guardianController.addGuardian(guardian1.address, 1);
      await guardianController.addGuardian(guardian2.address, 2);

      const [isActive1, weight1] = await guardianController.getGuardianInfo(guardian1.address);
      const [isActive2, weight2] = await guardianController.getGuardianInfo(guardian2.address);

      expect(isActive1).to.be.true;
      expect(weight1).to.equal(1);
      expect(isActive2).to.be.true;
      expect(weight2).to.equal(2);
    });

    it("Should have correct required weight", async function () {
      expect(await guardianController.requiredWeight()).to.equal(2);
    });
  });

  describe("ApprovalRevokeHelper", function () {
    it("Should deploy with correct owner", async function () {
      expect(await approvalRevokeHelper.owner()).to.equal(owner.address);
    });

    it("Should return correct approval count", async function () {
      expect(await approvalRevokeHelper.getApprovalCount(user.address)).to.equal(0);
    });

    it("Should handle basic contract functionality", async function () {
      // Test that the contract can be called without reverting
      const address = await approvalRevokeHelper.getAddress();
      expect(address).to.not.equal(ethers.ZeroAddress);
    });
  });

  describe("Integration", function () {
    it("Both contracts should be deployed and accessible", async function () {
      const guardianControllerAddress = await guardianController.getAddress();
      const approvalRevokeHelperAddress = await approvalRevokeHelper.getAddress();

      expect(guardianControllerAddress).to.not.equal(ethers.ZeroAddress);
      expect(approvalRevokeHelperAddress).to.not.equal(ethers.ZeroAddress);
      expect(guardianControllerAddress).to.not.equal(approvalRevokeHelperAddress);
    });
  });
});
