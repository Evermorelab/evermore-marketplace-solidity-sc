const { expect } = require("chai");
require("chai").use(require("chai-as-promised"));


describe("ERC721Lockable", function () {
  let erc721Lockable;
  const TOKEN_ID = 1;

  beforeEach(async function () {
    const ERC721Lockable = await ethers.getContractFactory("ERC721LockableMock");
    erc721Lockable = await ERC721Lockable.deploy(false);
    await erc721Lockable.waitForDeployment();
  });

  it("should lock NFT", async function () {
    await erc721Lockable.lockNFT(TOKEN_ID);
    const isLocked = await erc721Lockable.isLocked(TOKEN_ID);
    expect(isLocked).to.be.true;
  });

  it("should not mint locked NFT", async function () {
    const [receiver] = await ethers.getSigners();
    // Lock the NFT
    await erc721Lockable.lockNFT(TOKEN_ID);
    // Attempt to mint the locked NFT
    await expect(
      erc721Lockable.mint(receiver.address, TOKEN_ID)
    ).to.be.rejectedWith(/ERC721Lockable: Token is locked/i);
  });
  
  it("should unlock NFT", async function () {
    await erc721Lockable.lockNFT(TOKEN_ID);
    await erc721Lockable.unlockNFT(TOKEN_ID);
    const isLocked = await erc721Lockable.isLocked(TOKEN_ID);
    expect(isLocked).to.be.false;
  });

  it("should transfer unlocked NFT", async function () {
    const [receiver] = await ethers.getSigners();
    // Lock the NFT
    await erc721Lockable.lockNFT(TOKEN_ID);
    // Unlock the NFT
    await erc721Lockable.unlockNFT(TOKEN_ID);
    // Mint the unlocked NFT
    await erc721Lockable.mint(receiver.address, TOKEN_ID);
    // Expect the NFT to be minted
    const owner = await erc721Lockable.ownerOf(TOKEN_ID);
    expect(owner).to.equal(receiver.address);
  });

  it("should lock all NFTs if contract initialized with ", async function () {
    const ERC721Lockable = await ethers.getContractFactory("ERC721LockableMock");
    erc721Lockable = await ERC721Lockable.deploy(true);
    await erc721Lockable.waitForDeployment();
    const isLocked = await erc721Lockable.isLocked(TOKEN_ID);
    expect(isLocked).to.be.true;
  });

});
