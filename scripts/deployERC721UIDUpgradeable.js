const { Wallet } = require('ethers');
const { ethers } = require("hardhat");
const hre = require("hardhat");


// EX: npx hardhat run scripts/deployERC721UIDUpgradeable.js --network polygon_mumbai

async function main() {
  // Fetch the --network option used to call the script
  const networkArgIndex = process.argv.indexOf("--network");
  const networkOption = networkArgIndex !== -1 ? process.argv[networkArgIndex + 1] : "localhost";
  console.log("networkOption:", networkOption);

  const nftAddress = process.env.NFT_ADDRESS;
  const baseUID = process.env.BASE_UID;

  if (!baseUID) {
    console.error("Please provide a valid UID");
    process.exit(1);
  }
  if (!nftAddress) {
    console.error("Please provide a valid NFT address");
    process.exit(1);
  }
  console.log("baseUID:", baseUID);
  console.log("nftAddress:", nftAddress);

  // Create a new wallet instance from the private key
  const privateKey = process.env.METAMASK_PRIVATE_KEY;
  const deployerWallet = new Wallet(privateKey);
  // print the address of the wallet
  console.log("Deploying contract with the account:", deployerWallet.address);
  // get provider
  const provider = ethers.getDefaultProvider();
  // print the network
  console.log("Network:", network.name);
  // print balance
  const balance = await provider.getBalance(deployerWallet.address);
  console.log("Balance:", ethers.utils.formatEther(balance));

  console.log("Deploying an UID contract...");
  const uidFactory = await ethers.getContractFactory("ERC721UIDUpgradeable");
  const uid = await upgrades.deployProxy(uidFactory, [nftAddress, baseUID], { signer: deployerWallet });
  await uid.deployed();
  const uidAddress = uid.address;
  console.log("uid address:", uidAddress);

  const evermoreNFT = await ethers.getContractAt("EvermoreNFTUpgradeable", nftAddress);
  await evermoreNFT.setUIDContract(uidAddress);

  await uid.deployTransaction.wait(2);
  await hre.run("verify:verify", {
    address: uidAddress,
    network: networkOption
  });

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });