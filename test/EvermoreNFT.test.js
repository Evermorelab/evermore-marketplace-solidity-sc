const { expect } = require("chai");
require("chai").use(require("chai-as-promised"));



describe("EvermoreNFT", function () {
  const ITEM_SUPPLY = 100;
  const BASE_URI="ipfs://QmQ1X";
  const BASE_UID= "MERCH-RED-COT-L-923";
  const TOKEN_ID = 1;
  const MANAGER_ROLE = ethers.utils.id("MANAGER");
  const ADMIN_ROLE = ethers.utils.id("ADMIN");

  beforeEach(async function (init_with_lock=false) {
    // deploy marketplace
    const Marketplace = await ethers.getContractFactory("EvermoreMarketplace");
    marketplace = await Marketplace.deploy();
    await marketplace.deployed();
    this.marketplaceAddress = marketplace.address;
    // deploy NFT
    [owner, other] = await ethers.getSigners();
    this.owner = owner;
    this.other = other;
    const EvermoreNFT = await ethers.getContractFactory("EvermoreNFT");
    evermoreNFT = await EvermoreNFT.connect(owner).deploy(this.marketplaceAddress, ITEM_SUPPLY, BASE_UID, init_with_lock);
    await evermoreNFT.deployed();
    await evermoreNFT.connect(this.owner).setBaseURI(BASE_URI);
  });

  it("should be able to lock NFT as MANAGER", async function () {
    await evermoreNFT.connect(this.owner).grantRole(MANAGER_ROLE, other.address);
    await evermoreNFT.connect(this.other).lockNFT(TOKEN_ID);
    const isLocked = await evermoreNFT.isLocked(TOKEN_ID);
    expect(isLocked).to.be.true;
  });

  it("should not be able to lock NFT as NON-MANAGER", async function () {
    await expect(
      evermoreNFT.connect(this.other).lockNFT(TOKEN_ID)
    ).to.be.rejectedWith(/is missing role/i);
  });

  it("should be able to unlock NFT as MANAGER", async function () {
    await evermoreNFT.connect(this.owner).grantRole(MANAGER_ROLE, other.address);
    await evermoreNFT.connect(this.other).lockNFT(TOKEN_ID);
    await evermoreNFT.connect(this.other).unlockNFT(TOKEN_ID);
    const isLocked = await evermoreNFT.isLocked(TOKEN_ID);
    expect(isLocked).to.be.false;
  });

  it("should not be able to unlock NFT as NON-MANAGER", async function () {
    await evermoreNFT.connect(this.owner).lockNFT(TOKEN_ID);
    await expect(
      evermoreNFT.connect(this.other).unlockNFT(TOKEN_ID)
    ).to.be.rejectedWith(/is missing role/i);
  });

  it("should not be able to claim an NFT if tokenId higher than supply", async function () {
    await expect(
      evermoreNFT.connect(this.owner).claim(this.other.address, ITEM_SUPPLY+1)
    ).to.be.rejectedWith(/Token ID is greater than supply/i);
  });

  it("should register a new NFT in the marketplace by default", async function () {
    const registerMarketplace = await evermoreNFT.shouldRegisterMarketplace();
    expect(registerMarketplace).to.equal(true);
  });

  it("should be able to claim an NFT if tokenId is not claimed", async function () {
    const [minter] = await ethers.getSigners();
    await evermoreNFT.claim(minter.address, TOKEN_ID);
    const owner = await evermoreNFT.ownerOf(TOKEN_ID);
    expect(owner).to.equal(minter.address);
  });

  it("should not be able to claim an NFT if tokenId is already claimed", async function () {
    const [minter1, minter2] = await ethers.getSigners();
    await evermoreNFT.claim(minter1.address, TOKEN_ID);
    await expect(
      evermoreNFT.claim(minter2.address, TOKEN_ID)
    ).to.be.rejectedWith(/ERC721: token already minted/i);
  });

  it("should not be able to claim an NFT if tokenId is locked", async function () {
    const [minter] = await ethers.getSigners();
    await evermoreNFT.connect(this.owner).lockNFT(TOKEN_ID);
    await expect(
      evermoreNFT.claim(minter.address, TOKEN_ID)
    ).to.be.rejectedWith(/ERC721Lockable: Token is locked/i);
  });

  it("should by able to update the supply as admin", async function () {
    await evermoreNFT.connect(this.owner).grantRole(ADMIN_ROLE, this.other.address);
    const newSupply = ITEM_SUPPLY+5;
    await evermoreNFT.connect(this.other).setItemSupply(newSupply);
    const supply = await evermoreNFT.itemSupply();
    expect(supply.toString()).to.equal(newSupply.toString());
  });

  it("should not be able to update the supply as non-admin", async function () {
    const newSupply = ITEM_SUPPLY+5;
    await expect(
      evermoreNFT.connect(this.other).setItemSupply(newSupply)
    ).to.be.rejectedWith(/is missing role/i);
    await evermoreNFT.connect(this.owner).grantRole(MANAGER_ROLE, other.address);
    await expect(
      evermoreNFT.connect(this.other).setItemSupply(newSupply)
    ).to.be.rejectedWith(/is missing role/i);
    const supply = await evermoreNFT.itemSupply();
    expect(supply.toString()).to.equal(ITEM_SUPPLY.toString());
  });

  it("should not be able to update the marketplace adderss as non-admin", async function () {
    await expect(
      evermoreNFT.connect(this.other).setMarketplaceAddress(this.other.address)
    ).to.be.rejectedWith(/is missing role/i);
    await evermoreNFT.connect(this.owner).grantRole(MANAGER_ROLE, this.other.address);
    await expect(
      evermoreNFT.connect(this.other).setMarketplaceAddress(this.other.address)
    ).to.be.rejectedWith(/is missing role/i);
    const marketplaceAddress = await evermoreNFT.marketplaceAddress();
    expect(marketplaceAddress).to.equal(this.marketplaceAddress);
  });

  it("should be able to update the marketplace address as admin", async function () {
    await evermoreNFT.connect(this.owner).grantRole(ADMIN_ROLE, this.other.address);
    await evermoreNFT.connect(this.other).setMarketplaceAddress(this.other.address);
    const marketplaceAddress = await evermoreNFT.marketplaceAddress();
    expect(marketplaceAddress).to.equal(this.other.address);
  });

  it("should not be able to update the baseUID as non-admin", async function () {
    const newBaseUID = "123";
    await expect(
      evermoreNFT.connect(this.other).setBaseUID(newBaseUID)
    ).to.be.rejectedWith(/is missing role/i);
    await evermoreNFT.connect(this.owner).grantRole(MANAGER_ROLE, this.other.address);
    await expect(
      evermoreNFT.connect(this.other).setBaseUID(newBaseUID)
    ).to.be.rejectedWith(/is missing role/i);
    const baseUID = await evermoreNFT.baseUID();
    expect(baseUID).to.equal(BASE_UID);
  });

  it("should be able to update the baseUID as admin", async function () {
    const newBaseUID = "123";
    await evermoreNFT.connect(this.owner).grantRole(ADMIN_ROLE, this.other.address);
    await evermoreNFT.connect(this.other).setBaseUID(newBaseUID);
    const baseUID = await evermoreNFT.baseUID();
    expect(baseUID).to.equal(newBaseUID);
  });

  it("should not be able to update the baseURI as non-admin", async function () {
    const newBaseURI = "123";
    await expect(
      evermoreNFT.connect(this.other).setBaseURI(newBaseURI)
    ).to.be.rejectedWith(/is missing role/i);
    await evermoreNFT.connect(this.owner).grantRole(MANAGER_ROLE, this.other.address);
    await expect(
      evermoreNFT.connect(this.other).setBaseURI(newBaseURI)
    ).to.be.rejectedWith(/is missing role/i);
    const baseURI = await evermoreNFT.baseURI();
    expect(baseURI).to.equal(BASE_URI);
  });

  it("should be able to update the baseURI as admin", async function () {
    const newBaseURI = "123";
    await evermoreNFT.connect(this.owner).grantRole(ADMIN_ROLE, this.other.address);
    await evermoreNFT.connect(this.other).setBaseURI(newBaseURI);
    const baseURI = await evermoreNFT.baseURI();
    expect(baseURI).to.equal(newBaseURI);
  });

  it("should not be able to update the royalties as non-admin", async function () {
    await expect(
      evermoreNFT.connect(this.other).setRoyalty(this.other.address, 10)
    ).to.be.rejectedWith(/is missing role/i);
    await evermoreNFT.connect(this.owner).grantRole(MANAGER_ROLE, this.other.address);
    await expect(
      evermoreNFT.connect(this.other).setRoyalty(this.other.address, 10)
    ).to.be.rejectedWith(/is missing role/i);
  });

  it("should be able to update the royalties as admin", async function () {
    const newRoyaltyPerc = 10;
    const newRoyalty = newRoyaltyPerc*100;
    const [minter] = await ethers.getSigners();
    await evermoreNFT.connect(this.owner).grantRole(ADMIN_ROLE, this.other.address);
    await evermoreNFT.connect(this.other).setRoyalty(this.other.address, newRoyalty);
    await evermoreNFT.claim(minter.address, TOKEN_ID);
    const [address, percentage] = await evermoreNFT.royaltyInfo(TOKEN_ID, 100);
    expect(address).to.equal(this.other.address);
    expect(percentage.toString()).to.equal(newRoyaltyPerc.toString());
  });

});