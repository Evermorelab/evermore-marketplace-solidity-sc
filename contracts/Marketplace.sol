//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);
error ItemNotForSale(address nftAddress, uint256 tokenId);
error NotListed(address nftAddress, uint256 tokenId);
error NotRegistered(address nftAddress, uint256 tokenId);
error AlreadyListed(address nftAddress, uint256 tokenId);
error AlreadyRegistered(address nftAddress, uint256 tokenId);
error NoProceeds();
error NotAuthorised();
error NotApprovedForMarketplace();
error PriceMustBeAboveZero();
error BuyOwnNFT(address nftAddress, uint256 tokenId);


contract EvermoreMarketplace is ReentrancyGuard, Ownable {

    using SafeMath for uint256;
  
    uint256 public EVERMORE_FEES = 2;

    // save all the listings hapenning on the marketplace
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
    address[] public nft_addresses;
    mapping(address => uint256[]) private _tokenIdPerAddress;

    /////////////////////
    ////// Events ///////
    /////////////////////

    event ItemRegistered(
        address indexed seller,
        address indexed nftAddress,
        uint256 tokenId
    );

    event ItemUnregistered(
        address indexed seller,
        address indexed nftAddress,
        uint256 tokenId
    );

    event ItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    ) ;

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

    event withdrawProceeded(address indexed seller);

    event FeesSet();


    /////////////////////
    ///// Mofifiers /////
    /////////////////////

    modifier shouldBeRegistered(address _nftAddress, uint256 _tokenId) {
        if (!_isRegistered(_nftAddress, _tokenId)) {
            revert NotRegistered(_nftAddress, _tokenId);
        }
        _;
    }

    modifier shouldNotBeRegistered(
        address _nftAddress,
        uint256 _tokenId
    ) {
        if (_isRegistered(_nftAddress, _tokenId)) {
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
            revert NotAuthorised();
        }
        _;
    }

    modifier isOwnerOrContract(
      address _nftAddress,
      uint256 _tokenId,
      address _caller
    ){
        IERC721 nft = IERC721(_nftAddress);
        address owner = nft.ownerOf(_tokenId);
        if (_caller != owner && _caller != _nftAddress) {
            revert NotAuthorised();
        }
        _;
    }

    function _isRegistered(address _nftAddress, uint256 _tokenId) internal view returns (bool) {
        Listing memory listing = s_listings[_nftAddress][_tokenId];
        if (listing.seller == address(0)) {
            return false;
        }
        return true;
    }

    /////////////////////
    // Main functions ///
    /////////////////////

    /*
     * @notice Method for registering a new NFT into the marketplace
     * @param _nftAddress Address of NFT contract
     * @param _tokenId Token ID of NFT
     */
    function registerItem(
        address _nftAddress,
        uint256 _tokenId
    )
        public
        shouldNotBeRegistered(_nftAddress, _tokenId)
        isOwnerOrContract(_nftAddress, _tokenId, msg.sender)
    {

        IERC721 nft = IERC721(_nftAddress);
        address _owner = nft.ownerOf(_tokenId);

        if (_tokenIdPerAddress[_nftAddress].length == 0) {
            nft_addresses.push(_nftAddress);
        }

        _tokenIdPerAddress[_nftAddress].push(_tokenId);
        s_listings[_nftAddress][_tokenId] = Listing(0, _owner, false, _nftAddress, _tokenId);

        emit ItemRegistered(_owner, _nftAddress, _tokenId);
    }

    /*
    * @notice Method for unregistering an existing NFT from the marketplace
    * @param _nftAddress Address of NFT contract
    * @param _tokenId Token ID of NFT
    */
    function unregisterItem(
        address _nftAddress,
        uint256 _tokenId
    )
        external
        shouldBeRegistered(_nftAddress, _tokenId)
        isOwnerOrContract(_nftAddress, _tokenId, msg.sender)
    {
        // Remove the item from the list of registered items
        delete s_listings[_nftAddress][_tokenId];

        // Remove the token ID from the array of token IDs for the given NFT address
        uint256[] storage tokenIds = _tokenIdPerAddress[_nftAddress];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == _tokenId) {
                // Swap with the last element and delete
                tokenIds[i] = tokenIds[tokenIds.length - 1];
                tokenIds.pop();
                break;
            }
        }

        // If there are no more registered items for the given NFT address, remove it from the list
        if (tokenIds.length == 0) {
            for (uint256 i = 0; i < nft_addresses.length; i++) {
                if (nft_addresses[i] == _nftAddress) {
                    // Swap with the last element and delete
                    nft_addresses[i] = nft_addresses[nft_addresses.length - 1];
                    nft_addresses.pop();
                    break;
                }
            }
        }

        emit ItemUnregistered(msg.sender, _nftAddress, _tokenId);
    }

    /*
     * @notice Method to list for sale a NFT already known by the marketplace
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
        notListed(_nftAddress, _tokenId)
        isOwner(_nftAddress, _tokenId, msg.sender)
    {
        if (_price <= 0) {
            revert PriceMustBeAboveZero();
        }
        IERC721 nft = IERC721(_nftAddress);
        if (!_isRegistered(_nftAddress, _tokenId)){
            registerItem(_nftAddress, _tokenId);
        }
        if (nft.getApproved(_tokenId) != address(this) && !nft.isApprovedForAll(msg.sender, address(this))) {
            revert NotApprovedForMarketplace();
        }
        Listing storage listedItem = s_listings[_nftAddress][_tokenId];
        listedItem.currentlyListed = true;
        listedItem.price = _price;
  
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

        // Calculate Evermore fees
        uint256 _evermoreValue = SafeMath.div(SafeMath.mul(msg.value, EVERMORE_FEES), 100);

        s_proceeds[listedItem.seller] += msg.value.sub(_royaltiesValue).sub(_evermoreValue);
        listedItem.currentlyListed = false;
        listedItem.seller = msg.sender;
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
        emit withdrawProceeded(msg.sender);
    }

    /////////////////////
    // Setter Functions //
    /////////////////////

    function setEvermoreFees(uint256 _newFees) public onlyOwner {
        require(_newFees > 0 ether, "Cannot set fees to zero");
        EVERMORE_FEES = _newFees;
        emit FeesSet();
    }

    /////////////////////
    // Getter Functions //
    /////////////////////

    /*
     * @notice Method to returns all listed market items
     * @param _nftAddress Address of NFT contract
     * @param _tokenId Token ID of NFT
     * @param _newPrice Price in Wei of the item
     * TODO: to optimize or replace per graph
     */
    function fetchListedItems() public view returns (Listing[] memory) {
      uint256 itemCount = 0;
      uint256 currentIndex = 0;

      for (uint256 i = 0; i < nft_addresses.length; i++) {
        address _nftAddress = nft_addresses[i];
        uint256[] memory ids = _tokenIdPerAddress[_nftAddress];
        for (uint j = 0; j < ids.length; j++) {
          Listing memory listing = s_listings[_nftAddress][ids[j]];
          if (listing.currentlyListed) {
            itemCount += 1;
          }
        }
      }

      Listing[] memory listedItems = new Listing[](itemCount);
      for (uint256 i = 0; i < nft_addresses.length; i++) {
        address _nftAddress = nft_addresses[i];
        uint256[] memory ids = _tokenIdPerAddress[_nftAddress];
        for (uint256 j = 0; j < ids.length; j++) {
          Listing memory listing = s_listings[_nftAddress][ids[j]];
          if (listing.currentlyListed) {
            listedItems[currentIndex] = listing;
            currentIndex += 1;
          }
        }
      }
      return listedItems;
    }

    /*
     * @notice Method to returns all listed market items
     * TODO: to optimize or replace per graph
     */
    function fetchAllItems() public view returns (Listing[] memory) {
      uint256 itemCount = 0;
      uint256 currentIndex = 0;

      for (uint256 i = 0; i < nft_addresses.length; i++) {
        address _nftAddress = nft_addresses[i];
        uint256[] memory ids = _tokenIdPerAddress[_nftAddress];
        for (uint j = 0; j < ids.length; j++) {
          itemCount += 1;
        }
      }

      Listing[] memory _items = new Listing[](itemCount);
      for (uint256 i = 0; i < nft_addresses.length; i++) {
        address _nftAddress = nft_addresses[i];
        uint256[] memory ids = _tokenIdPerAddress[_nftAddress];
        for (uint256 j = 0; j < ids.length; j++) {
          Listing memory listing = s_listings[_nftAddress][ids[j]];
          _items[currentIndex] = listing;
          currentIndex += 1;
        }
      }
      return _items;
    }

    /*
     * @notice Method to returns all items beloging to a specific address
     * @param _userAddress
     * TODO: to optimize or replace per graph
     */
    function fetchUserItems(address _userAddress) public view returns (Listing[] memory) {
      uint256 itemCount = 0;
      uint256 currentIndex = 0;

      for (uint256 i = 0; i < nft_addresses.length; i++) {
        address _nftAddress = nft_addresses[i];
        uint256[] memory ids = _tokenIdPerAddress[_nftAddress];
        for (uint j = 0; j < ids.length; j++) {
          Listing memory listing = s_listings[_nftAddress][ids[j]];
          if (listing.seller == _userAddress) {
            itemCount += 1;
          }
        }
      }

      Listing[] memory _items = new Listing[](itemCount);
      for (uint256 i = 0; i < nft_addresses.length; i++) {
        address _nftAddress = nft_addresses[i];
        uint256[] memory ids = _tokenIdPerAddress[_nftAddress];
        for (uint256 j = 0; j < ids.length; j++) {
          Listing memory listing = s_listings[_nftAddress][ids[j]];
          if (listing.seller == _userAddress) {
          _items[currentIndex] = listing;
            currentIndex += 1;
          }
        }
      }
      return _items;
    }

    function fetchMyItems() public view returns (Listing[] memory) {
      return fetchUserItems(msg.sender);
    }

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

    function getMarketplaceFees() public view returns (uint256) {
        return EVERMORE_FEES;
    }

    function getKnownNFTAddresses() public view returns (address[] memory) {
        return nft_addresses;
    }
}