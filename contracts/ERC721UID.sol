//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title ERC721 Unique Identifier
 * @dev ERC721 token with unique identifier
 */


abstract contract ERC721UID {

    // Structure to store token range instead of each token ID
    // This is to save gas when minting a large number of tokens
    // Both start and end are inclusive
    struct TokenRange {
        uint256 start;
        uint256 end;
    }

    // Mapping from token UID to token ID
    mapping(bytes32 => TokenRange[]) private _UIDtoTokens;

    event UIDUpdate(bytes32 indexed _baseUID);

    /**
    * @dev Add a new tokens range for a given UID
    * @param _baseUID bytes32 representing the UID
    * @param startToken uint256 representing the start token ID
    * @param endToken uint256 representing the end token ID
    */
    function _setUIDTokens(bytes32 _baseUID, uint256 startToken, uint256 endToken) internal virtual {
        _UIDtoTokens[_baseUID].push(TokenRange(startToken, endToken));
        emit UIDUpdate(_baseUID);
    }

    /**
    * @dev Return the token ranges for a given UID
    * @param _baseUID bytes32 representing the UID
    */
    function getUIDTokens(bytes32 _baseUID) external view virtual returns (TokenRange[] memory) {
        return _UIDtoTokens[_baseUID];
    }

}