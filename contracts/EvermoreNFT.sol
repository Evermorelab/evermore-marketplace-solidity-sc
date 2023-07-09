//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControlDefaultAdminRules.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "./ERC721Lockable.sol";
import "./ERC721UID.sol";
import "./ERC721MarketplaceLink.sol";


contract EvermoreNFT is ERC721Royalty, ERC721UID, ERC721Lockable, ERC721MarketplaceLink, AccessControlDefaultAdminRules {
  
    // ROLES
    // Role to manage the smart contract such as setting fees, supply, etc.
    // This role is also able to mint NFTs
    bytes32 public constant ADMIN = keccak256("ADMIN");
    // Role to manage the NFT collection such as locking/unlocking NFTs. Can also add events to the NFT lifecycle.
    bytes32 public constant MANAGER = keccak256("MANAGER");
    // Role to allowed to add events in the NFT lifecycle, such as resale, repair, etc.
    bytes32 public constant EVENT_MANAGER = keccak256("EVENT_MANAGER");

    string public baseURI;
    uint256 public itemSupply;

    // store the different events happening to an NFT during the corresponding item lifecycle
    // Each event is a link to the event metadata {timestamp, event description, images, etc.}
    mapping(uint256 => string[]) public itemEvents;


    event NFTClaimed(uint256 indexed tokenId);
    event SupplySet(uint256 newSupply);
    event BaseURISet(string newBaseURI);
    event ItemEventAdded(uint256 indexed tokenId, string eventURI);

    modifier onlyTrusted(uint256 tokenId) {
        require(
            (ownerOf(tokenId) == _msgSender() ||
            hasRole(EVENT_MANAGER, _msgSender()) ||
            hasRole(MANAGER, _msgSender()) ||
            hasRole(ADMIN, _msgSender())
            ),
            "Missing required role");
        _;
    }

    constructor(
        address _marketplaceContract,
        uint256 _itemSupply,
        string memory _baseUID,
        bool _initWithLock)
        ERC721("Evermore NFT", "EVMNFT")
        AccessControlDefaultAdminRules(1, _msgSender()){
        _setMarketplaceAddress(_marketplaceContract);
        _grantRole(ADMIN, _msgSender());
        _grantRole(MANAGER, _msgSender());
        setBaseUID(_baseUID);
        setItemSupply(_itemSupply);
        if (_initWithLock) {
            _lockAllNFTs(itemSupply); // lock all NFTs by default
        }
    }

    function claim(address _receiver, uint256 _tokenId) public {
        _safeMint(_receiver, _tokenId);
        _registerOnMarketplace(_tokenId);
        emit NFTClaimed(_tokenId);
    }

    function lockNFT(uint256 _tokenId) external onlyRole(MANAGER) {
        _lockNFT(_tokenId);
    }

    function unlockNFT(uint256 _tokenId) external onlyRole(MANAGER) {
        _unlockNFT(_tokenId);
    }

    function addItemEvent(uint256 _tokenId, string memory _eventURI) external onlyTrusted(_tokenId) {
        itemEvents[_tokenId].push(_eventURI);
        emit ItemEventAdded(_tokenId, _eventURI);
    }

    // Setter Functions

    function setBaseURI(string memory _newBaseURI) public onlyRole(ADMIN) {
        baseURI = _newBaseURI;
        emit BaseURISet(_newBaseURI);
    }

    function setBaseUID(string memory _newBaseUID) public onlyRole(ADMIN) {
        _setbaseUID(_newBaseUID);
    }

    function setItemSupply(uint256 _newSupply) public onlyRole(ADMIN) {
        require(_newSupply > 0 ether, "Cannot set supply to zero");
        itemSupply = _newSupply;
        emit SupplySet(_newSupply);
    }

    function setRoyalty(address _recipient, uint96 _percentage) public onlyRole(ADMIN) {
        _setDefaultRoyalty(_recipient, _percentage);
    }

    function setMarketplaceAddress(address _newMarketplaceAddress) public onlyRole(ADMIN) {
        _setMarketplaceAddress(_newMarketplaceAddress);
    }

    // Getter Functions

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721)
        returns (string memory)
    {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId)) : "";
    }

    function getItemEvents(uint256 _tokenId) external view returns (string[] memory) {
        return itemEvents[_tokenId];
    }

    // Override Functions

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Lockable)
    {
        require(batchSize == 1, "Batch size must be 1");
        require(tokenId <= itemSupply, "Token ID is greater than supply");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn (uint256 tokenId) internal override(ERC721, ERC721Lockable, ERC721Royalty) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Royalty, AccessControlDefaultAdminRules)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}