// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
/**
* @title Heros United
* @author 0xgrindpa
* @dev This is an ERC721 contract that uses ipfs to host token metadata
 */
contract Heros is ERC721 {
    // == ERRORS == //
    error Heros__MaxCapacityReached(uint256 currentCountValue);
    error Heros__TokenDoesNotExist(uint256 tokenId);

    // == CUSTOM TYPES == //
    
    // == SYNTACTIC SUGER == //

    // == STATE VARIABLES == //
    uint256 public sTokenCounter;
    string public sTokenUri;
    mapping(uint256 tokenId => string tokenUri) public sIdToUri;

    // == EVENTS == //
    event SuccessfulMint(uint256 indexed tokenId);

    // == MODIFIERS == //
    modifier exists(uint256 tokenId) {
        if (keccak256(abi.encodePacked(sIdToUri[tokenId])) == keccak256(abi.encodePacked(""))) revert Heros__TokenDoesNotExist(tokenId);
        _;
    }

    // == SPECIAL FUNCTIONS == //
    constructor(string memory name, string memory ticker, string memory _tokenUri) ERC721(name, ticker) {
        sTokenCounter = 1;
        sTokenUri = _tokenUri;
    }

    // == PUBLIC/EXTERNAL FUNCTIONS == //
    function mintHero() public {
        if (sTokenCounter == 5) revert Heros__MaxCapacityReached(sTokenCounter);
        uint256 tokenId = sTokenCounter;
        _mint(msg.sender, tokenId);
        sIdToUri[tokenId] = sTokenUri;
        
        emit SuccessfulMint(tokenId);
        sTokenCounter++;
    }

    // == INTERNAL/PRIVATE FUNCTIONS == //

    // == GETTERS == //
    function tokenURI(uint256 tokenId) public view override exists(tokenId) returns(string memory) {
        return sIdToUri[tokenId];
    }

    function getTotalMinted() public view returns (uint256) {
        return sTokenCounter;
    }
}