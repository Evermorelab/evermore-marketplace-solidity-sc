// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "../ERC721Lockable.sol";

contract ERC721LockableMock is ERC721Lockable {
    constructor() ERC721("MockNFT", "MOCK") {}

    function lockNFT(uint256 tokenId) external {
        _lockNFT(tokenId);
    }

    function unlockNFT(uint256 tokenId) external {
        _unlockNFT(tokenId);
    }

    function mint(address to, uint256 tokenId) external {
        _safeMint(to, tokenId);
    }

}
