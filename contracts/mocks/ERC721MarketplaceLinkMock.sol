// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

import "../ERC721MarketplaceLink.sol";

contract ERC721MarketplaceLinkMock is ERC721MarketplaceLink {
    
    constructor(address _newMarketplaceAddress) ERC721("MockNFT", "MOCK") {
        _setMarketplaceAddress(_newMarketplaceAddress);
    }

    function mint(address to, uint256 tokenId) external {
        _safeMint(to, tokenId);
        _registerOnMarketplace(tokenId);
    }

    function setMarketplaceAddress(address _newMarketplaceAddress) public {
        _setMarketplaceAddress(_newMarketplaceAddress);
    }
}