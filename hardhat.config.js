/** @type import('hardhat/config').HardhatUserConfig */

require("@nomiclabs/hardhat-ethers");
require("dotenv").config();
require('solidity-coverage');
require("hardhat-gas-reporter");


const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY;
const METAMASK_PRIVATE_KEY = process.env.METAMASK_PRIVATE_KEY;


module.exports = {
  solidity: "0.8.19",
  settings: {
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
  networks: {
    goerli: {
      url: `https://eth-goerli.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
      accounts: [METAMASK_PRIVATE_KEY]
    },
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
      accounts: [METAMASK_PRIVATE_KEY],
    },
    polygon_mumbai: {
      url: "https://rpc-mumbai.maticvigil.com",
      accounts: [METAMASK_PRIVATE_KEY]
    },
    alfajores: {
      url: "https://alfajores-forno.celo-testnet.org",
      accounts: [METAMASK_PRIVATE_KEY],
      chainId: 44787
    },
  },
};
