const { ethers } = require("hardhat")

const baseURI =  "/ipfs/bafybeih6cahp6rwzlgy2tn5sdjo33hixvem6gn5yfbtn2okfdikncnjaua"
const PRICE1 = ethers.utils.parseEther("50")
const PRICE2 = ethers.utils.parseEther("40")
const IDENTITIES = {}

async function logListing(marketplace, nftAddress, nftId) {
  listing = await marketplace.getNFTListing(nftAddress, nftId)
  console.log(`listing\n \tprice: ${listing.price}\n 
  \tisListed: ${listing.currentlyListed}\n 
  \towner:${IDENTITIES[listing.seller]}\n
  \taddress: ${listing.contractAddress}\n
  \ttokenId: ${listing.tokenId}`
  )
}

async function logNftOwner(nftContract, tokenId) {
  console.log(`OWNER of NFT ${tokenId}: ${IDENTITIES[await nftContract.ownerOf(tokenId)]}`);
}

async function approveTransfers(marketplace, nftContract, user) {
  const isApprovedForAll = await nftContract.isApprovedForAll(user.address, marketplace.address)
  if(!isApprovedForAll){
      await nftContract.connect(user).setApprovalForAll(marketplace.address, true)
  }
}

async function newMintAndList(marketplace, evermoreNFT, listingFee, owner) {
  let mintTx = await evermoreNFT.connect(owner).mint(baseURI)
  const mintTxReceipt = await mintTx.wait(1)
  const tokenId = mintTxReceipt.events[0].args.tokenId
  console.log("check approved: ", await evermoreNFT.getApproved(tokenId));
  console.log("check isApprovedForAll: ", await evermoreNFT.isApprovedForAll(owner.address, marketplace.address));

  await marketplace.connect(owner).listItem(evermoreNFT.address, tokenId, PRICE1, {value: listingFee})
  await logListing(marketplace, evermoreNFT.address, tokenId)
  return tokenId
}

async function cancelListing(marketplace, evermoreNFT, owner, tokenId) {
  console.log(`--------- Cancel NFT with ID ${tokenId} ---------`)
  await marketplace.connect(owner).cancelListing(evermoreNFT.address, tokenId)
  await logListing(marketplace, evermoreNFT.address, tokenId)
}

async function updateListing(marketplace, evermoreNFT, owner, tokenId, newPrice) {
  console.log(`--------- Update NFT price with ID ${tokenId} ---------`)
  await marketplace.connect(owner).updateListing(evermoreNFT.address, tokenId, newPrice)
  await logListing(marketplace, evermoreNFT.address, tokenId)
}

async function buyItem(marketplace, evermoreNFT, buyer, tokenId, price) {
  console.log(`--------- BUY 1 NFTs with ID ${tokenId} for ${price} ---------`)
  await logNftOwner(evermoreNFT, tokenId)
  await marketplace.connect(buyer).buyItem(evermoreNFT.address, tokenId, {value: price})
  await logNftOwner(evermoreNFT, tokenId)
  await logListing(marketplace, evermoreNFT.address, tokenId)
}

async function relistItem(marketplace, evermoreNFT, owner, tokenId, price, listingFee) {
  console.log(`--------- LIST 2ND HAND NFTs with ID ${tokenId} for ${price} ---------`)
  await marketplace.connect(owner).relistItem(evermoreNFT.address, tokenId, price, {value: listingFee})
  await logListing(marketplace, evermoreNFT.address, tokenId)
}

async function withdrawProceeds(marketplace, user) {
  console.log(`--------- WITHDRAW for ${IDENTITIES[user.address]} ---------`)
  await marketplace.connect(user).withdrawProceeds()
}


async function main() {

  const accounts = await ethers.getSigners()
  const [deployer, owner, royaliesReceiver, buyer1, buyer2] = accounts

  IDENTITIES[deployer.address] = "DEPLOYER"
  IDENTITIES[owner.address] = "OWNER"
  IDENTITIES[buyer1.address] = "BUYER_1"
  IDENTITIES[buyer2.address] = "BUYER_2"
  IDENTITIES[royaliesReceiver.address] = "ROYALTIES ACCOUNT"
  
  try {
    const marketplaceFactory = await ethers.getContractFactory("EvermoreMarketplace")
    const marketplace = await marketplaceFactory.deploy()
    await marketplace.deployed()

    const evermoreNFTFactory = await ethers.getContractFactory("EvermoreNFT")
    const evermoreNFT = await evermoreNFTFactory.deploy(marketplace.address)
    await evermoreNFT.deployed()
    await evermoreNFT.setRoyalty(10, royaliesReceiver.address)

    // Making sure the marketplace can transfer all the users NFT
    await approveTransfers(marketplace, evermoreNFT, owner)
    await approveTransfers(marketplace, evermoreNFT, buyer1)
    await approveTransfers(marketplace, evermoreNFT, buyer2)

    const nbToMint = 3
    let tokenIds = []
    let listingFee = await marketplace.getListingFee()
    listingFee = listingFee.toString()

    console.log(`--------- MINT AND LIST ${nbToMint} NFTs ---------`)
    for (let i=0; i<nbToMint; i++) {
      const tokenId = await newMintAndList(marketplace, evermoreNFT, listingFee, owner)
      tokenIds.push(tokenId)
      console.log(`Minted and listed token ${tokenId} by owner ${IDENTITIES[owner]}`)
    }

    await cancelListing(marketplace, evermoreNFT, owner, tokenIds[0])

    await updateListing(marketplace, evermoreNFT, owner, tokenIds[1], PRICE2)
    
    const listing1 = await marketplace.getNFTListing(evermoreNFT.address, tokenIds[1])
    const nftPrice1 = listing1.price.toString()

    await buyItem(marketplace, evermoreNFT, buyer1, tokenIds[1], nftPrice1)

    await relistItem(marketplace, evermoreNFT, buyer1, tokenIds[1], PRICE1, listingFee)
    const listing2 = await marketplace.getNFTListing(evermoreNFT.address, tokenIds[1])
    const nftPrice2 = listing2.price.toString()
    await buyItem(marketplace, evermoreNFT, buyer2, tokenIds[1], nftPrice2)

    console.log("to earn owner", await marketplace.getSellerProceeds(owner.address));
    console.log("to earn buyer1", await marketplace.getSellerProceeds(buyer1.address));
    console.log("to earn buyer2", await marketplace.getSellerProceeds(buyer2.address));
    await withdrawProceeds(marketplace, owner)
    await withdrawProceeds(marketplace, buyer1)

    console.log("MARKETPLACE ACCOUNT", await ethers.provider.getBalance(marketplace.address))
    console.log("ROYALTIES ACCOUNT", await ethers.provider.getBalance(royaliesReceiver.address))
    console.log("OWNER ACCOUNT", await ethers.provider.getBalance(owner.address))
    console.log("BUYER1 ACCOUNT", await ethers.provider.getBalance(buyer1.address))
    console.log("BUYER2 ACCOUNT", await ethers.provider.getBalance(buyer2.address))

  } catch(err) {
    console.log('Doh! ', err);
  }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
