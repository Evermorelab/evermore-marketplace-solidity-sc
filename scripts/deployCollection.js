const PRICE0 = ethers.parseEther(process.env.PRICE);
const nbCollectionItems = process.env.QUANTITY;
const defautMarketplaceAddress = process.env.MARKETPLACE_ADDRESS;
const baseURI = process.env.BASE_URI;
const baseUID = process.env.BASE_UID;
const royaltiesAddress = process.env.ROYALTIES_ADDRESS;
const signatureAddress = process.env.SIGNATURE_LIBRARY_ADDRESS;

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const evermoreNFTFactory = await ethers.getContractFactory( "EvermoreNFT", {
    libraries: {
      SignatureLibrary: signatureAddress,
    },
  });
  const evermoreNFT = await evermoreNFTFactory.connect(deployer).deploy(defautMarketplaceAddress, nbCollectionItems, baseUID, false);
  await evermoreNFT.waitForDeployment();
  if (baseURI) {
    await evermoreNFT.setbaseURI(baseURI);
  }
  await evermoreNFT.setRoyalty(royaltiesAddress, 1000); // 10% royalties
  const evermoreNFTAddress = await evermoreNFT.getAddress();

  console.log("marketplace address:", defautMarketplaceAddress);
  console.log("evermoreNFT address:", evermoreNFTAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });