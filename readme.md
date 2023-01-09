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

Deploy on testnet apothem:
1. Set the variables in a .env file:
```
METAMASK_PRIVATE_KEY="" // your account private key

// Values to deploy a collection
MARKETPLACE_ADDRESS="0x36042AA54644ABc270c490EdA913d20F85a3A7F2"
QUANTITY=750
PRICE="0.05"
```
2. Run `npx hardhat run scripts/deploy.js --network apothem` to deploy the Marketplace
3. Run `npx hardhat run scripts/deployCollection.js --network apothem` for each NFT collection you want to deploy. Make sure you add the deployed address into the Database. Make sure you setup the correct values in .env before deployment


