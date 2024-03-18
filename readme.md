# Evermore marketplace

This is a project that uses [Hardhat](https://hardhat.org/) to develop and deploy smart contracts.

It contains 2 main contracts:
- Evermore NFT to create and manage NFTs: contracts/upgradeable/EvermoreNFTUpgradeable.sol (depends on other contracts in contracts/upgradeable)
- Evermore Marketplace to buy and sell NFTs on a secondary market: contracts/Marketplace.sol

## Prerequisites

To work with this project, you will need to have the following software installed on your computer:

- [Node.js](https://nodejs.org/)
- [npm](https://www.npmjs.com/) (comes with Node.js)
- [Hardhat](https://hardhat.org/)

## Setup

To set up the project, follow these steps:

Install the dependencies:
```
npm install
```

## Dev
After each change in your smart contracts, re-compile them using: `npx hardhat compile`

You can run the test script with: `npm run script`

## Deploy

Deploy on testnet:
1. Set the variables in a .env file:
```
# your wallet private key
METAMASK_PRIVATE_KEY=""
# your Alchemy API key
ALCHEMY_API_KEY=""
```
2. Run `npx hardhat run scripts/deployMarketplace.js --network polygon_mumbai` to deploy the Marketplace on the Alfajores testnet. The Marketplace contract address will be displayed in the console after deployment. Keep it, you will need it for the next step.

3. Update the collection initial variables in the .env file:
```
# Contract owner address
OWNER_ADDRESS=""
BASE_UID=""
ROYALTIES_ADDRESS=""
```

4. Run `npx hardhat run scripts/deployNFTUpgradable.js --network polygon_mumbai` for each NFT collection you want to deploy. Make sure you add the deployed address into the products Database. Make sure you setup the correct values in .env before each deployment.

5.  Run `npx hardhat run scripts/deployNFTUpgradable.js --network polygon` to deploy the NFT collection on the Polygon mainnet. The NFT collection contract address will be displayed in the console after deployment. Keep it, you will need it for the next step.
