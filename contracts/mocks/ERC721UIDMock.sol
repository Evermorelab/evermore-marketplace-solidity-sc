// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import "../ERC721UID.sol";

contract ERC721UIDMock is ERC721UID {
    
    constructor(string memory _baseUID) ERC721("MockNFT", "MOCK") {
        _setbaseUID(_baseUID);
    }

    function mint(address to, uint256 tokenId) external {
        _safeMint(to, tokenId);
    }

}