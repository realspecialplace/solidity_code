// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";

contract CityLight is ERC721 {
    // == ERRORS == //
    error CityLight__IsNotAuthorizedOrApproved(address wallet);
    error CityLight__TokenDoesNotExist(uint256 tokenId);

    // == SYNTACTIC SUGER == //

    // == CUSTOM TYPES == //

    // == STATE VAIABLES == //
    uint256 public sCounter;
    string public sDayTimeImg;
    string public sNightTimeImg;
    mapping(uint256 tokenId => bool tokenImgState) public tokenIdToImg; // bool instead of enum since the state exists only in two ways

    // == EVENTS == //
    event SuccessfullMint(uint256 tokenId);
    
    // == MODIFIERS == //
    modifier checkTokenId(uint256 tokenId) {
        if (tokenId > sCounter-1) revert CityLight__TokenDoesNotExist(tokenId);
        _;
    }

    // == SPECIAL FUNCTIONS == //
    constructor(string memory name, string memory symbol, string memory dayTime, string memory nightTime) ERC721(name, symbol) {
        sDayTimeImg = dayTime;
        sNightTimeImg = nightTime;
        sCounter = 1;
    }

    // == EXTERNAL/PUBLIC FUNCTIONS == //
    function mint() public {
        uint256 currentId = sCounter;
        tokenIdToImg[currentId] = true;
        _mint(msg.sender, currentId);

        sCounter++;
        emit SuccessfullMint(currentId);
    }

    /**
    * @dev This function checks the current nft state and changes it
     */
    function switchTime(uint256 tokenId) public {
        if (!_isAuthorized(ownerOf(tokenId), msg.sender, tokenId)) revert CityLight__IsNotAuthorizedOrApproved(msg.sender);
        if (tokenIdToImg[tokenId] == true) {
            tokenIdToImg[tokenId] = false;
        } else {
            tokenIdToImg[tokenId] = true;
        }
    }

    function tokenURI(uint256 tokenId) public view override checkTokenId(tokenId) returns (string memory) {
        // get the current nft state
        bool state = tokenIdToImg[tokenId];
        string memory tokenImg;
        string memory metadata;

        if (state == true) {
            tokenImg = sDayTimeImg;
            metadata = string.concat(
                '{"name": "',name(),'", "description": "Experience day and night on the Ethereum blockchain", "attributes": [{"trait_type": "Day Time", "value": "Morning"}, "trait_type": "Condition": "Sunny"], "image": "',tokenImg,'"}'
            );
        } else {
            tokenImg = sNightTimeImg;
            metadata = string.concat(
                '{"name": "',name(),'", "description": "Experience day and night on the Ethereum blockchain", "attributes": [{"trait_type": "Day Time", "value": "Night"}, "trait_type": "Condition": "Dawn and cool"], "image": "',tokenImg,'"}'
            );
        }
        // convert metadata to base64 bytes
        string memory metadataBase64 = Base64.encode(abi.encodePacked(metadata));

        return string.concat(
            "",_baseURI(),"",metadataBase64,""
        );
    }
    
    // == INTERNAL/PRIVATE FUNCTIONS == //
    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json; base64,";
    }
}