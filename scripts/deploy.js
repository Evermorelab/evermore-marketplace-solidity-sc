const PRICE0 = ethers.utils.parseEther("0.6")
const nbCollectionItems = 1000

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());


  const marketplaceFactory = await ethers.getContractFactory("EvermoreMarketplace")
  const marketplace = await marketplaceFactory.deploy()
  await marketplace.deployed()

  const evermoreNFTFactory = await ethers.getContractFactory("EvermoreNFT")
  const evermoreNFT = await evermoreNFTFactory.deploy(marketplace.address, PRICE0, nbCollectionItems)
  await evermoreNFT.deployed()

  console.log("marketplace address:", marketplace.address);
  console.log("evermoreNFT address:", evermoreNFT.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });