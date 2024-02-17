/** @type import('hardhat/config').HardhatUserConfig */

require("@nomiclabs/hardhat-ethers");
require("hardhat-contract-sizer");
require("dotenv").config();
require('solidity-coverage');
require("hardhat-gas-reporter");
require('@openzeppelin/hardhat-upgrades');
require("@nomiclabs/hardhat-etherscan");

const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY;
const METAMASK_PRIVATE_KEY = process.env.METAMASK_PRIVATE_KEY;


module.exports = {
  solidity: {
    compilers: [
      {
        version: `0.8.21`,
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          },
          evmVersion: `paris`
        }
      },
    ],
  },
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
    only: ['EvermoreNFT', 'EvermoreNFTUpgradeable', 'ERC721UID', 'HistoryStorage', 'Marketplace'],
  },
  etherscan: {
    apiKey: process.env.POLYGONSCAN_API_KEY,
  },
  networks: {
    goerli: {
      url: `https://eth-goerli.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
      accounts: [METAMASK_PRIVATE_KEY]
    },
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_TESTNET_API_KEY}`,
      accounts: [METAMASK_PRIVATE_KEY],
    },
    polygon_mumbai: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY_MUMBAI}`,
      accounts: [METAMASK_PRIVATE_KEY]
    },
    alfajores: {
      url: "https://alfajores-forno.celo-testnet.org",
      accounts: [METAMASK_PRIVATE_KEY],
      chainId: 44787
    },
    polygon: {
      url: `https://polygon-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY_POLYGON}`,
      accounts: [METAMASK_PRIVATE_KEY]
    },
  },
};
