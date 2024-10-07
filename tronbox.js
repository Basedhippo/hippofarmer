require('dotenv').config(); // Import and configure dotenv to use .env variables

const port = process.env.HOST_PORT || 9090;

module.exports = {
  networks: {
    mainnet: {
      privateKey: process.env.PRIVATE_KEY_MAINNET,
      userFeePercentage: 100,
      feeLimit: 1000 * 1e6,
      fullHost: 'https://api.trongrid.io',
      network_id: '1',
    },
    shasta: {
      privateKey: process.env.PRIVATE_KEY_SHASTA, // Using the private key from .env
      userFeePercentage: 50,
      feeLimit: 1000 * 1e6,
      fullHost: 'https://api.shasta.trongrid.io',
      network_id: '2',
    },
    nile: {
      privateKey: process.env.PRIVATE_KEY_NILE, // Similarly for Nile testnet
      userFeePercentage: 100,
      feeLimit: 1000 * 1e6,
      fullHost: 'https://nile.trongrid.io',
      network_id: '3',
    },
    development: {
      privateKey: '0000000000000000000000000000000000000000000000000000000000000001', // Dev network private key
      userFeePercentage: 0,
      feeLimit: 1000 * 1e6,
      fullHost: 'http://127.0.0.1:' + port,
      network_id: '9',
    },
  },
  // solc compiler settings
  solc: {
    optimizer: {
      enabled: true,
      runs: 200,
    },
    evmVersion: 'istanbul',
  },
};
