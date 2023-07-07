const { ethers } = require("hardhat")

const baseURI =  "/ipfs/bafybeih6cahp6rwzlgy2tn5sdjo33hixvem6gn5yfbtn2okfdikncnjaua"
const baseUID = "ASCG-98069-RD"  // Random product code
const PRICE0 = ethers.parseEther("0.6")
const PRICE1 = ethers.parseEther("0.5")
const PRICE2 = ethers.parseEther("0.4")
const nbCollectionItems = 1000
const IDENTITIES = {}

async function logListing(marketplace, nftAddress, nftId) {
  listing = await marketplace.getNFTListing(nftAddress, nftId)
  console.log(`>>> MARKETPLACE LISTINGS:
  \tprice: ${listing.price}
  \tisListed: ${listing.currentlyListed}
  \towner:${IDENTITIES[listing.seller]}
  \taddress: ${listing.contractAddress}
  \ttokenId: ${listing.tokenId}`
  )
}

async function logListedItems(marketplace) {
  let listings = await marketplace.fetchListedItems()
  console.log("LISTED ITEMS FOR SALE", listings);
}

async function logNftOwner(nftContract, tokenId) {
  console.log(`OWNER of NFT ${tokenId}: ${IDENTITIES[await nftContract.ownerOf(tokenId)]}`);
}

async function approveTransfers(marketplaceAddress, nftContract, user) {
  const isApprovedForAll = await nftContract.isApprovedForAll(user.address, marketplaceAddress)
  if(!isApprovedForAll){
      await nftContract.connect(user).setApprovalForAll(marketplaceAddress, true)
  }
}

async function approveNFTClaim(evermoreNFT, owner, tokenId) {
  await evermoreNFT.connect(owner).addToAllowlist(tokenId)
}

async function claimNFT(marketplace, evermoreNFT, owner, tokenId) {
  console.log(`\n\n--------- CLAIM NFT with ID ${tokenId} ---------`)
  let mintTx = await evermoreNFT.connect(owner).claim(owner.address, tokenId)
  console.log("check approved: ", await evermoreNFT.getApproved(tokenId));
  console.log("check isApprovedForAll: ", await evermoreNFT.isApprovedForAll(owner.address, await marketplace.getAddress()));

  await logListing(marketplace, await evermoreNFT.getAddress(), tokenId)
  return tokenId
}

async function cancelListing(marketplace, evermoreNFTAdress, owner, tokenId) {
  console.log(`\n\n--------- Cancel NFT with ID ${tokenId} ---------`)
  await marketplace.connect(owner).cancelListing(evermoreNFTAdress, tokenId)
  await logListing(marketplace, evermoreNFTAdress, tokenId)
}

async function updateListing(marketplace, evermoreNFTAdress, owner, tokenId, newPrice) {
  console.log(`\n\n--------- Update NFT price with ID ${tokenId} ---------`)
  await marketplace.connect(owner).updateListing(evermoreNFTAdress, tokenId, newPrice)
  await logListing(marketplace, evermoreNFTAdress, tokenId)
}

async function buyItem(marketplace, evermoreNFTAdress, buyer, tokenId, price) {
  console.log(`\n\n--------- BUY NFT with ID ${tokenId} for ${price} ---------`)
  await marketplace.connect(buyer).buyItem(evermoreNFTAdress, tokenId, {value: price})
  await logListing(marketplace, evermoreNFTAdress, tokenId)
}

async function listItem(marketplace, evermoreNFTAdress, owner, tokenId, price) {
  console.log(`\n\n--------- LIST 2ND HAND NFTs with ID ${tokenId} for ${price} ---------`)
  await marketplace.connect(owner).listItem(evermoreNFTAdress, tokenId, price)
  await logListing(marketplace, evermoreNFTAdress, tokenId)
}

