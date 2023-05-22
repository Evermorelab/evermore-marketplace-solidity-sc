//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Marketplace.sol";


contract EvermoreNFT is ERC721Royalty, Ownable, ReentrancyGuard {
  
    address public marketplaceContract;  // Evermore Marketplace smart contract
    uint256 public EVERMORE_FEES = 2;  // Evemore fees when minting a token
    address public feesRecipient;  // Wallet to receive minting fees
    bool public registerMarketplace = true;  // automatically register token on Evermore Marketplace
    mapping(address => bool) public admins;  // add addtionnal addresses to interact with sensitive functions

    uint256 public itemPrice;
    string public baseURI;
    string public baseUID;
    uint256 public itemSupply;
    bool public initWithLock;  // If true, NFT have to be unlocked before they can be claimed
    uint96 public royaltyPercentage;
    address public royaltyRecipient;

    mapping(uint256 => bool) public NFTLocked; // NFT allowed to be claimed

    event NFTMinted(uint256 indexed tokenId);
    event NFTClaimed(uint256 indexed tokenId);
    event RoyaltySet(uint96 percentage, address recipient);
    event FeesSet(uint256 newFees, address recipient);
    event SupplySet(uint256 newSupply);
    event PriceSet(uint256 newPrice);
    event BaseURISet(string newBaseURI);
    event BaseUIDSet(string newBaseUID);
    event MarketplaceContractSet(address newMarketplaceAddress);
    event NFTLockeded(uint256 tokenId);
    event NFTUnlocked(uint256 tokenId);
    event AdminAdded(address admin);
    event AdminRemoved(address admin);

    modifier onlyOwnerOrAdmin() {
        require(owner() == _msgSender() || admins[_msgSender()], "Only owner or admin can call this function");
        _;
    }

    constructor(address _marketplaceContract, uint256 _itemSupply, string memory _baseUID, bool _initWithLock) ERC721("Evermore NFT", "EVMNFT") {
        marketplaceContract = _marketplaceContract;
        itemSupply = _itemSupply;
        initWithLock = _initWithLock;
        setbaseUID(_baseUID);
        if (initWithLock) {
            lockAllNFTs();  // token are unlocked by default
        }
    }

    function lockAllNFTs() internal {
        // Perform a loop to set true as default value for all keys
        for (uint256 i = 1; i <= itemSupply; i++) {
            NFTLocked[i] = true;
        }
    }

    function mint(address _receiver, uint256 _tokenId) public payable nonReentrant{
        require(itemPrice <= msg.value, "Not enough payment tokens sent");

        // Send Evermore fees
        uint256 _evermoreValue = SafeMath.div(SafeMath.mul(msg.value, EVERMORE_FEES), 100);
        payable(feesRecipient).transfer(_evermoreValue);

        _safeMint(_receiver, _tokenId);
        setApprovalForAll(marketplaceContract, true);
        if (registerMarketplace) {
            EvermoreMarketplace marketplace = EvermoreMarketplace(marketplaceContract);
            marketplace.registerItem(address(this), _tokenId);
        }
        emit NFTMinted(_tokenId);
    }

    function claim(address _receiver, uint256 _tokenId) public {
        require(!NFTLocked[_tokenId], "Token has not be approved for claim");
        _safeMint(_receiver, _tokenId);
        setApprovalForAll(marketplaceContract, true);
        if (registerMarketplace) {
            EvermoreMarketplace marketplace = EvermoreMarketplace(marketplaceContract);
            marketplace.registerItem(address(this), _tokenId);
        }
        emit NFTClaimed(_tokenId);
    }

    function lockNFT(uint256 _tokenId) external onlyOwnerOrAdmin {
        NFTLocked[_tokenId] = true;
        emit NFTLockeded(_tokenId);
    }

    function unlockNFT(uint256 _tokenId) external onlyOwnerOrAdmin {
        NFTLocked[_tokenId] = false;
        emit NFTUnlocked(_tokenId);
    }

    function addAdmin(address _address) external onlyOwner {
        admins[_address] = true;
        emit AdminAdded(_address);
    }

    function removeAdmin(address _address) external onlyOwner {
        admins[_address] = false;
        emit AdminRemoved(_address);
    }

    /////////////////////
    // Setter Functions //
    /////////////////////

    function setbaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
        emit BaseURISet(_newBaseURI);
    }

    function setbaseUID(string memory _newBaseUID) public onlyOwner {
        baseUID = _newBaseUID;
        emit BaseUIDSet(_newBaseUID);
    }

    function setItemPrice(uint256 _newPrice) public onlyOwner {
        require(_newPrice > 0 ether, "Cannot set price to zero");
        itemPrice = _newPrice;
        emit PriceSet(_newPrice);
    }

    function setItemSupply(uint256 _newSupply) public onlyOwner {
        require(_newSupply > 0 ether, "Cannot set supply to zero");
        itemSupply = _newSupply;
        emit SupplySet(_newSupply);
    }

    function setFees(uint256 _newFees, address _recipient) public onlyOwner {
        require(_newFees > 0 ether, "Cannot set fees to zero");
        EVERMORE_FEES = _newFees;
        feesRecipient = _recipient;
        emit FeesSet(_newFees, _recipient);
    }

    function setRoyalty(uint96 _percentage, address _recipient) public onlyOwner {
        royaltyPercentage = _percentage;
        royaltyRecipient = _recipient;
        _setDefaultRoyalty(royaltyRecipient, royaltyPercentage);
        emit RoyaltySet(_percentage, _recipient);
    }

    function setMarketplaceAddress(address _newMarketplaceAddress) public onlyOwner {
        marketplaceContract = _newMarketplaceAddress;
        emit MarketplaceContractSet(_newMarketplaceAddress);
    }

    /////////////////////
    // Getter Functions //
    /////////////////////

    function getFees() public view returns (uint256) {
        return EVERMORE_FEES;
    }

    function getItemPrice() public view returns (uint256) {
        return itemPrice;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId)) : "";
    }

    function tokenUID(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(baseUID).length > 0 ? string(abi.encodePacked(baseUID, "-", tokenId)) : "";
    }

    function isAdminOrOwner(address _user) public view returns (bool) {
        return admins[_user] || owner() == _user;
    }

     function isLocked(uint256 _tokenId) public view returns (bool) {
        return NFTLocked[_tokenId];
    }


}