// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import "../ERC721UID.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ERC721UIDMock is ERC721UID, ERC721 {

    uint256 public itemSupply;
    
    constructor() ERC721("MockNFT", "MOCK") {
    }

    function mint(address to, uint256 tokenId) external {
        _safeMint(to, tokenId);
    }

    function addItems(uint256 _amount, bytes32 _tokenUID) external {
        uint256 startTokenId = itemSupply + 1; // Make sure to start at 1
        _setUIDTokens(_tokenUID, startTokenId, startTokenId + _amount - 1);
        itemSupply += _amount;
    }

}