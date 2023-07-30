//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControlDefaultAdminRules.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "./ERC721UID.sol";
import "./ERC721MarketplaceLink.sol";
import "./HistoryStorage.sol";
import "./SignatureLibrary.sol";

error InvalidSignature();
error SignatureAlreadyUsed();
error InvalidTokenId();
error InvalidSupply();
error InvalidBatchSize();
error InvalidPermissions();

contract EvermoreNFT is ERC721Royalty, ERC721UID, ERC721MarketplaceLink, AccessControlDefaultAdminRules {

    // HISTORY DATA
    // History data for an item corresponding to the item's lifecycle; stored in a separate contract
    // The reading functions are public, but the writing functions are only accessible by the NFT contract
    // The reading functions are not implemented here as the contract is too large
    HistoryStorage public historyStorage;

    // ROLES
    // Role to manage the smart contract such as setting fees, supply, etc.
    // This role is also able to mint NFTs
    bytes32 public constant ADMIN = keccak256("ADMIN");
    // Role to manage the NFT collection such as locking/unlocking NFTs. Can also add events to the NFT lifecycle.
    bytes32 public constant MANAGER = keccak256("MANAGER");
    // Role to allowed to add events in the NFT lifecycle, such as resale, repair, etc.
    bytes32 public constant EVENT_MANAGER = keccak256("EVENT_MANAGER");

    // Allowlist variables
    mapping(bytes => bool) public signatureUsed;

    string public baseURI;
    uint256 public itemSupply;

    event NFTClaimed(uint256 indexed tokenId);
    event SupplySet(uint256 newSupply);
    event BaseURISet(string newBaseURI);

    function _onlyTrusted(uint256 tokenId) private view {
        if (
            ownerOf(tokenId) != _msgSender() &&
            !hasRole(EVENT_MANAGER, _msgSender()) &&
            !hasRole(MANAGER, _msgSender()) &&
            !hasRole(ADMIN, _msgSender())
        ) {
            revert InvalidPermissions();
        }
    }

    function _allowedSignClaim(address _signer) private view {
        if (!hasRole(MANAGER, _signer)) {
            revert InvalidSignature();
        }
    }

    constructor(
        address _marketplaceContract,
        uint256 _itemSupply,
        string memory _baseUID
    )
        ERC721("Evermore NFT", "EVMNFT")
        AccessControlDefaultAdminRules(1, _msgSender()){
        _setMarketplaceAddress(_marketplaceContract);
        _grantRole(ADMIN, _msgSender());
        _grantRole(MANAGER, _msgSender());
        setBaseUID(_baseUID);
        setItemSupply(_itemSupply);
        // Deploy HistoryStorage contract
        historyStorage = new HistoryStorage();
    }

    // TODO: make sure the hash corresponds to the correct tokenId and receiver
    function claim(address _receiver, uint256 _tokenId, bytes32 hash, bytes memory signature) public {
        _allowedSignClaim(SignatureLibrary.recoverSigner(hash, signature));
        if (signatureUsed[signature]) {
            revert SignatureAlreadyUsed();
        }
        signatureUsed[signature] = true;
        _safeMint(_receiver, _tokenId);
        _registerOnMarketplace(_tokenId);
        emit NFTClaimed(_tokenId);
    }

    function addItemEvent(uint256 _tokenId, string memory _eventURI) external {
        _onlyTrusted(_tokenId);
        historyStorage.addItemEvent(_tokenId, _eventURI);
    }

    function addItemCondition(uint256 _tokenId, string memory _conditionURI) external {
        _onlyTrusted(_tokenId);
        historyStorage.addItemCondition(_tokenId, _conditionURI);
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
        if (_newSupply <= 0) {
            revert InvalidSupply();
        }
        itemSupply = _newSupply;
        emit SupplySet(_newSupply);
    }

    function setRoyalty(address _recipient, uint96 _percentage) public onlyRole(ADMIN) {
        _setDefaultRoyalty(_recipient, _percentage);
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

    // Override Functions

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override
    {
        if (batchSize != 1) {
            revert InvalidBatchSize();
        }
        if (tokenId > itemSupply || tokenId < 1 ) {
            revert InvalidTokenId();
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn (uint256 tokenId) internal override(ERC721, ERC721Royalty) {
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