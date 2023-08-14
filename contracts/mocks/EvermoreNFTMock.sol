// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import "../EvermoreNFT.sol";

contract EvermoreNFTMock is EvermoreNFT {

  constructor() EvermoreNFT(10, "ipfs://aaa") {}
  
  function beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) public {
    _beforeTokenTransfer(from, to, tokenId, batchSize);
  }
}