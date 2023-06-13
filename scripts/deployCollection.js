const PRICE0 = ethers.utils.parseEther(process.env.PRICE);
const nbCollectionItems = process.env.QUANTITY;
const defautMarketplaceAddress = process.env.MARKETPLACE_ADDRESS;
const baseURI = process.env.BASE_URI;
const baseUID = process.env.BASE_UID;
const royaltiesAddress = process.env.ROYALTIES_ADDRESS;

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const evermoreNFTFactory = await ethers.getContractFactory("EvermoreNFT")
  const evermoreNFT = await evermoreNFTFactory.connect(deployer).deploy(defautMarketplaceAddress, nbCollectionItems, baseUID, false)
  await evermoreNFT.deployed()
  if (baseURI) {
    await evermoreNFT.setbaseURI(baseURI)
  }
  await evermoreNFT.setRoyalty(10, royaltiesAddress)

  console.log("marketplace address:", defautMarketplaceAddress);
  console.log("evermoreNFT address:", evermoreNFT.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });