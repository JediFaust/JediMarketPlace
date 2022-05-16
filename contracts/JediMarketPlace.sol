// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Jedi721.sol";
import "./Jedi1155.sol";
import "./Jedi20.sol";

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title MarketPlace contract with ERC721 and ERC1155 compatibility
/// @author Omur Kubanychbekov
/// @notice You can use this contract for make your own MarketPlace
/// @dev All functions tested successfully and have no errors
contract JediMarketPlace is ReentrancyGuard, ERC721Holder, ERC1155Holder {
    struct Item {
        address tokenOwner; 
        bool listed;
        uint256 price;
    }

    struct AuctionItem {
        address tokenOwner;
        address lastBuyer;
        uint256 startDate;
        uint256 lastPrice;
        uint256 bids;
    }

    struct Item1155 {
        address tokenOwner; 
        bool listed;
        uint256 price;
        uint256 amount;
    }

    struct AuctionItem1155 {
        address tokenOwner;
        address lastBuyer;
        uint256 startDate;
        uint256 lastPrice;
        uint256 bids;
        uint256 amount;
    }

    mapping(uint256 => Item) private _items;
    mapping(uint256 => AuctionItem) private _auctionItems;

    mapping(uint256 => Item1155) private _items1155;
    mapping(uint256 => AuctionItem1155) private _auctionItems1155;

    Jedi20 private _erc20;
    Jedi721 private _erc721;
    Jedi1155 private _erc1155;

   /// @notice Deploys the contract with the
   /// initial parameters(ERC20 token, ERC721 token, ERC1155 token)
   /// @dev Constructor should be used when deploying contract
   /// @param token20 Address of ERC20 token
   /// @param token721 Address of ERC20 token
   /// @param token1155 Address of ERC20 token
    constructor(address token20, address token721, address token1155) {
        _erc20 = Jedi20(token20);
        _erc721 = Jedi721(token721);
        _erc1155 = Jedi1155(token1155);
    }

   /// @notice Creates new item with given Uri
   /// @param tokenUri Uri of the token
   /// @return id of minted token
    function createItem(string memory tokenUri) external returns(uint256) {
        uint256 id = _erc721.mint(msg.sender);
        _erc721.setTokenURI(id, tokenUri);

        _items[id].tokenOwner = msg.sender;

        return id;
    }

   /// @notice Creates new ERC1155 item with given amount
   /// @param amount Total amount of new token
   /// @return id of minted token
    function createItem1155(uint256 amount) external returns(uint256) {
        uint256 id = _erc1155.mintNewToken(msg.sender, amount, "");

        _items1155[id].tokenOwner = msg.sender;

        return id;
    }
    
   /// @notice Lists ERC721 item for sale
   /// Caller must be the owner of the token
   /// @param id ID of the token
   /// @param price Price of the token as ERC20
   /// @return true if item is listed
    function listItem(uint256 id, uint256 price) external returns(bool) {
        _erc721.safeTransferFrom(msg.sender, address(this), id);

        Item storage i = _items[id];
        i.listed = true;
        i.price = price;

        return true;
    }

   /// @notice Lists ERC1155 item for sale
   /// Caller must be the owner of the token
   /// @param id ID of the token
   /// @param amount Amount of the tokens to be listed
   /// @param price Price of the token as ERC20
   /// @return true if item is listed
    function listItem1155(uint256 id, uint256 amount, uint256 price) external returns(bool) {
        _erc1155.safeTransferFrom(msg.sender, address(this), id, amount, "");

        Item1155 storage i = _items1155[id];
        i.tokenOwner = msg.sender;
        i.listed = true;
        i.amount = amount;
        i.price = price;

        return true;
    }

   /// @notice Cancels listing of ERC721 item
   /// Caller must be the owner of the token
   /// @param id ID of the token
   /// @return true if listing is canceled
    function cancel(uint256 id) external returns(bool) {
        Item storage i = _items[id];
        require(i.tokenOwner == msg.sender, "You are not owner");

        i.listed = false;
        _erc721.safeTransferFrom(address(this), msg.sender, id);

        return true;      
    }

   /// @notice Cancels listing of ERC1155 item
   /// Caller must be the owner of the token
   /// @param id ID of the token
   /// @return true if listing is canceled
    function cancel1155(uint256 id) external returns(bool) {
        Item1155 storage i = _items1155[id];
        require(i.tokenOwner == msg.sender, "You are not owner");

        i.listed = false;
        _erc1155.safeTransferFrom(address(this), msg.sender, id, i.amount, "");

        return true;      
    }

   /// @notice Buys listed ERC721 item
   /// Caller must allow price amount of ERC20 tokens to MarketPlace contract
   /// @param id ID of the token
   /// @return true if item is bought
    function buyItem(uint256 id) external nonReentrant returns(bool) {   
        Item storage i = _items[id];
        require(i.listed, "Item not listed");

        _erc20.transferFrom(msg.sender, i.tokenOwner, i.price);
        _erc721.safeTransferFrom(address(this), msg.sender, id);

        i.tokenOwner = msg.sender;
        i.listed = false;

        return true;
    }

   /// @notice Buys listed ERC1155 item
   /// Caller must allow price amount of ERC20 tokens to MarketPlace contract
   /// Bought amount is limited by the amount set by owner
   /// @param id ID of the token
   /// @return true if item is bought
    function buyItem1155(uint256 id) external nonReentrant returns(bool) {   
        Item1155 storage i = _items1155[id]; 
        require(i.listed, "Item not listed");

        _erc20.transferFrom(msg.sender, i.tokenOwner, i.price);
        _erc1155.safeTransferFrom(address(this), msg.sender, id, i.amount, "");

        i.tokenOwner = msg.sender;
        i.listed = false;

        return true;
    }


   /// @notice Lists ERC721 item for auction with minimum price
   /// Caller must be the owner of the token
   /// @param id ID of the token
   /// @param minPrice minimum price of token on ERC20
   /// @return true if item is listed
    function listItemOnAuction(uint256 id, uint256 minPrice) external returns(bool) {
        require(_items[id].tokenOwner == msg.sender, "You are not owner");
        _erc721.safeTransferFrom(msg.sender, address(this), id, "");

        AuctionItem storage a = _auctionItems[id];
        require(a.startDate == 0, "Item already on auction");
        a.startDate = block.timestamp;
        a.lastPrice = minPrice;
        a.tokenOwner = msg.sender;

        return true;
    }

   /// @notice Lists ERC1155 item for auction with given minimum price and amount
   /// Caller must be the owner of the token
   /// @param id ID of the token
   /// @param amount Amount of the tokens to be listed
   /// @param minPrice minimum price of token on ERC20
   /// @return true if item is listed
    function listItemOnAuction1155(uint256 id, uint256 amount, uint256 minPrice) external returns(bool) {
        _erc1155.safeTransferFrom(msg.sender, address(this), id, amount, "");

        AuctionItem1155 storage a = _auctionItems1155[id];
        require(a.startDate == 0, "Item already on auction");

        a.startDate = block.timestamp;
        a.lastPrice = minPrice;
        a.amount = amount;
        a.tokenOwner = msg.sender;

        return true;
    }

   /// @notice Creates Bid for ERC721 item
   /// Caller must allow price amount of ERC20 tokens to MarketPlace contract
   /// @param id ID of the token
   /// @param price given price of the token as ERC20
   /// must be greater than last price
   /// @return true if Bid is created
    function makeBid(uint256 id, uint256 price) external nonReentrant returns(bool) {
        AuctionItem storage a = _auctionItems[id];
        require(a.startDate != 0 && a.startDate <= block.timestamp + 3 days, "Item not listed");
        require(price > a.lastPrice, "Price lower than last");

        if (a.bids > 0) {
            _erc20.transferFrom(address(this), a.lastBuyer, a.lastPrice);
        } 

        _erc20.transferFrom(msg.sender, address(this), price);

        a.bids += 1;
        a.lastBuyer = msg.sender;
        a.lastPrice = price;
        
        return true;
    }

   /// @notice Creates Bid for ERC1155 item
   /// Caller must allow price amount of ERC20 tokens to MarketPlace contract
   /// @param id ID of the token
   /// @param price given price of the token as ERC20
   /// must be greater than last price
   /// @return true if Bid is created
    function makeBid1155(uint256 id, uint256 price) external nonReentrant returns(bool) {
        AuctionItem1155 storage a = _auctionItems1155[id];
        require(a.startDate != 0 && a.startDate <= block.timestamp + 3 days, "Item not listed");
        require(price > a.lastPrice, "Price lower than last");

        if (a.bids > 0) {
            _erc20.transferFrom(address(this), a.lastBuyer, a.lastPrice);
        } 

        _erc20.transferFrom(msg.sender, address(this), price);

        a.bids += 1;
        a.lastBuyer = msg.sender;
        a.lastPrice = price;
        
        return true;
    }

   /// @notice finishes auction for ERC721 item
   /// Caller must be the owner of the token
   /// Bids count must be more than 2
   /// Sends ERC721 token to last Bidder
   /// Sends ERC20 tokens to token owner
   /// @param id ID of the token
   /// @return true if auction is finishes
    function finishAuction(uint256 id) external nonReentrant returns(bool) {
        AuctionItem storage a = _auctionItems[id];
        require(a.tokenOwner == msg.sender, "You are not owner");
        require(block.timestamp > a.startDate + 3 days, "Auction not finished");
        require(a.bids > 2, "Bids less than 2");

        _erc20.transferFrom(address(this), a.tokenOwner, a.lastPrice);
        _erc721.safeTransferFrom(address(this), a.lastBuyer, id);

        // Cleaning old data for security
        a.startDate = 0;
        a.bids = 0;

        return true;
    }

   /// @notice finishes auction for ERC1155 item
   /// Caller must be the owner of the token
   /// Bids count must be more than 2
   /// Sends ERC1155 tokens of set amount to last Bidder
   /// Sends ERC20 tokens to token owner
   /// @param id ID of the token
   /// @return true if auction is finishes
    function finishAuction1155(uint256 id) external nonReentrant returns(bool) {
        AuctionItem1155 storage a = _auctionItems1155[id];
        require(a.tokenOwner == msg.sender, "You are not owner");
        require(block.timestamp > a.startDate + 3 days, "Auction not finished");
        require(a.bids > 2, "Bids less than 3");

        _erc20.transferFrom(address(this), a.tokenOwner, a.lastPrice);
        _erc1155.safeTransferFrom(address(this), a.lastBuyer, id, a.amount, "");

        // Cleaning old data for security
        a.startDate = 0;
        a.bids = 0;

        return true;
    }

   /// @notice cancels auction for ERC721 item
   /// Caller must be the owner of the token
   /// Bids count must be less than 3
   /// Sends ERC721 token to owner back
   /// Sends ERC20 tokens to last Bidder back
   /// @param id ID of the token
   /// @return true if auction cancels
    function cancelAuction(uint256 id) external nonReentrant returns(bool) {
        AuctionItem storage a = _auctionItems[id];
        require(a.tokenOwner == msg.sender, "You are not owner");
        require(block.timestamp > a.startDate + 3 days, "Auction not finished");
        require(a.bids <= 2, "Bids more than 2");

        _erc20.transferFrom(address(this), a.lastBuyer, a.lastPrice);
        _erc721.safeTransferFrom(address(this), a.tokenOwner, id);

        // Cleaning old data for security
        a.startDate = 0;
        a.bids = 0;

        return true;
    }

   /// @notice cancels auction for ERC1155 item
   /// Caller must be the owner of the token
   /// Bids count must be less than 3
   /// Sends ERC1155 tokens of set amount to owner back
   /// Sends ERC20 tokens to last Bidder back
   /// @param id ID of the token
   /// @return true if auction cancels
    function cancelAuction1155(uint256 id) external nonReentrant returns(bool) {
        AuctionItem1155 storage a = _auctionItems1155[id];
        require(a.tokenOwner == msg.sender, "You are not owner");
        require(block.timestamp > a.startDate + 3 days, "Auction not finished");
        require(a.bids <= 2, "Bids more than 2");

        _erc20.transferFrom(address(this), a.lastBuyer, a.lastPrice);
        _erc1155.safeTransferFrom(address(this), a.tokenOwner, id, a.amount, "");

        // Cleaning old data for security
        a.startDate = 0;
        a.bids = 0;

        return true;
    }
}
