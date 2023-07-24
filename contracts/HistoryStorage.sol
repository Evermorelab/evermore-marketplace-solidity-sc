//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title History Data
 * @dev History Data for an item's lifecycle
 * Each item has a history of events (repair, etc) and conditions (product current contition at a point in time)
 */

contract HistoryStorage is Context {

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
        require(
            _nftContract == _msgSender(),
            "HistoryStorage: Only the NFT contract can call this function"
        );
        _;
    }

    constructor() {
        _nftContract = _msgSender();
    }

    function addItemEvent(uint256 _tokenId, string memory _eventURI) external onlyNFTContract {
        itemEvents[_tokenId].push(_eventURI);
        emit ItemEventAdded(_tokenId, _eventURI);
    }

    function addItemCondition(uint256 _tokenId, string memory _conditionURI) external onlyNFTContract {
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