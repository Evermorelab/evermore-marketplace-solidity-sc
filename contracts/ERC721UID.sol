//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title ERC721 Unique Identifier
 * @dev ERC721 token with unique identifier
 */


abstract contract ERC721UID is ERC721 {
    
    string public baseUID;

    event BaseUIDSet(string newBaseUID);

    function _setbaseUID(string memory _newBaseUID) internal virtual {
        baseUID = _newBaseUID;
        emit BaseUIDSet(_newBaseUID);
    }

    function tokenUID(uint256 tokenId)
        external
        view
        virtual
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721UID: UID query for nonexistent token");
        return bytes(baseUID).length > 0 ? string(abi.encodePacked(baseUID, "-", tokenId)) : "";
    }

}