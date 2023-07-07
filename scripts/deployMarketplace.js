const PRICE0 = ethers.parseEther(process.env.PRICE);
const nbCollectionItems = process.env.QUANTITY;

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const marketplaceFactory = await ethers.getContractFactory("EvermoreMarketplace");
  const marketplace = await marketplaceFactory.deploy();
  await marketplace.waitForDeployment();
  const marketplaceAddress = await marketplace.getAddress();

  console.log("marketplace address:", marketplaceAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });