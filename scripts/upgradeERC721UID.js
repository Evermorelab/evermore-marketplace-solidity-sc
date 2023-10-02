const { Wallet } = require('ethers');

CONTRACT_ADDRESS = '0x7Be366CFa4457a2CFFd7906d0be2E234dbd92aD6';

async function main() {

  // Create a new wallet instance from the private key
  const privateKey = process.env.METAMASK_PRIVATE_KEY;
  const deployerWallet = new Wallet(privateKey);

  // Deploy the contract
  const contractFactory = await ethers.getContractFactory("ERC721UIDUpgradeable");
  const contract = await upgrades.upgradeProxy(CONTRACT_ADDRESS, contractFactory, ['0x544e2ef46982003EE58404aF1a6A744133E51874', 'CLOTHIER'], { signer: deployerWallet });
  await contract.deployed();
  const contractAddress = contract.address;
  console.log("Contract deployed to:", contractAddress);
}

main()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error);
  process.exit(1);
});