require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config({ path: require('path').resolve(__dirname, '../.env') });

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true,
    },
  },
  networks: {
    hardhat: {
      chainId: 1337,
    },
    zircuit: {
      url: process.env.ZIRCUIT_RPC || "https://zircuit1.publicnode.com",
      accounts: process.env.PRIVATE_KEY && process.env.PRIVATE_KEY !== "0xabc..." ? [process.env.PRIVATE_KEY] : [],
      chainId: 48899,
      gasPrice: 1000000000, // 1 gwei
    },
    zircuit_testnet: {
      url: process.env.ZIRCUIT_RPC || "https://zircuit1.publicnode.com",
      accounts: process.env.PRIVATE_KEY && process.env.PRIVATE_KEY !== "0xabc..." ? [process.env.PRIVATE_KEY] : [],
      chainId: 48899,
      gasPrice: 1000000000, // 1 gwei
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
};
