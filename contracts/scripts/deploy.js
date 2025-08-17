const hre = require("hardhat");
const fs = require('fs');
const path = require('path');

// Load environment variables from the root .env file
require("dotenv").config({ path: path.resolve(__dirname, '../../.env') });

async function main() {
  console.log("🚀 Starting Sentinel contracts deployment on Zircuit...");

  // Get the contract factories
  const GuardianController = await hre.ethers.getContractFactory("GuardianController");
  const ApprovalRevokeHelper = await hre.ethers.getContractFactory("ApprovalRevokeHelper");

  // Get deployer account
  const [deployer] = await hre.ethers.getSigners();
  console.log("📝 Deploying contracts with account:", deployer.address);

  // Get smart account address from environment - using the new standardized name
  const smartAccountAddress = process.env.SMART_ACCOUNT_ADDR;
  if (!smartAccountAddress) {
    throw new Error("SMART_ACCOUNT_ADDR environment variable not set in root .env file");
  }
  console.log("🏦 Smart Account Address:", smartAccountAddress);

  // Deploy GuardianController
  console.log("🔐 Deploying GuardianController...");
  const guardianController = await GuardianController.deploy(smartAccountAddress);
  await guardianController.waitForDeployment();
  const guardianControllerAddress = await guardianController.getAddress();
  console.log("✅ GuardianController deployed to:", guardianControllerAddress);

  // Deploy ApprovalRevokeHelper
  console.log("🔄 Deploying ApprovalRevokeHelper...");
  const approvalRevokeHelper = await ApprovalRevokeHelper.deploy();
  await approvalRevokeHelper.waitForDeployment();
  const approvalRevokeHelperAddress = await approvalRevokeHelper.getAddress();
  console.log("✅ ApprovalRevokeHelper deployed to:", approvalRevokeHelperAddress);

  // --- Start of new automated .env update logic ---

  console.log("\n📝 Updating .env file with new contract addresses...");
  const envFilePath = path.resolve(__dirname, '../../.env');
  let envFileContent = '';

  // Create .env if it doesn't exist, by copying from .env.example
  if (!fs.existsSync(envFilePath)) {
    const exampleEnvPath = path.resolve(__dirname, '../../.env.example');
    if (fs.existsSync(exampleEnvPath)) {
        fs.copyFileSync(exampleEnvPath, envFilePath);
        console.log("Created .env file from .env.example.");
    }
  }
  
  // Read the (possibly new) .env file
  if (fs.existsSync(envFilePath)) {
    envFileContent = fs.readFileSync(envFilePath, 'utf8');
  }

  const updates = {
    GUARDIAN_CONTROLLER_ADDR: guardianControllerAddress,
    APPROVAL_REVOKE_HELPER_ADDR: approvalRevokeHelperAddress
  };

  for (const [key, value] of Object.entries(updates)) {
    // Regex to match 'KEY=...'
    const regex = new RegExp(`^${key}=.*`, 'm');
    const newEntry = `${key}=${value}`;

    if (regex.test(envFileContent)) {
      // Update existing key
      envFileContent = envFileContent.replace(regex, newEntry);
    } else {
      // Append new key
      envFileContent += `\n${newEntry}`;
    }
  }

  fs.writeFileSync(envFilePath, envFileContent.trim());
  console.log('✅ Successfully updated .env file.');

  // --- End of new automated .env update logic ---


  console.log("\n🎉 Deployment completed successfully!");

  return {
    guardianController: guardianControllerAddress,
    approvalRevokeHelper: approvalRevokeHelperAddress,
  };
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error("❌ Deployment failed:", error);
  process.exitCode = 1;
});
