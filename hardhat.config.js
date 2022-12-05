require("dotenv").config();
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require('@typechain/hardhat')
require('@nomiclabs/hardhat-ethers')
require('@nomiclabs/hardhat-waffle')
require("@nomiclabs/hardhat-etherscan")
require('@openzeppelin/hardhat-upgrades')
require('solidity-coverage')

// Go to https://www.alchemyapi.io, sign up, create
// a new App in its dashboard, and replace "KEY" with its key
const ALCHEMY_API_KEY_ETHEREUM = process.env.ALCHEMY_API_KEY_ETHEREUM
const ALCHEMY_API_KEY_POLYGON = process.env.ALCHEMY_API_KEY_POLYGON
const ALCHEMY_API_KEY_POLYGON_MAINNET = process.env.ALCHEMY_API_KEY_POLYGON_MAINNET
// Replace this private key with your Ropsten account private key
// To export your private key from Metamask, open Metamask and
// go to Account Details > Export Private Key
// Be aware of NEVER putting real Ether into testing accounts
const WALLET_PRIVATE_KEY = process.env.WALLET_PRIVATE_KEY

const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY
const POLYGONSCAN_API_KEY = process.env.POLYGONSCAN_API_KEY

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.12",
  networks: {
    goerli: {
      url: `https://eth-goerli.g.alchemy.com/v2/${ALCHEMY_API_KEY_ETHEREUM}`,
      accounts: [`0x${WALLET_PRIVATE_KEY}`],
      gasMultiplier: 1.5,
    },
    mumbai: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/${ALCHEMY_API_KEY_POLYGON}`,
      accounts: [`0x${WALLET_PRIVATE_KEY}`],
      gasMultiplier: 1.5,
    },
    polygon_mainnet: {
      url: `https://polygon-mainnet.g.alchemy.com/v2/${ALCHEMY_API_KEY_POLYGON_MAINNET}`,
      accounts: [`0x${WALLET_PRIVATE_KEY}`],
      gasMultiplier: 1.5,
    }
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: {
      goerli: ETHERSCAN_API_KEY,
      polygonMumbai: POLYGONSCAN_API_KEY,
      polygon: POLYGONSCAN_API_KEY
    }   
  },
  gasReporter: {
    currency: 'EUR',
    gasPrice: 40,
    coinmarketcap: process.env.COINMARKETCAP_KEY,
    token: 'MATIC'
  },
  plugins: ["solidity-coverage"]
};
