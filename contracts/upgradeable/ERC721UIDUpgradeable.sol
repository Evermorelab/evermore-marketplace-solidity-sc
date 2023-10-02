//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


error InvalidPermissionsUID();

contract ERC721UIDUpgradeable is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    // Structure to store token range instead of each token ID
    // This is to save gas when minting a large number of tokens
    // Both start and end are inclusive
    struct TokenRange {
        uint256 start;
        uint256 end;
    }
    address private _nftContract;
    // Mapping from token UID to token ID
    mapping(string => TokenRange[]) private _UIDtoTokens;
    string public baseUID;

    event UIDUpdate(string indexed _baseTokenUID);

    modifier onlyNFTContract() {
        if (_nftContract != _msgSender()) {
            revert InvalidPermissionsUID();
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _contractAddress, string memory _baseUID) initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();

        _nftContract = _contractAddress;
        baseUID = _baseUID;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    /**
    * @dev Add a new tokens range for a given UID
    * @param _baseTokenUID bytes32 representing the UID
    * @param startToken uint256 representing the start token ID
    * @param endToken uint256 representing the end token ID
    */
    function setUIDTokens(string memory _baseTokenUID, uint256 startToken, uint256 endToken) external virtual onlyNFTContract {
        _UIDtoTokens[_baseTokenUID].push(TokenRange(startToken, endToken));
        emit UIDUpdate(_baseTokenUID);
    }

    /**
    * @dev Return the token ranges for a given UID
    * @param _baseTokenUID bytes32 representing the UID
    */
    function getUIDTokens(string memory _baseTokenUID) external view virtual returns (TokenRange[] memory) {
        return _UIDtoTokens[_baseTokenUID];
    }

}