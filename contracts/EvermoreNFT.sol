//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract EvermoreNFT is ERC721URIStorage, ERC721Enumerable, ERC721Royalty, Ownable, ReentrancyGuard {
  
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    address public marketplaceContract;
    address public feesRecipient;
    uint256 public EVERMORE_FEES = 2;
    uint256 public itemPrice;
    string public baseURI;
    uint256 public itemSupply;
    uint96 public royaltyPercentage;
    address public royaltyRecipient;

    event NFTMinted(uint256 tokenId);
    event RoyaltySet(uint96 percentage, address recipient);
    event FeesSet(uint256 newFees, address recipient);
    event SupplySet(uint256 newSupply);
    event PriceSet(uint256 newPrice);

    constructor(address _marketplaceContract, uint256 _itemPrice, uint256 _itemSupply) ERC721("Evermore NFT", "EveNFT") {
        marketplaceContract = _marketplaceContract;
        itemPrice = _itemPrice;
        itemSupply = _itemSupply;
    }

    function mint(string memory _tokenURI) public payable nonReentrant{
        require(_tokenIds.current() < itemSupply, "All items have been sold");
        require(itemPrice <= msg.value, "Not enough payment tokens sent");

        // Send Evermore fees
        uint256 _evermoreValue = SafeMath.div(SafeMath.mul(msg.value, EVERMORE_FEES), 100);
        payable(feesRecipient).transfer(_evermoreValue);

        _tokenIds.increment();
        uint256 _newTokenId = _tokenIds.current();
        _safeMint(msg.sender, _newTokenId);
        _setTokenURI(_newTokenId, _tokenURI);
        setApprovalForAll(marketplaceContract, true);
        emit NFTMinted(_newTokenId);
    }

    /////////////////////
    // Setter Functions //
    /////////////////////

    function setItemPrice(uint256 _newPrice) public onlyOwner {
        require(_newPrice > 0 ether, "Cannot set price to zero");
        itemPrice = _newPrice;
        emit PriceSet(_newPrice);
    }

    function setItemSupply(uint256 _newSupply) public onlyOwner {
        require(_newSupply > 0 ether, "Cannot set supply to zero");
        itemSupply = _newSupply;
        emit SupplySet(_newSupply);
    }

    function setFees(uint256 _newFees, address _recipient) public onlyOwner {
        require(_newFees > 0 ether, "Cannot set fees to zero");
        EVERMORE_FEES = _newFees;
        feesRecipient = _recipient;
        emit FeesSet(_newFees, _recipient);
    }

    function setRoyalty(uint96 _percentage, address _recipient) public onlyOwner {
        royaltyPercentage = _percentage;
        royaltyRecipient = _recipient;
        _setDefaultRoyalty(royaltyRecipient, royaltyPercentage);
        emit RoyaltySet(_percentage, _recipient);
    }

    /////////////////////
    // Getter Functions //
    /////////////////////

    function getFees() public view returns (uint256) {
        return EVERMORE_FEES;
    }

    function getItemPrice() public view returns (uint256) {
        return itemPrice;
    }

    function _baseURI() internal view virtual override(ERC721) returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        //string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId)) : "";
    }

    ////////////////////////
    // Override Functions //
    ////////////////////////

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage, ERC721Royalty) {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

}