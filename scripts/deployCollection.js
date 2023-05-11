const PRICE0 = ethers.utils.parseEther(process.env.PRICE);
const nbCollectionItems = process.env.QUANTITY;
const defautMarketplaceAddress = process.env.MARKETPLACE_ADDRESS;
const baseURI = process.env.BASE_URI;
const baseUID = process.env.BASE_UID;
const deployerAddress = process.env.DEPLOYER_ADDRESS;

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const evermoreNFTFactory = await ethers.getContractFactory("EvermoreNFT")
  const evermoreNFT = await evermoreNFTFactory.deploy(defautMarketplaceAddress, PRICE0, nbCollectionItems, baseUID)
  await evermoreNFT.deployed()
  if (baseURI) {
    await evermoreNFT.setbaseURI(baseURI)
  }

  console.log("marketplace address:", defautMarketplaceAddress);
  console.log("evermoreNFT address:", evermoreNFT.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });