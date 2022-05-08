// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Jedi721.sol";
import "./Jedi1155.sol";
import "./Jedi20.sol";


// import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
// import "@openzeppelin/contracts/access/AccessControl.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


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

    constructor(address token20, address token721, address token1155) {
        _erc20 = Jedi20(token20);
        _erc721 = Jedi721(token721);
        _erc1155 = Jedi1155(token1155);
    }

    function createItem(string memory tokenUri) external returns(uint256) {
        uint256 id = _erc721.mint(msg.sender);
        _erc721.setTokenURI(id, tokenUri);

        _items[id].tokenOwner = msg.sender;

        return id;
    }

    function createItem1155(uint256 amount) external returns(uint256) {
        uint256 id = _erc1155.mintNewToken(msg.sender, amount, "");

        _items1155[id].tokenOwner = msg.sender;

        return id;
    }
    

    function listItem(uint256 id, uint256 price) external returns(bool) {
        _erc721.safeTransferFrom(msg.sender, address(this), id);

        Item storage i = _items[id];
        i.listed = true;
        i.price = price;

        return true;
    }

    function listItem1155(uint256 id, uint256 amount, uint256 price) external returns(bool) {
        _erc1155.safeTransferFrom(msg.sender, address(this), id, amount, "");

        Item1155 storage i = _items1155[id];
        i.tokenOwner = msg.sender;
        i.listed = true;
        i.amount = amount;
        i.price = price;

        return true;
    }


    function cancel(uint256 id) external returns(bool) {
        Item storage i = _items[id];
        require(i.tokenOwner == msg.sender, "You are not owner");

        i.listed = false;
        _erc721.safeTransferFrom(address(this), msg.sender, id);

        return true;      
    }

    function cancel1155(uint256 id) external returns(bool) {
        Item1155 storage i = _items1155[id];
        require(i.tokenOwner == msg.sender, "You are not owner");

        i.listed = false;
        _erc1155.safeTransferFrom(address(this), msg.sender, id, i.amount, "");

        return true;      
    }


    function buyItem(uint256 id) external nonReentrant returns(bool) {   
        Item storage i = _items[id];
        require(i.listed, "Item not listed");

        // Check allowance for safety
        _erc20.transferFrom(msg.sender, i.tokenOwner, i.price);
        _erc721.safeTransferFrom(address(this), msg.sender, id);

        i.tokenOwner = msg.sender;
        i.listed = false;

        return true;
    }

    function buyItem1155(uint256 id) external nonReentrant returns(bool) {   
        Item1155 storage i = _items1155[id]; 
        require(i.listed, "Item not listed");

        // Check allowance for safety
        _erc20.transferFrom(msg.sender, i.tokenOwner, i.price);
        _erc1155.safeTransferFrom(address(this), msg.sender, id, i.amount, "");

        i.tokenOwner = msg.sender;
        i.listed = false;

        return true;
    }


    // Auction part
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

    // We don't need this function actually
    // because we can execute cancel feature on finishAuction function
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

    // function backDate(uint256 id) external {
    //     _auctionItems[id].startDate -= 3 days;
    // }

    // function backDate1155(uint256 id) external {
    //     _auctionItems1155[id].startDate -= 3 days;
    // }
}
