const { expect } = require("chai");
require("chai").use(require("chai-as-promised"));

describe("ERC721MarketplaceLink", function () {

  const TOKEN_ID = 12;
  const NULL_ADDRESS = "0x0000000000000000000000000000000000000000";

  this.beforeEach(async function () {
    // deploy marketplace
    const Marketplace = await ethers.getContractFactory("EvermoreMarketplace");
    marketplace = await Marketplace.deploy();
    await marketplace.waitForDeployment();
    this.marketplaceAddress = await marketplace.getAddress();
    // deploy NFT
    const ERC721MarketplaceLink = await ethers.getContractFactory("ERC721MarketplaceLinkMock");
    erc721MarketplaceLink = await ERC721MarketplaceLink.deploy(this.marketplaceAddress, true);
    await erc721MarketplaceLink.waitForDeployment();
    this.NFTAddress = await erc721MarketplaceLink.getAddress();
  });

  it("should return the correct marketplace address", async function () {
    expect(await erc721MarketplaceLink.marketplaceAddress()).to.equal(this.marketplaceAddress);
  });

  it("should able to update the marketplace address", async function () {
    const NEW_MARKETPLACE_ADDRESS = "0x9bB683b20181A959fE1Fad5425c4298F90c300d9";
    await erc721MarketplaceLink.setMarketplaceAddress(NEW_MARKETPLACE_ADDRESS);
    expect(await erc721MarketplaceLink.marketplaceAddress()).to.equal(NEW_MARKETPLACE_ADDRESS);
  });

  it("should register the token in the marketplace", async function () {
    const [minter] = await ethers.getSigners();
    await erc721MarketplaceLink.mint(minter.address, TOKEN_ID);
    const listing = await marketplace.getNFTListing(this.NFTAddress, TOKEN_ID);
    // listing exist and address is not zero
    expect(listing.seller).to.equal(minter.address);
  });

  it("not minted token should not be registered in the marketplace", async function () {
    const listing = await marketplace.getNFTListing(this.NFTAddress, TOKEN_ID);
    await expect(listing.seller).to.equal(NULL_ADDRESS);
  });

  it("should not register the token in the marketplace if the flag is false", async function () {
    const ERC721MarketplaceLink = await ethers.getContractFactory("ERC721MarketplaceLinkMock");
    erc721MarketplaceLink = await ERC721MarketplaceLink.deploy(this.marketplaceAddress, false);
    await erc721MarketplaceLink.waitForDeployment();
    const NFTAddress = await erc721MarketplaceLink.getAddress();
    const [minter] = await ethers.getSigners();
    await erc721MarketplaceLink.mint(minter.address, TOKEN_ID);
    const listing = await marketplace.getNFTListing(NFTAddress, TOKEN_ID);
    await expect(listing.seller).to.equal(NULL_ADDRESS);
  });

  it("should be approved for the marketplace after a NFT is minted", async function () {
    const [minter] = await ethers.getSigners();
    await erc721MarketplaceLink.mint(minter.address, TOKEN_ID);
    const approvedForAll = await erc721MarketplaceLink.isApprovedForAll(minter.address, this.marketplaceAddress);
    expect(approvedForAll).to.equal(true);
  });

});
