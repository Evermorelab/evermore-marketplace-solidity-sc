//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


error OnlyPermissionsHistory();

contract HistoryStorageUpgradeable is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    // Mapping of item token ID to array of events
    // Each event is a URI to a JSON file containing the event data (date, description, images etc)
    mapping(uint256 => string[]) private itemEvents;
    // Mapping of item token ID to array of conditions
    // Each condition is a URI to a JSON file containing the condition data (date, description, images etc)
    mapping(uint256 => string[]) private itemConditions;
    address private _nftContract;

    event ItemEventAdded(uint256 indexed tokenId, string eventURI);
    event ItemConditionAdded(uint256 indexed tokenId, string conditionURI);

    modifier onlyNFTContract() {
        if (_nftContract != _msgSender()) {
            revert OnlyPermissionsHistory();
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _contractAddress) initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();

        _nftContract = _contractAddress;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function addItemData(uint256 _tokenId, string memory _uri, bool isCondition) external onlyNFTContract {
        if (isCondition) {
            _addItemCondition(_tokenId, _uri);
        } else {
           _addItemEvent(_tokenId, _uri);
        }
    }

    function _addItemEvent(uint256 _tokenId, string memory _eventURI) internal {
        itemEvents[_tokenId].push(_eventURI);
        emit ItemEventAdded(_tokenId, _eventURI);
    }

    function _addItemCondition(uint256 _tokenId, string memory _conditionURI) internal {
        itemConditions[_tokenId].push(_conditionURI);
        emit ItemConditionAdded(_tokenId, _conditionURI);
    }

    function getItemEvents(uint256 _tokenId) external view returns (string[] memory) {
        return itemEvents[_tokenId];
    }

    function getItemConditions(uint256 _tokenId) external view returns (string[] memory) {
        return itemConditions[_tokenId];
    }
}