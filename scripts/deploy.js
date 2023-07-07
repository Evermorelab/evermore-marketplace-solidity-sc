const PRICE0 = ethers.parseEther(process.env.PRICE);
const nbCollectionItems = process.env.QUANTITY;

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const marketplaceFactory = await ethers.getContractFactory("EvermoreMarketplace");
  const marketplace = await marketplaceFactory.deploy();
  await marketplace.waitForDeployment();
  const marketplaceAddress = await marketplace.getAddress();

  const evermoreNFTFactory = await ethers.getContractFactory("EvermoreNFT");
  const evermoreNFT = await evermoreNFTFactory.deploy(marketplaceAddress, PRICE0, nbCollectionItems, false);
  await evermoreNFT.waitForDeployment();
  const evermoreNFTAddress = await evermoreNFT.getAddress();

  console.log("marketplace address:", marketplaceAddress);
  console.log("evermoreNFT address:", evermoreNFTAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });