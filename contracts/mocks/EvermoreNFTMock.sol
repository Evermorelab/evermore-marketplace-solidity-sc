// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

import "../deprecated/EvermoreNFT.sol";

contract EvermoreNFTMock is EvermoreNFT {
    constructor() EvermoreNFT() {}

    function beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) public {
        _beforeTokenTransfer(from, to, tokenId, batchSize);
    }
}
