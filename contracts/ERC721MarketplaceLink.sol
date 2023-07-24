//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./Marketplace.sol";


/**
 * @title ERC721 Marketplace Link
 * @dev ERC721 token linked to Evermore Marketplace
 * Each token is automatically registered on Evermore Marketplace and approved for trading
 */

abstract contract ERC721MarketplaceLink is ERC721 {
    
    address public marketplaceAddress;  // Evermore Marketplace smart contract
    bool public shouldRegisterMarketplace = true;  // automatically register token on Evermore Marketplace

    event MarketplaceContractSet(address newMarketplaceAddress);
    event MarketplaceRegistrationSet(bool shouldRegisterMarketplace);
    event NFTRegistered(address indexed nftAddress, uint256 indexed tokenId);

    function _setRegisterMarketplace(bool _shouldRegisterMarketplace) internal virtual {
        shouldRegisterMarketplace = _shouldRegisterMarketplace;
        emit MarketplaceRegistrationSet(shouldRegisterMarketplace);
    }

    function _setMarketplaceAddress(address _newMarketplaceAddress) internal virtual {
        marketplaceAddress = _newMarketplaceAddress;
        emit MarketplaceContractSet(_newMarketplaceAddress);
    }

    function _registerOnMarketplace(uint256 tokenId) internal virtual {
        if (shouldRegisterMarketplace) {
            setApprovalForAll(marketplaceAddress, true);
            EvermoreMarketplace marketplace = EvermoreMarketplace(marketplaceAddress);
            marketplace.registerItem(address(this), tokenId);
            emit NFTRegistered(address(this), tokenId);
        }
    }

}