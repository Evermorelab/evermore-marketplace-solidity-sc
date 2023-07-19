const PRICE0 = ethers.utils.parseEther(process.env.PRICE);
const nbCollectionItems = process.env.QUANTITY;

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const libraryFactory = await ethers.getContractFactory("SignatureLibrary");
  const library = await libraryFactory.deploy();
  await library.deployed();
  const libraryAddress = await library.address;

  console.log("library address:", libraryAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });