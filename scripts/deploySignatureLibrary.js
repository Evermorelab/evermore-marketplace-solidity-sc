const PRICE0 = ethers.parseEther(process.env.PRICE);
const nbCollectionItems = process.env.QUANTITY;

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const libraryFactory = await ethers.getContractFactory("SignatureLibrary");
  const library = await libraryFactory.deploy();
  await library.waitForDeployment();
  const libraryAddress = await library.getAddress();

  console.log("library address:", libraryAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });