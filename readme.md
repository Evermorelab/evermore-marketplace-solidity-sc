# Evermore marketplace

This is a project that uses [Hardhat](https://hardhat.org/) to develop and deploy smart contracts on the Ethereum blockchain.

It contains 2 smart contracts:
- EvermoreNFT: to mint new NFTs
- EvermoreMarketplace: to buy and sell NFTs

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
2. Run `npx hardhat run scripts/deployMarketplace.js --network alfajores` to deploy the Marketplace on the Alfajores testnet. The Marketplace contract address will be displayed in the console after deployment. Keep it, you will need it for the next step.

3. Run `npx hardhat run scripts/deploySignatureLibrary.js --network alfajores` to deploy the Library on the Alfajores testnet. The Library contract address will be displayed in the console after deployment. Keep it, you will need it for the next step.

4. Update the collection initial variables in the .env file:
```
 # the address of the deployed Marketplace
MARKETPLACE_ADDRESS="0x36042AA54644ABc270c490EdA913d20F85a3A7F2"
# the address of the deployed Signature Library
SIGNATURE_LIBRARY_ADDRESS=
# Contract owner address
OWNER_ADDRESS=""
QUANTITY=100
BASE_URI="https://ipfs.io/ipfs/"
BASE_UID=""
ROYALTIES_ADDRESS=""
```

4. Run `npx hardhat run scripts/deployCollection.js --network alfajores` for each NFT collection you want to deploy. Make sure you add the deployed address into the products Database. Make sure you setup the correct values in .env before each deployment.
