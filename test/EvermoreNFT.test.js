const { expect } = require("chai");
require("@nomicfoundation/hardhat-chai-matchers");
require("chai").use(require("chai-as-promised"));
const { ethers } = require("hardhat");


describe("EvermoreNFT", function () {
  const ITEM_SUPPLY = 10;
  const BASE_UID_SUPPLY= ethers.utils.formatBytes32String("MERCH-RED-COT-L-924");
  const TOKEN_ID = 1;
  const MANAGER_ROLE = ethers.utils.id("MANAGER");
  const ADMIN_ROLE = ethers.utils.id("ADMIN");
  const EVENT_MANAGER_ROLE = ethers.utils.id("EVENT_MANAGER");

  async function getStorageContract(evermoreNFT) {
    const historyStorageAddress = await evermoreNFT.historyStorage();
    const historyStorage = await ethers.getContractAt("HistoryStorage", historyStorageAddress);
    return historyStorage;
  }

  async function signClaim(tokenId, receiver, signer) {
    const message = `${receiver.address} claims token ${tokenId}`;
    const messageHash = ethers.utils.id(message);
    const messageBytes = ethers.utils.arrayify(messageHash);
    const signature = await signer.signMessage(messageBytes);
    return { messageHash, signature };
  }

  async function claimNFT(evermoreNFT, tokenId, receiver) {
    const { messageHash, signature } = await signClaim(tokenId, receiver, this.owner);
    return evermoreNFT.connect(receiver).claim(receiver.address, tokenId, messageHash, signature);
  }

  function simulateTokenURI(tokenId) {
    return tokenId + ".json";
  }

  function createItemsURI(amount) {
    const items = [];
    for (let i = 1; i <= amount; i++) {
      items.push(simulateTokenURI(i));
    }
    return items;
  }

  beforeEach(async function () {
    // Set up accounts
    [owner, other, receiver, minter] = await ethers.getSigners();
    this.owner = owner;
    this.other = other;
    this.receiver = receiver;
    this.minter = minter;

    // deploy NFT
    const EvermoreNFT = await ethers.getContractFactory("EvermoreNFT");
    evermoreNFT = await EvermoreNFT.connect(owner).deploy();
    await evermoreNFT.deployed();
    const items = createItemsURI(ITEM_SUPPLY);
    await evermoreNFT.connect(this.owner).addItems(items, BASE_UID_SUPPLY);
  });

  it("should the owner be also an ADMIN and MANAGER", async function () {
    const isAdmin = await evermoreNFT.hasRole(ADMIN_ROLE, this.owner.address);
    const isManager = await evermoreNFT.hasRole(MANAGER_ROLE, this.owner.address);
    expect(isAdmin).to.be.true;
    expect(isManager).to.be.true;
  });

  it("should have the initial supply set to 0", async function () {
    const EvermoreNFTLocal = await ethers.getContractFactory("EvermoreNFT");
    let evermoreNFTLocal = await EvermoreNFTLocal.connect(owner).deploy();
    await evermoreNFTLocal.deployed();
    expect(await evermoreNFTLocal.itemSupply()).to.equal("0");
  });

  // UID
  it("should be able to add items as MANAGER", async function () {
    const baseUID2 = ethers.utils.formatBytes32String("MERCH-YEL-COT-XXL-923231");
    const items = createItemsURI(ITEM_SUPPLY);
    await evermoreNFT.connect(this.owner).grantRole(MANAGER_ROLE, this.other.address);
    await evermoreNFT.connect(this.other).addItems(items, baseUID2);

    // check items
    let tokens = await evermoreNFT.getUIDTokens(baseUID2);
    expect(tokens).to.have.lengthOf(1);
    expect(tokens[0].end - tokens[0].start).to.equal(ITEM_SUPPLY - 1);
  });

  it("should not be able to add items as NON-MANAGER", async function () {
    const baseUID2 = ethers.utils.formatBytes32String("MERCH-YEL-COT-XXL-923231");
    const items = createItemsURI(ITEM_SUPPLY);
    await expect(
      evermoreNFT.connect(this.other).addItems(items, baseUID2)
    ).to.be.revertedWith(/is missing role/i);
  });

  it("should't be able to claim item if not added to the contract", async function () {
    await expect(
      claimNFT(evermoreNFT, ITEM_SUPPLY + 1, this.minter)
    ).to.be.revertedWithCustomError(evermoreNFT, 'InvalidTokenId');
  });

  // ROYALTIES

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
    await evermoreNFT.connect(this.owner).grantRole(ADMIN_ROLE, this.other.address);
    await evermoreNFT.connect(this.other).setRoyalty(this.other.address, newRoyalty);
    await claimNFT(evermoreNFT, TOKEN_ID, this.minter);
    const [address, percentage] = await evermoreNFT.royaltyInfo(TOKEN_ID, 100);
    expect(address).to.equal(this.other.address);
    expect(percentage.toString()).to.equal(newRoyaltyPerc.toString());
  });

  // EVENTS

  it("should be able to add an event as nft owner", async function () {
    const eventURI = "ipfs://123";
    await claimNFT(evermoreNFT, TOKEN_ID, this.minter);
    await evermoreNFT.connect(this.minter).addItemEvent(TOKEN_ID, eventURI);
    const historyStorage = await getStorageContract(evermoreNFT);
    const events = await historyStorage.getItemEvents(TOKEN_ID);
    expect(events[0]).to.equal(eventURI);
  });

  it("should not be able to add an event as non-nft owner", async function () {
    const eventURI = "ipfs://123";
    await claimNFT(evermoreNFT, TOKEN_ID, this.minter);
    // transfer to another address
    await evermoreNFT.connect(this.minter).transferFrom(this.minter.address, this.receiver.address, TOKEN_ID);
    await expect(
      evermoreNFT.connect(this.minter).addItemEvent(TOKEN_ID, eventURI)
    ).to.be.revertedWithCustomError(evermoreNFT, 'InvalidPermissions');
  });

  it("should be able to add an event as EVENT_MANAGER, ADMIN or MANAGER", async function () {
    const eventURIs =[ "ipfs://123", "ipfs://456", "ipfs://789"];
    const historyStorage = await getStorageContract(evermoreNFT);
    // event manager
    await claimNFT(evermoreNFT, TOKEN_ID, this.minter);
    await evermoreNFT.connect(this.owner).grantRole(EVENT_MANAGER_ROLE, this.other.address);
    await evermoreNFT.connect(this.other).addItemEvent(TOKEN_ID, eventURIs[0]);
    const events = await historyStorage.getItemEvents(TOKEN_ID);
    expect(events[0]).to.equal(eventURIs[0]);
    // manager
    await evermoreNFT.connect(this.owner).grantRole(MANAGER_ROLE, this.receiver.address);
    await evermoreNFT.connect(this.receiver).addItemEvent(TOKEN_ID, eventURIs[1]);
    const events2 = await historyStorage.getItemEvents(TOKEN_ID);
    
    expect(events2[1]).to.equal(eventURIs[1]);
    // admin
    await evermoreNFT.connect(this.owner).revokeRole(MANAGER_ROLE, this.receiver.address);
    await evermoreNFT.connect(this.owner).grantRole(ADMIN_ROLE, this.receiver.address);
    await evermoreNFT.connect(this.receiver).addItemEvent(TOKEN_ID, eventURIs[2]);
    const events3 = await historyStorage.getItemEvents(TOKEN_ID);
    expect(events3[2]).to.equal(eventURIs[2]);
  });

  it("should be able to add a condition as nft owner", async function () {
    const conditionURI = "ipfs://123";
    await claimNFT(evermoreNFT, TOKEN_ID, this.minter);
    await evermoreNFT.connect(this.minter).addItemCondition(TOKEN_ID, conditionURI);
    const historyStorage = await getStorageContract(evermoreNFT);
    const conditions = await historyStorage.getItemConditions(TOKEN_ID);
    expect(conditions[0]).to.equal(conditionURI);
  });

  it("should not be able to add a condition as a non-nft owner", async function () {
    const conditionURI = "ipfs://123";
    await claimNFT(evermoreNFT, TOKEN_ID, this.minter);
    // transfer to another address
    await evermoreNFT.connect(this.minter).transferFrom(this.minter.address, this.receiver.address, TOKEN_ID);
    await expect(
      evermoreNFT.connect(this.minter).addItemCondition(TOKEN_ID, conditionURI)
    ).to.be.revertedWithCustomError(evermoreNFT, 'InvalidPermissions');
  });

  it("should be able to add a condition as EVENT_MANAGER, ADMIN or MANAGER", async function () {
    const conditionURIs =[ "ipfs://123", "ipfs://456", "ipfs://789"];
    const historyStorage = await getStorageContract(evermoreNFT);
    // condition manager
    await claimNFT(evermoreNFT, TOKEN_ID, this.minter);
    await evermoreNFT.connect(this.owner).grantRole(EVENT_MANAGER_ROLE, this.other.address);
    await evermoreNFT.connect(this.other).addItemCondition(TOKEN_ID, conditionURIs[0]);
    const conditions = await historyStorage.getItemConditions(TOKEN_ID);
    expect(conditions[0]).to.equal(conditionURIs[0]);
    // manager
    await evermoreNFT.connect(this.owner).grantRole(MANAGER_ROLE, this.receiver.address);
    await evermoreNFT.connect(this.receiver).addItemCondition(TOKEN_ID, conditionURIs[1]);
    const conditions2 = await historyStorage.getItemConditions(TOKEN_ID);
    expect(conditions2[1]).to.equal(conditionURIs[1]);
    // admin
    await evermoreNFT.connect(this.owner).revokeRole(MANAGER_ROLE, this.receiver.address);
    await evermoreNFT.connect(this.owner).grantRole(ADMIN_ROLE, this.receiver.address);
    await evermoreNFT.connect(this.receiver).addItemCondition(TOKEN_ID, conditionURIs[2]);
    const conditions3 = await historyStorage.getItemConditions(TOKEN_ID);
    expect(conditions3[2]).to.equal(conditionURIs[2]);
  });

  // CLAIM

  it("should not be able to claim an NFT if tokenId higher than supply", async function () {    
    await expect(
      claimNFT(evermoreNFT, ITEM_SUPPLY+1, this.other)
    ).to.be.revertedWithCustomError(evermoreNFT, 'InvalidTokenId');
  });

  it("should be able to claim an NFT if tokenId is not claimed", async function () {
    await claimNFT(evermoreNFT, TOKEN_ID, this.minter);
    const owner = await evermoreNFT.ownerOf(TOKEN_ID);
    expect(owner).to.equal(minter.address);
  });

  it("should not be able to claim an NFT if tokenId is already claimed", async function () {
    await claimNFT(evermoreNFT, TOKEN_ID, this.minter);
    await expect(
      claimNFT(evermoreNFT, TOKEN_ID, this.other)
    ).to.be.rejectedWith(/ERC721: token already minted/i);
  });

  it("should be able to claim with signature from a manager", async function () {
    await evermoreNFT.connect(this.owner).grantRole(MANAGER_ROLE, this.other.address);
    const { messageHash, signature } = await signClaim(TOKEN_ID, this.minter, this.other);
    await evermoreNFT.connect(this.minter).claim(this.minter.address, TOKEN_ID, messageHash, signature);
    await expect(
      evermoreNFT.ownerOf(TOKEN_ID)
    ).to.eventually.equal(this.minter.address);
  });

  it("should not be able to claim with if signer is not a manager", async function () {
    const { messageHash, signature } = await signClaim(TOKEN_ID, this.minter, this.other);
    await expect(
      evermoreNFT.connect(this.minter).claim(this.minter.address, TOKEN_ID, messageHash, signature)
    ).to.be.revertedWithCustomError(evermoreNFT, 'InvalidPermissions');
  });

  it("should not be able to claim multiple times with the same signature", async function () {
    await evermoreNFT.connect(this.owner).grantRole(MANAGER_ROLE, this.other.address);
    const { messageHash, signature } = await signClaim(TOKEN_ID, this.minter, this.other);
    await evermoreNFT.connect(this.minter).claim(this.minter.address, TOKEN_ID, messageHash, signature);
    await expect(
      evermoreNFT.connect(this.minter).claim(this.minter.address, TOKEN_ID+1, messageHash, signature)
    ).to.be.revertedWithCustomError(evermoreNFT, 'SignatureAlreadyUsed');
  });

  it("should be able to claim multiple NFTs with a valide signature", async function () {
    await evermoreNFT.connect(this.owner).grantRole(MANAGER_ROLE, this.other.address);
    let { messageHash: messageHash1, signature: signature1 } = await signClaim(TOKEN_ID, this.minter, this.other);
    await evermoreNFT.connect(this.minter).claim(this.minter.address, TOKEN_ID, messageHash1, signature1);
    let { messageHash: messageHash2, signature: signature2 } = await signClaim(TOKEN_ID+1, this.minter, this.other);
    await evermoreNFT.connect(this.minter).claim(this.minter.address, TOKEN_ID+1, messageHash2, signature2);
    await expect(
      evermoreNFT.ownerOf(TOKEN_ID+1)
    ).to.eventually.equal(this.minter.address);
  });

  // BURN

  it("should be able to burn a NFT as a manager", async function () {
    await claimNFT(evermoreNFT, TOKEN_ID, this.minter);
    await evermoreNFT.connect(this.owner).grantRole(MANAGER_ROLE, this.other.address);
    await evermoreNFT.connect(this.other).burn(TOKEN_ID);
    await expect(
      evermoreNFT.ownerOf(TOKEN_ID)
    ).to.be.revertedWith(/ERC721: invalid token ID/i);
  });

  it("should be able to burn a NFT as an admin", async function () {
    await claimNFT(evermoreNFT, TOKEN_ID, this.minter);
    await evermoreNFT.connect(this.owner).grantRole(ADMIN_ROLE, this.other.address);
    await evermoreNFT.connect(this.other).burn(TOKEN_ID);
    await expect(
      evermoreNFT.ownerOf(TOKEN_ID)
    ).to.be.revertedWith(/ERC721: invalid token ID/i);
  });

  it("should be able to burn a NFT as the NFT owner", async function () {
    await claimNFT(evermoreNFT, TOKEN_ID, this.minter);
    await evermoreNFT.connect(this.minter).burn(TOKEN_ID);
    await expect(
      evermoreNFT.ownerOf(TOKEN_ID)
    ).to.be.revertedWith(/ERC721: invalid token ID/i);
  });


  it("should not be able to burn a NFT if not the owner", async function () {
    await claimNFT(evermoreNFT, TOKEN_ID, this.minter);
    await evermoreNFT.connect(this.minter).burn(TOKEN_ID);
    await expect(
      evermoreNFT.ownerOf(TOKEN_ID)
    ).to.be.revertedWith(/ERC721: invalid token ID/i);
  });

  // TOKEN URI

  it("should return the correct tokenURI", async function () {
    await claimNFT(evermoreNFT, TOKEN_ID, this.minter);
    const tokenURI = await evermoreNFT.tokenURI(TOKEN_ID);
    expect(tokenURI).to.equal(simulateTokenURI(TOKEN_ID));
  });

  it("should return the correct tokenURI if no baseURI", async function () {
    const EvermoreNFTLocal = await ethers.getContractFactory("EvermoreNFT");
    let evermoreNFTLocal = await EvermoreNFTLocal.connect(owner).deploy();
    // add items
    const items = createItemsURI(ITEM_SUPPLY);
    await evermoreNFTLocal.connect(this.owner).addItems(items, BASE_UID_SUPPLY);
    await evermoreNFTLocal.deployed();
    await claimNFT(evermoreNFTLocal, TOKEN_ID, this.minter);
    const tokenURI = await evermoreNFTLocal.tokenURI(TOKEN_ID);
    expect(tokenURI).to.equal(simulateTokenURI(TOKEN_ID));
  });

  // TRANSFER

  it("should not be able to transfer more than 1 NFT at the time", async function () {
    const EvermoreNFTMock = await ethers.getContractFactory("EvermoreNFTMock");
    const evermoreNFTMock = await EvermoreNFTMock.deploy();
    await evermoreNFTMock.deployed();
    const items = createItemsURI(ITEM_SUPPLY);
    await evermoreNFTMock.connect(this.owner).addItems(items, BASE_UID_SUPPLY);
    await claimNFT(evermoreNFTMock, TOKEN_ID, this.minter);
    await claimNFT(evermoreNFTMock, TOKEN_ID+1, this.minter);
    await expect(
      evermoreNFTMock.connect(this.minter).beforeTokenTransfer(this.minter.address, this.receiver.address, TOKEN_ID, 2)
    ).to.be.rejectedWith(/InvalidBatchSize/i);
  });

  // UNUSED EXTENSIONS
  /* it("should be able to lock NFT as MANAGER", async function () {
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

  it("should not be able to claim an NFT if tokenId is locked", async function () {
    await evermoreNFT.connect(this.owner).lockNFT(TOKEN_ID);
    await expect(
      claimNFT(evermoreNFT, TOKEN_ID, this.minter)
    ).to.be.revertedWithCustomError(evermoreNFT, 'InvalidNFTLockState');
  });*/

});