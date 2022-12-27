//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

error PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);
error ItemNotForSale(address nftAddress, uint256 tokenId);
error NotListed(address nftAddress, uint256 tokenId);
error NotRegistered(address nftAddress, uint256 tokenId);
error AlreadyListed(address nftAddress, uint256 tokenId);
error AlreadyRegistered(address nftAddress, uint256 tokenId);
error NoProceeds();
error NotOwner();
error NotApprovedForMarketplace();
error PriceMustBeAboveZero();
error BuyOwnNFT(address nftAddress, uint256 tokenId);


contract EvermoreMarketplace is ReentrancyGuard {

    using SafeMath for uint256;
  
    uint256 public LISTING_FEE = 0.0001 ether;
    address payable private _marketOwner;
    // Counters.Counter private _nftCount;
    // Counters.Counter private _nftsListed;

    // save all the listing hapenning on the marketplace
    struct Listing {
        uint256 price;
        address seller;
        bool currentlyListed;
        address contractAddress;
        uint256 tokenId;
    }

    // State Variables
    mapping(address => mapping(uint256 => Listing)) private s_listings;
    mapping(address => uint256) private s_proceeds;


    /////////////////////
    ////// Events ///////
    /////////////////////

    event ItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    event ItemCanceled(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    event ItemBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );


    /////////////////////
    ///// Mofifiers /////
    /////////////////////

    modifier isRegistered(address _nftAddress, uint256 _tokenId) {
        Listing memory listing = s_listings[_nftAddress][_tokenId];
        if (listing.price <= 0) {
            revert NotRegistered(_nftAddress, _tokenId);
        }
        _;
    }

    modifier notRegistered(
        address _nftAddress,
        uint256 _tokenId
    ) {
        Listing memory listing = s_listings[_nftAddress][_tokenId];
        if (listing.price > 0) {
            revert AlreadyRegistered(_nftAddress, _tokenId);
        }
        _;
    }

    modifier isListed(address _nftAddress, uint256 _tokenId) {
        Listing memory listing = s_listings[_nftAddress][_tokenId];
        if (listing.price <= 0 || !listing.currentlyListed) {
            revert NotListed(_nftAddress, _tokenId);
        }
        _;
    }

    modifier notListed(
        address _nftAddress,
        uint256 _tokenId
    ) {
        Listing memory listing = s_listings[_nftAddress][_tokenId];
        if (listing.price > 0 && listing.currentlyListed) {
            revert AlreadyListed(_nftAddress, _tokenId);
        }
        _;
    }

    modifier isOwner(
        address _nftAddress,
        uint256 _tokenId,
        address _caller
    ) {
        IERC721 nft = IERC721(_nftAddress);
        address owner = nft.ownerOf(_tokenId);
        if (_caller != owner) {
            revert NotOwner();
        }
        _;
    }

    /////////////////////
    // Main functions ///
    /////////////////////

    /*
     * @notice Method for listing a new NFT
     * @param _nftAddress Address of NFT contract
     * @param _tokenId Token ID of NFT
     * @param _price sale price for each item
     */
    function listItem(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _price
    )
        public
        payable
        nonReentrant
        notRegistered(_nftAddress, _tokenId)
        isOwner(_nftAddress, _tokenId, msg.sender)
    {
        if (_price <= 0) {
            revert PriceMustBeAboveZero();
        }
        require(msg.value == LISTING_FEE, "Not enough ether for listing fee");

        IERC721 nft = IERC721(_nftAddress);
        if (nft.getApproved(_tokenId) != address(this) && !nft.isApprovedForAll(msg.sender, address(this))) {
            revert NotApprovedForMarketplace();
        }
        s_listings[_nftAddress][_tokenId] = Listing(_price, msg.sender, true, _nftAddress, _tokenId);
        // _nftCount.increment();
        // _nftsListed.increment();

        emit ItemListed(msg.sender, _nftAddress, _tokenId, _price);
    }

    /*
     * @notice Method for re-listing a an NFT already known by the marketplace
     * @param _nftAddress Address of NFT contract
     * @param _tokenId Token ID of NFT
     * @param _price sale price for each item
     */
    function relistItem(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _price
    )
        public
        payable
        nonReentrant
        notListed(_nftAddress, _tokenId)
        isOwner(_nftAddress, _tokenId, msg.sender)
    {
        if (_price <= 0) {
            revert PriceMustBeAboveZero();
        }
        require(msg.value == LISTING_FEE, "Not enough ether for listing fee");
        Listing storage listedItem = s_listings[_nftAddress][_tokenId];
        listedItem.currentlyListed = true;
        listedItem.price = _price;
        // _nftsListed.increment();
  
        emit ItemListed(msg.sender, _nftAddress, _tokenId, _price);
    }

    /*
     * @notice Method for cancelling listing
     * @param _nftAddress Address of NFT contract
     * @param _tokenId Token ID of NFT
     */
    function cancelListing(address _nftAddress, uint256 _tokenId)
        external
        isOwner(_nftAddress, _tokenId, msg.sender)
        isListed(_nftAddress, _tokenId)
    {
        Listing storage listedItem = s_listings[_nftAddress][_tokenId];
        listedItem.currentlyListed = false;
        // _nftsListed.decrement();
        emit ItemCanceled(msg.sender, _nftAddress, _tokenId);
    }

    /*
     * @notice Method for buying listing
     * @notice The owner of an NFT could unapprove the marketplace,
     * which would cause this function to fail
     * TODO: implement `Escrow`feature
     * @param _nftAddress Address of NFT contract
     * @param _tokenId Token ID of NFT
     */
    function buyItem(address _nftAddress, uint256 _tokenId)
        external
        payable
        isListed(_nftAddress, _tokenId)
        nonReentrant
    {
        Listing storage listedItem = s_listings[_nftAddress][_tokenId];
        address seller = listedItem.seller;
        if (msg.value < listedItem.price) {
            revert PriceNotMet(_nftAddress, _tokenId, listedItem.price);
        }
        if (msg.sender == listedItem.seller) {
            revert BuyOwnNFT(_nftAddress, _tokenId);
        }

        // Calculate royalties
        ERC721Royalty nft = ERC721Royalty(_nftAddress);
        nft.safeTransferFrom(seller, msg.sender, _tokenId);
        (address _creator, uint256 _royaltiesValue) = nft.royaltyInfo(_tokenId, msg.value);

        s_proceeds[listedItem.seller] += msg.value.sub(_royaltiesValue);
        listedItem.currentlyListed = false;
        listedItem.seller = msg.sender;
        // _nftsListed.decrement();
        payable(_creator).transfer(_royaltiesValue);
        emit ItemBought(msg.sender, _nftAddress, _tokenId, listedItem.price);
    }

    /*
     * @notice Method for updating listing
     * @param _nftAddress Address of NFT contract
     * @param _tokenId Token ID of NFT
     * @param _newPrice Price in Wei of the item
     */
    function updateListing(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _newPrice
    )
        external
        isListed(_nftAddress, _tokenId)
        nonReentrant
        isOwner(_nftAddress, _tokenId, msg.sender)
    {
        if (_newPrice <= 0) {
            revert PriceMustBeAboveZero();
        }
        s_listings[_nftAddress][_tokenId].price = _newPrice;
        emit ItemListed(msg.sender, _nftAddress, _tokenId, _newPrice);
    }
    /*
     * @notice Method for withdrawing proceeds from sales
     */
    function withdrawProceeds() external {
        uint256 proceeds = s_proceeds[msg.sender];
        if (proceeds <= 0) {
            revert NoProceeds();
        }
        s_proceeds[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: proceeds}("");
        require(success, "Transfer failed");
    }

    /////////////////////
    // Getter Functions //
    /////////////////////

    function getNFTListing(address _nftAddress, uint256 _tokenId)
        external
        view
        returns (Listing memory)
    {
        return s_listings[_nftAddress][_tokenId];
    }

    function getSellerProceeds(address _seller) external view returns (uint256) {
        return s_proceeds[_seller];
    }

    function getListingFee() public view returns (uint256) {
        return LISTING_FEE;
    }

}