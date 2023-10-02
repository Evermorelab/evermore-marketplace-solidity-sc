// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

import "../ERC721Lockable.sol";

contract ERC721LockableMock is ERC721Lockable {
    uint256 public TOTAL_SUUPLY = 100;

    constructor(bool _initWithLock) ERC721("MockNFT", "MOCK") {
        if (_initWithLock) {
            _lockAllNFTs(TOTAL_SUUPLY);
        }
    }

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
