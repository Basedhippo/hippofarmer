// Import necessary dependencies for Tron
const TronWeb = require('tronweb').default || require('tronweb');
const fs = require('fs');
const path = require('path');
require('dotenv').config(); // Load environment variables

// Tron testnet configuration (Nile Testnet)
const fullHost = 'https://nile.trongrid.io';
const privateKey = process.env.PRIVATE_KEY; // Load private key from .env file

// Ensure TronWeb is instantiated correctly
const tronWeb =tronWeb({
  fullHost: fullHost,
  privateKey: privateKey,
});

// Path to compiled contract JSON (ensure this path is correct)
const compiledContract = require(path.join(__dirname, '../build/contracts/HippoBreeds.json'));

// Deployment function
async function deployContract() {
  try {
    console.log('Deploying HippoBreeds contract to Tron testnet...');

    const abi = compiledContract.abi;
    const bytecode = compiledContract.bytecode;

    // Deploy the contract
    const contractInstance = await tronWeb.contract().new({
      abi,
      bytecode,
      feeLimit: 100_000_000,  // Set a fee limit of 100 TRX for deployment
      callValue: 0,  // No TRX sent along with the transaction
      userFeePercentage: 1,  // Energy usage fees
      originEnergyLimit: 10_000_000  // Limit for the energy consumption
    });

    // Contract deployed successfully
    console.log('Contract deployed successfully!');
    console.log('Contract Address:', contractInstance.address);

    // Write contract address to a JSON file in the abis directory
    const contractAddress = {
      address: contractInstance.address,
    };

    fs.writeFileSync(path.join(__dirname, '../src/abis/contractAddress.json'), JSON.stringify(contractAddress, null, 2));
    console.log('Contract address saved to src/abis/contractAddress.json');
  } catch (error) {
    console.error('Error deploying contract:', error.message);
    process.exit(1);
  }
}

// Execute the deployment
deployContract();
