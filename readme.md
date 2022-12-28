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

Deploy on testnet goerli:
1. Set the variables in a .env file:
```
ALCHEMY_API_KEY=""
GOERLI_PRIVATE_KEY="" // your account private key
```
2. Run `npx hardhat run scripts/deploy.js --network goerli`


