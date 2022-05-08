// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Jedi1155 is ERC1155, ERC1155Holder, AccessControl, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256[] private _tokenSupply;

    bytes32 public constant MINTER = keccak256("MINTER");

    constructor() ERC1155("https://gateway.pinata.cloud/ipfs/QmVWndwuTwR57dTc3DKzKRQ3uMYGdX1QjBE3Pbrm7JwQ67/{uri}.json") {}

    modifier onlyMinter {
        require(hasRole(MINTER, msg.sender), "Caller is not a minter");
        _;
    }

    function setMinter(address minter) external onlyOwner returns(bool) {
        _setupRole(MINTER, minter);

        return true;
    }

    function mintNewToken(address to, uint256 amount, bytes memory data) external onlyMinter returns(uint256) {
        uint256 newItemId = _tokenIds.current();
        _tokenIds.increment();

        _mint(to, newItemId, amount, data);
        _tokenSupply.push(amount);

        return newItemId;
    }

    function mintTokenById(address to, uint256 id, uint256 amount, bytes memory data) external onlyMinter returns(bool) {
        require(id < _tokenIds.current(), "Invalid ID");

        _mint(to, id, amount, data);
        _tokenSupply[id] += amount;

        return true;
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIds.current();
    }

    function tokenSupply(uint256 id) external view returns (uint256) {
        return _tokenSupply[id];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC1155Receiver, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
}
