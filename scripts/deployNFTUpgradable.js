const { Wallet } = require('ethers');
const { ethers } = require("hardhat");
const hre = require("hardhat");

const royaltiesAddress = process.env.ROYALTIES_ADDRESS;
const signatureAddress = process.env.SIGNATURE_LIBRARY_ADDRESS;
const baseUID = process.env.BASE_UID;

async function main() {

  // Fetch the --network option used to call the script
  const networkArgIndex = process.argv.indexOf("--network");
  const networkOption = networkArgIndex !== -1 ? process.argv[networkArgIndex + 1] : "localhost";
  console.log("networkOption:", networkOption);

  if (!baseUID) {
    console.error("Please provide a valid UID");
    process.exit(1);
  }
  console.log("baseUID:", baseUID);

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

  console.log("Deploying EvermoreNFT...");
  const evermoreNFTFactory = await ethers.getContractFactory("EvermoreNFTUpgradeable");
  const evermoreNFT = await upgrades.deployProxy(evermoreNFTFactory, [], {
    signer: deployerWallet,
    initializer: "initialize"
  });
  await evermoreNFT.deployed();
  const nftAddress = evermoreNFT.address;
  console.log("evermoreNFT address:", evermoreNFT.address);
  await evermoreNFT.setRoyalty(royaltiesAddress, 1000); // 10% royalties

  console.log("Deploying An history Storage...");
  const historyStorageFactory = await ethers.getContractFactory("HistoryStorageUpgradeable");
  const historyStorage = await upgrades.deployProxy(historyStorageFactory, [nftAddress], { signer: deployerWallet });
  await historyStorage.deployed();
  const historyStorageAddress = historyStorage.address;
  console.log("historyStorage address:", historyStorageAddress);
  evermoreNFT.setHistoryStorage(historyStorageAddress);

  console.log("Deploying an UID contract...");
  const uidFactory = await ethers.getContractFactory("ERC721UIDUpgradeable");
  const uid = await upgrades.deployProxy(uidFactory, [nftAddress, baseUID], { signer: deployerWallet });
  await uid.deployed();
  const uidAddress = uid.address;
  console.log("uid address:", uidAddress);
  await evermoreNFT.setUIDContract(uidAddress);

  console.log("UID ADDRESS:", await evermoreNFT.uidContract());
  console.log("HISTORY STORAGE ADDRESS:", await evermoreNFT.historyStorage());

  console.log("\n\n\n Verifying the contracts...");

  // wait for deployment transaction confirmations and verify each contract
  await evermoreNFT.deployTransaction.wait(2);
  await hre.run("verify:verify", {
    address: nftAddress,
    network: networkOption
  });

  await historyStorage.deployTransaction.wait(2);
  await hre.run("verify:verify", {
    address: historyStorageAddress,
    network: networkOption
  });

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