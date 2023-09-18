const { expect } = require("chai");
require("chai").use(require("chai-as-promised"));
const { ethers } = require("hardhat");

describe("ERC721UID", function () {

  beforeEach(async function () {
    const ERC721UID = await ethers.getContractFactory("ERC721UIDMock");
    erc721UID = await ERC721UID.deploy();
    await erc721UID.deployed();
  });

  it("should return the correct tokens range for UID", async function () {
    const amount1 = 10;
    const amount2 = 13;
    const baseUID1 = ethers.utils.formatBytes32String("MERCH-YEL-COT-M-923");
    const baseUID2 = ethers.utils.formatBytes32String("MERCH-YEL-COT-L-923");
    await erc721UID.addItems(amount1, baseUID1);
    await erc721UID.addItems(amount2, baseUID2);
    await erc721UID.addItems(amount1, baseUID1);
    let tokens1 = await erc721UID.getUIDTokens(baseUID1);
    let tokens2 = await erc721UID.getUIDTokens(baseUID2);

    expect(tokens1).to.have.lengthOf(2);
    expect(tokens2).to.have.lengthOf(1);
    expect(tokens1[0].start).to.equal(1);
    expect(tokens1[0].end).to.equal(amount1);
    expect(tokens1[1].start).to.equal(amount1 + amount2 + 1);
    expect(tokens1[1].end).to.equal(amount1 + amount2 + amount1);
    expect(tokens2[0].start).to.equal(amount1 + 1);
    expect(tokens2[0].end).to.equal(amount1 + amount2);
  });

});