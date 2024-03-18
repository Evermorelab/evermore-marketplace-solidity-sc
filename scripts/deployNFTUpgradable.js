const { Wallet } = require('ethers');
const { ethers } = require("hardhat");
const hre = require("hardhat");

const alchemyApiKey = process.env.ALCHEMY_API_KEY_POLYGON;
const NETWORK_TO_URL = {
  "polygon_mumbai": `https://polygon-mumbai.g.alchemy.com/v2/${alchemyApiKey}`,
  "polygon": `https://polygon-mainnet.g.alchemy.com/v2/${alchemyApiKey}`,
  "xrpl": "https://rpc-evm-sidechain.xrpl.org"
};

/* const royaltiesAddress = process.env.ROYALTIES_ADDRESS; */
const baseUID = process.env.BASE_UID;
const GAS_PRICE = ethers.utils.parseUnits("55", "gwei");

async function main() {

  // Fetch the --network option used to call the script
  const networkArgIndex = process.argv.indexOf("--network");
  const networkOption = networkArgIndex !== -1 ? process.argv[networkArgIndex + 1] : "localhost";
  // print the network
  console.log("Network:", network.name);

  // get provider
  const providerUrl = NETWORK_TO_URL[network.name];
  const provider = new ethers.providers.JsonRpcProvider(providerUrl);

  // Create a new wallet instance from the private key
  const privateKey = network.name === 'polygon' ? process.env.METAMASK_PRIVATE_KEY_MAINNET : process.env.METAMASK_PRIVATE_KEY;
  if (!privateKey) {
    throw new Error("Private key not provided in environment variables.");
  }
  const deployerWallet = new Wallet(privateKey, provider);
  console.log("Deploying contract with the account:", deployerWallet.address);
  // print balance
  const balance = await provider.getBalance(deployerWallet.address);
  console.log("Balance:", ethers.utils.formatEther(balance), "MATIC");

  // get base UID
  if (!baseUID) {
    console.error("Please provide a valid UID");
    process.exit(1);
  }
  console.log("baseUID:", baseUID);

  console.log("Deploying EvermoreNFT...");
  const evermoreNFTFactory = await ethers.getContractFactory("EvermoreNFTUpgradeable");
  const evermoreNFT = await upgrades.deployProxy(evermoreNFTFactory, [], {
    signer: deployerWallet,
    initializer: "initialize",
    gasPrice: GAS_PRICE
  });
  await evermoreNFT.deployed();
  const nftAddress = evermoreNFT.address;
  console.log("evermoreNFT address:", evermoreNFT.address);
  await evermoreNFT.deployTransaction.wait(2);
  //await evermoreNFT.setRoyalty(royaltiesAddress, 1000); // 10% royalties

  console.log("Deploying an History Storage...");
  const historyStorageFactory = await ethers.getContractFactory("HistoryStorageUpgradeable");
  const historyStorage = await upgrades.deployProxy(historyStorageFactory, [nftAddress], {
    signer: deployerWallet,
    gasPrice: GAS_PRICE
  });
  await historyStorage.deployed();
  const historyStorageAddress = historyStorage.address;
  console.log("historyStorage address:", historyStorageAddress);
  evermoreNFT.setHistoryStorage(historyStorageAddress);

  console.log("Deploying an UID contract...");
  const uidFactory = await ethers.getContractFactory("ERC721UIDUpgradeable");
  const uid = await upgrades.deployProxy(uidFactory, [nftAddress, baseUID], {
    signer: deployerWallet,
    gasPrice: GAS_PRICE
  });
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