//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// Custom contracts
import "./ERC721UIDUpgradeable.sol";
import "./HistoryStorageUpgradeable.sol";
import "./ERC721URIStorageBeforeMintUpgradeable.sol";
import "../SignatureLibrary.sol";

error SignatureAlreadyUsed();
error InvalidTokenId();
error InvalidSupply();
error InvalidBatchSize();
error InvalidPermissions();

contract EvermoreNFTUpgradeable is Initializable, ERC721RoyaltyUpgradeable, ERC721URIStorageBeforeMintUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {

    // HISTORY DATA
    // History data for an item corresponding to the item's lifecycle; stored in a separate contract
    // The reading functions are public, but the writing functions are only accessible by the NFT contract
    // The reading functions are not implemented here as the contract is too large
    HistoryStorageUpgradeable public historyStorage;

    // UID DATA
    ERC721UIDUpgradeable public uidContract;

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

    // SETUP FUNCTIONS

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializer function.
     * Run the initialisations and setup the default permissions for the calling address
     */

    function initialize() initializer public {
        __ERC721_init("Evermore NFT", "EVMNFT");
        __ERC721URIStorage_init();
        __ERC721Royalty_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ADMIN, _msgSender());
        _grantRole(MANAGER, _msgSender());
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(ADMIN)
        override
    {}

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
        address _signer = SignatureLibrary.recoverSigner(hash, signature);
        if (!hasRole(MANAGER, _signer) && !hasRole(ADMIN, _signer)) {
            revert InvalidPermissions();
        }
        if (signatureUsed[signature]) {
            revert SignatureAlreadyUsed();
        }
        signatureUsed[signature] = true;
        _safeMint(_receiver, _tokenId);
        emit NFTClaimed(_tokenId);
    }

    /**
     * @dev addItemData
     * @param _tokenId the token ID of the NFT.
     * @param _dataURI the URI of the event.
     * @param isCondition whether the data is a condition. If not, it is a general event.
     * Add data into the NFT lifecycle.
     * The event is stored in the HistoryStorage contract.
     * Only the owner, a manager, an admin, or an event manager can add an event.
     */
    function addItemData(uint256 _tokenId, string memory _dataURI, bool isCondition) external {
        if (!hasRole(EVENT_MANAGER, _msgSender())) {
            _tokenTrusted(_tokenId);
        }
        historyStorage.addItemData(_tokenId, _dataURI, isCondition);
    }

    /**
     * @dev addItems
     * @param _uris the URIs of the items.
     * @param _baseUID the UID of the items.
     * Add a batch of items to the NFT collection.
     * Only a manager or an admin can add items.
     */
    function addItems(string memory _baseUID, string[] memory _uris) public onlyRole(MANAGER) {
        // get the next available token ID and set the token URI and UID for each token
        uint256 startTokenId = itemSupply + 1; // Make sure to start at 1
        for (uint256 i = 0; i < _uris.length; i++) {
            uint256 tokenId = startTokenId + i;
            _setTokenURI(tokenId, _uris[i]);
        }
        uidContract.setUIDTokens(_baseUID, startTokenId, startTokenId + _uris.length - 1);
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
     * @dev setHistoryStorage
     * @param _historyStorage the address of the HistoryStorage contract.
     * Set the address of the HistoryStorage contract.
     * Only an admin can set the address.
     */
    function setHistoryStorage(address _historyStorage) public onlyRole(ADMIN) {
        historyStorage = HistoryStorageUpgradeable(_historyStorage);
    }

    /**
     * @dev setUIDContract
     * @param _uidContract the address of the UID contract.
     * Set the address of the UID contract.
     * Only an admin can set the address.
     */
    function setUIDContract(address _uidContract) public onlyRole(ADMIN) {
        uidContract = ERC721UIDUpgradeable(_uidContract);
    }

    // Override Functions

    function _burn(uint256 tokenId) internal override(ERC721RoyaltyUpgradeable, ERC721URIStorageBeforeMintUpgradeable) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override
    {
        if (batchSize != 1 && from == address(0)) {
             revert InvalidBatchSize();
        }
        if (tokenId > itemSupply || tokenId < 1 || bytes(tokenURI(tokenId)).length == 0 ) {
            revert InvalidTokenId();
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721RoyaltyUpgradeable, AccessControlUpgradeable, ERC721URIStorageBeforeMintUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721URIStorageBeforeMintUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

}