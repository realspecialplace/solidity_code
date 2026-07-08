// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { AkaraToken } from "./Akara.sol";

contract Vest {
    // == ERRORS == //
    error Vesting__NotSupportedToken(address tokenCA);

    // == CUSTOM TYPES == //
    // == STATE VARIABLES == //
    uint256 public immutable i_vestPeriod; // in sec
    mapping(address allowedCa => uint256 state) public allowedTokenCAs;

    // == SPECIAL FUNCTIONS == //
    constructor(uint256 vestPeriod, address[] memory _allowedTokenCAs) {
        i_vestPeriod = vestPeriod;

        for (uint256 i=0; i < _allowedTokenCAs.length; i++) {
            allowedTokenCAs[_allowedTokenCAs[i]] = 1;
        }
    }

    // == MODIFIERS == //
    modifier notAllowedToken(address tokenCA) {
        if (allowedTokenCAs[tokenCA] != 1) {
            revert Vesting__NotSupportedToken(tokenCA);
        }
        _;
    }

    // == PUBLIC/EXTERNAL FUNCTIONS == //
    function vestToken(uint256 akaraAmount, address tokenCA) external notAllowedToken(tokenCA) {
        AkaraToken(tokenCA).transfer(msg.sender, address(this), akaraAmount);
    }
}