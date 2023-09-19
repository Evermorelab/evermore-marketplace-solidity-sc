//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./ERC721UID.sol";
import "./HistoryStorage.sol";
import "./SignatureLibrary.sol";
import "./ERC721URIStorageBeforeMint.sol";

error SignatureAlreadyUsed();
error InvalidTokenId();
error InvalidSupply();
error InvalidBatchSize();
error InvalidPermissions();

contract EvermoreNFT is ERC721Royalty, ERC721URIStorageBeforeMint, ERC721UID, AccessControl {

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

    uint256 public itemSupply;

    event NFTClaimed(uint256 indexed tokenId);
    event SupplySet(uint256 newSupply);

    /**
     * @dev _tokenTrusted `tokenId`.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be a manager or an admin to be considered trusted.
     */
    function _tokenTrusted(uint256 tokenId) private view {
        if (
            ownerOf(tokenId) != _msgSender() &&
            !hasRole(MANAGER, _msgSender()) &&
            !hasRole(ADMIN, _msgSender())
        ) {
            revert InvalidPermissions();
        }
    }

    /**
     * @dev _eventTokenTrusted `tokenId`.
     *
     * Requirements:
     *
     * - The caller must be either the owner, a manager, an admin, or an event manager to be considered trusted.
     */
    function _eventTokenTrusted(uint256 tokenId) private view {
        if (!hasRole(EVENT_MANAGER, _msgSender())) {
            _tokenTrusted(tokenId);
        }
    }

    /**
     * @dev _allowedSignClaim `sender`.
     *
     * Requirements:
     *
     * - The caller must be either a manager or an admin to be able to sign a claim.
     */
    function _allowedSignClaim(address _sender) private view {
        if (!hasRole(MANAGER, _sender) && !hasRole(ADMIN, _sender)) {
            revert InvalidPermissions();
        }
    }

    /**
     * @dev Constructor function.
     * Setup the default permissions for the calling address and
     * the marketplace contract, the base URI, and the item supply.
     * Deploy the HistoryStorage contract.
     */

    constructor(
    )
        ERC721("Evermore NFT", "EVMNFT"){
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ADMIN, _msgSender());
        _grantRole(MANAGER, _msgSender());
        // Deploy HistoryStorage contract
        historyStorage = new HistoryStorage();
    }

    // NFT MANAGEMENT FUNCTIONS

    /**
     * @dev claim `tokenId` NFT.
     * @param _receiver address of the receiver.
     * @param _tokenId the token ID of the NFT.
     * @param hash the hash of the token ID and receiver.
     * @param signature the signature of the hash.
     * Claim the NFT by minting it to the receiver and registering it on the marketplace.
     * The signature is used to verify that the token ID and receiver are correct.
     * The signature is also used to prevent replay attacks.
     */

    // TODO: make sure the hash corresponds to the correct tokenId and receiver
    function claim(address _receiver, uint256 _tokenId, bytes32 hash, bytes memory signature) public {
        _allowedSignClaim(SignatureLibrary.recoverSigner(hash, signature));
        if (signatureUsed[signature]) {
            revert SignatureAlreadyUsed();
        }
        signatureUsed[signature] = true;
        _safeMint(_receiver, _tokenId);
        emit NFTClaimed(_tokenId);
    }

    /**
     * @dev addItemEvent
     * @param _tokenId the token ID of the NFT.
     * @param _eventURI the URI of the event.
     * Add an event to the NFT lifecycle.
     * The event is stored in the HistoryStorage contract.
     * Only the owner, a manager, an admin, or an event manager can add an event.
     */
    function addItemEvent(uint256 _tokenId, string memory _eventURI) external {
        _eventTokenTrusted(_tokenId);
        historyStorage.addItemEvent(_tokenId, _eventURI);
    }

    /**
     * @dev addItemCondition
     * @param _tokenId the token ID of the NFT.
     * @param _conditionURI the URI of the condition.
     * Add a condition to the NFT lifecycle.
     * The condition is stored in the HistoryStorage contract.
     * Only the owner, a manager, an admin, or an event manager can add a condition.
     */
    function addItemCondition(uint256 _tokenId, string memory _conditionURI) external {
        _eventTokenTrusted(_tokenId);
        historyStorage.addItemCondition(_tokenId, _conditionURI);
    }

    /**
     * @dev addItems
     * @param _uris the URIs of the items.
     * @param _baseUID the UID of the items.
     * Add a batch of items to the NFT collection.
     * Only a manager or an admin can add items.
     */
    function addItems(bytes32 _baseUID, string[] memory _uris) public onlyRole(MANAGER) {
        // get the next available token ID and set the token URI and UID for each token
        uint256 startTokenId = itemSupply + 1; // Make sure to start at 1
        for (uint256 i = 0; i < _uris.length; i++) {
            uint256 tokenId = startTokenId + i;
            _setTokenURI(tokenId, _uris[i]);
        }
        _setUIDTokens(_baseUID, startTokenId, startTokenId + _uris.length - 1);
        itemSupply += _uris.length;
        emit SupplySet(itemSupply);
    }

    /**
     * @dev updateItems
     * @param _uris the URIs of the items.
     * @param _tokenIds the token IDs of the items.
     * Update a batch of items in the NFT collection.
     * Only a manager or an admin can update items.
     */
    function updateItems(uint256[] memory _tokenIds, string[] memory _uris) public onlyRole(MANAGER) {
        if (_uris.length != _tokenIds.length) {
            revert InvalidBatchSize();
        }
        for (uint256 i = 0; i < _uris.length; i++) {
            _setTokenURI(_tokenIds[i], _uris[i]);
        }
    }

    // Setter Functions

    /**
     * @dev setRoyalty for the NFT collection.
     * @param _recipient the address of the royalty recipient.
     * @param _percentage the percentage of the royalty.
     * Set the royalty of the NFTs.
     * Only an admin can set the royalty.
     */
    function setRoyalty(address _recipient, uint96 _percentage) public onlyRole(ADMIN) {
        _setDefaultRoyalty(_recipient, _percentage);
    }

    /**
     * @dev burn a NFT
     * @param tokenId the token ID of the NFT.
     * Burn the NFT.
     * Only the owner, a manager, or an admin can burn the NFT.
     */
    function burn(uint256 tokenId) public virtual {
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
            _tokenTrusted(tokenId);
        }
        _burn(tokenId);
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

    function _burn(uint256 tokenId) internal override(ERC721Royalty, ERC721URIStorageBeforeMint) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Royalty, AccessControl, ERC721URIStorageBeforeMint)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorageBeforeMint)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

}