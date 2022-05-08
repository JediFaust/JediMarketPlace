// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Jedi721 is ERC721URIStorage, AccessControl, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    bytes32 public constant MINTER = keccak256("MINTER");

    constructor() ERC721("JediNFT", "JNFT") {}

    modifier onlyMinter {
        require(hasRole(MINTER, msg.sender), "Caller is not a minter");
        _;
    }

    function setMinter(address minter) external onlyOwner returns(bool) {
        _setupRole(MINTER, minter);

        return true;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/";
    }

    function mint(address to) external onlyMinter returns (uint256) {
        uint256 newItemId = _tokenIds.current();
        _tokenIds.increment();

        _safeMint(to, newItemId);

        return newItemId;
    }

    function setTokenURI(uint256 tokenId, string memory tokenUri) external onlyMinter returns (bool) {
        _setTokenURI(tokenId, tokenUri);

        return true;
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIds.current();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}