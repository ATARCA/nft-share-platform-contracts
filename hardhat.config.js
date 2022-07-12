require("dotenv").config();
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require('@typechain/hardhat')
require('@nomiclabs/hardhat-ethers')
require('@nomiclabs/hardhat-waffle')
require("@nomiclabs/hardhat-etherscan")
require('@openzeppelin/hardhat-upgrades')

// Go to https://www.alchemyapi.io, sign up, create
// a new App in its dashboard, and replace "KEY" with its key
const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY

// Replace this private key with your Ropsten account private key
// To export your private key from Metamask, open Metamask and
// go to Account Details > Export Private Key
// Be aware of NEVER putting real Ether into testing accounts
const ROPSTEN_PRIVATE_KEY = process.env.ROPSTEN_PRIVATE_KEY

const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.12",
  networks: {
    ropsten: {
      url: `https://eth-ropsten.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
      accounts: [`${ROPSTEN_PRIVATE_KEY}`]
    }
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: {
      ropsten: ETHERSCAN_API_KEY
    }   
  },
  gasReporter: {
    currency: 'EUR',
    gasPrice: 3,
    coinmarketcap: process.env.COINMARKETCAP_KEY,
    token: 'MATIC'
  }
};