async function withdrawProceeds(marketplace, user) {
  console.log(`\n\n--------- WITHDRAW for ${IDENTITIES[user.address]} ---------`)
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
    await marketplace.waitForDeployment()
    const marketplaceAddress = await marketplace.getAddress()

    const evermoreNFTFactory = await ethers.getContractFactory("EvermoreNFT")
    const evermoreNFT = await evermoreNFTFactory.connect(deployer).deploy(marketplaceAddress, nbCollectionItems, baseUID, false)
    await evermoreNFT.waitForDeployment()
    await evermoreNFT.setRoyalty(royaliesReceiver.address, 1000) // 10% royalties
    await evermoreNFT.setBaseURI(baseURI)
    const evermoreNFTAddress = await evermoreNFT.getAddress()
    console.log("EvermoreNFT deployed to:", evermoreNFTAddress)

    // Making sure the marketplace can transfer all the users NFT
    await approveTransfers(marketplaceAddress, evermoreNFT, owner)
    await approveTransfers(marketplaceAddress, evermoreNFT, buyer1)
    await approveTransfers(marketplaceAddress, evermoreNFT, buyer2)

    const nbToMint = 3
    let tokenIds = []

    console.log(`\n\n--------- MINT AND REGISTER ${nbToMint} NFTs ---------`)
    for (let i=0; i<nbToMint; i++) {
      //await approveNFTClaim(evermoreNFT, deployer, i+1)
      let tokenId = i+5;
      await claimNFT(marketplace, evermoreNFT, owner, tokenId)
      tokenIds.push(tokenId)
      console.log(`Minted and listed token ${tokenId} by owner ${IDENTITIES[owner.address]}`)
    }

    ownerItems = await marketplace.connect(owner).fetchMyItems()
    console.log("OWNER ITEMS", ownerItems);

    await listItem(marketplace, evermoreNFT, owner, tokenIds[0], PRICE1)
    await listItem(marketplace, evermoreNFT, owner, tokenIds[1], PRICE1)

    await logListedItems(marketplace)

    await cancelListing(marketplace, evermoreNFTAddress, owner, tokenIds[0])

    await updateListing(marketplace, evermoreNFTAddress, owner, tokenIds[1], PRICE2)
    
    const listing1 = await marketplace.getNFTListing(evermoreNFTAddress, tokenIds[1])
    const nftPrice1 = listing1.price.toString()

    await buyItem(marketplace, evermoreNFTAddress, buyer1, tokenIds[1], nftPrice1)

    await listItem(marketplace, evermoreNFTAddress, buyer1, tokenIds[1], PRICE1)
    const listing2 = await marketplace.getNFTListing(evermoreNFTAddress, tokenIds[1])
    const nftPrice2 = listing2.price.toString()
    await buyItem(marketplace, evermoreNFTAddress, buyer2, tokenIds[1], nftPrice2)

    console.log(`\n\n--------- CHECK MARKETPLACE BALANCES ---------`)
    console.log("to earn owner", await marketplace.getSellerProceeds(owner.address));
    console.log("to earn buyer1", await marketplace.getSellerProceeds(buyer1.address));
    console.log("to earn buyer2", await marketplace.getSellerProceeds(buyer2.address));
    await withdrawProceeds(marketplace, owner)
    await withdrawProceeds(marketplace, buyer1)

    console.log(`\n\n--------- CHECK WALLETS BALANCES ---------`)
    console.log("MARKETPLACE ACCOUNT", await ethers.provider.getBalance(marketplaceAddress))
    console.log("ROYALTIES ACCOUNT", await ethers.provider.getBalance(royaliesReceiver.address))
    console.log("OWNER ACCOUNT", await ethers.provider.getBalance(owner.address))
    console.log("BUYER1 ACCOUNT", await ethers.provider.getBalance(buyer1.address))
    console.log("BUYER2 ACCOUNT", await ethers.provider.getBalance(buyer2.address))

    console.log(`\n\n--------- CHECK MY ITEMS ---------`)
    await logListedItems(marketplace)
    buyer2Items = await marketplace.connect(buyer2).fetchMyItems()
    console.log("buyer2Items", buyer2Items);
    ownerItems = await marketplace.connect(owner).fetchMyItems()
    console.log("ownerItems", ownerItems);


    // unregister all items
    for (let i=0; i<tokenIds.length; i++) {
      // try to connect with each key of IDENTITIES
      console.log(`\n\n--------- UNREGISTER ITEM ${tokenIds[i]} ---------`)
      for (const [key, value] of Object.entries(IDENTITIES)) {
        try {
          const user = accounts.filter((account) => account.address === key)[0]
          await marketplace.connect(user).unregisterItem(evermoreNFTAddress, tokenIds[i])
          console.log(`--------- UNREGISTER ITEM ${tokenIds[i]} for ${value} ---------`)
        } catch(err) {
        }
      }
    }

    ownerItems = await marketplace.connect(owner).fetchMyItems()
    console.log("ownerItems", ownerItems);
    // check the known NFT addresses in the marketplace
    const nftAddress = await marketplace.getKnownNFTAddresses()
    console.log("nftAddress", nftAddress);

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
