module.exports = {
  networks: {
    // Configuration for Tron testnet (Shasta Testnet)
    shasta: {
      privateKey: process.env.PRIVATE_KEY, // Store your private key in an environment variable for security
      consume_user_resource_percent: 30,  // Max resource consumption percentage
      fee_limit: 1000000000,  // Max TRX fee limit
      fullHost: "https://api.shasta.trongrid.io",  // Shasta Testnet
      network_id: "*",  // Match any network id
    },

    // Configuration for Tron mainnet
    mainnet: {
      privateKey: process.env.PRIVATE_KEY,  // Store your private key in an environment variable for security
      consume_user_resource_percent: 30,  // Max resource consumption percentage
      fee_limit: 1000000000,  // Max TRX fee limit
      fullHost: "https://api.trongrid.io",  // Tron Mainnet
      network_id: "*",  // Match any network id
    },
  },

  // Compiler configuration for Solidity
  solc: {
    version: "0.8.18",  // Specify the Solidity version you're using
    optimizer: {
      enabled: true,  // Enable Solidity optimizer
      runs: 200,  // Number of optimization runs
    },
  },

  // Custom paths for contracts and build files
  paths: {
    sources: "./contracts",  // Path to your smart contracts
    tests: "./test",  // Path to your test scripts
    artifacts: "./build/contracts",  // Path to your compiled contract artifacts
  },
};

