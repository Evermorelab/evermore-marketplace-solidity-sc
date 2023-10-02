// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
* @dev Contract module which allows children to lock and unlock specific NFTs.
*
* The module makes sure an NFT cannot be transferred if it is locked.
*
* This module is used through inheritance. It will make available the modifiers
* `whenNotLocked` and `whenLocked`, which can be applied to the functions of
* your contract.
* 
*/

error InvalidNFTLockState();


abstract contract ERC721Lockable is ERC721 {

    mapping(uint256 => bool) public NFTLocked;

    event NFTLockeded(uint256 tokenId);
    event NFTUnlocked(uint256 tokenId);

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        for (uint256 i = 0; i < batchSize; i++) {
            _requireNotLocked(firstTokenId + i);
        }
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _burn (uint256 tokenId) internal virtual override {
        NFTLocked[tokenId] = false;
        super._burn(tokenId);
    }

    function _requireNotLocked(uint256 tokenId) internal view virtual {
        if (NFTLocked[tokenId]) {
            revert InvalidNFTLockState();
        }
    }

    function _requireLocked(uint256 tokenId) internal view virtual {
        if (!NFTLocked[tokenId]) {
            revert InvalidNFTLockState();
        }
    }

    function _lockAllNFTs(uint256 itemSupply) internal {
        // Perform a loop to set true as default value for all keys
        for (uint256 i = 1; i <= itemSupply; i++) {
          NFTLocked[i] = true;
        }
    }

    function _lockNFT(uint256 _tokenId) internal virtual {
        _requireNotLocked(_tokenId);
        NFTLocked[_tokenId] = true;
        emit NFTLockeded(_tokenId);
    }

    function _unlockNFT(uint256 _tokenId) internal virtual {
        _requireLocked(_tokenId);
        NFTLocked[_tokenId] = false;
        emit NFTUnlocked(_tokenId);
    }

    function isLocked(uint256 _tokenId) external view returns (bool) {
        return NFTLocked[_tokenId];
    }
}