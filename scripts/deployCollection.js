const PRICE0 = ethers.utils.parseEther(process.env.PRICE);
const nbCollectionItems = process.env.QUANTITY;
const defautMarketplaceAddress = process.env.MARKETPLACE_ADDRESS;

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const evermoreNFTFactory = await ethers.getContractFactory("EvermoreNFT")
  const evermoreNFT = await evermoreNFTFactory.deploy(defautMarketplaceAddress, PRICE0, nbCollectionItems)
  await evermoreNFT.deployed()

  console.log("marketplace address:", defautMarketplaceAddress);
  console.log("evermoreNFT address:", evermoreNFT.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });