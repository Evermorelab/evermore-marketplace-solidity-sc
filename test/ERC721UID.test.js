const { expect } = require("chai");
require("chai").use(require("chai-as-promised"));

describe("ERC721UID", function () {

  const baseUID = "MERCH-YEL-COT-M-923";
  const TOKEN_ID = 29;

  beforeEach(async function () {
    const ERC721UID = await ethers.getContractFactory("ERC721UIDMock");
    erc721UID = await ERC721UID.deploy(baseUID);
    await erc721UID.deployed();
  });

  it("should return the base UID", async function () {
    expect(await erc721UID.baseUID()).to.equal(baseUID);
  });

  // TODO: Fix this test, problem with null trailing characters
  /* it("should return the correct UID for a token", async function () {
    const [minter] = await ethers.getSigners();
    const expectedUid = `${baseUID}-${TOKEN_ID}`;

    await erc721UID.mint(minter.address, TOKEN_ID);
    let uid = await erc721UID.tokenUID(TOKEN_ID);
    uid = uid.replace(/\0/g, ''); // Remove trailing zeros
    expect(uid).to.equal(expectedUid);
  }); */

  it("should return not return a UID if the token is not minted yet", async function () {
    await expect(erc721UID.tokenUID(TOKEN_ID)).to.be.rejectedWith(/ERC721UID: UID query for nonexistent token/i);
  });

});