// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AkaraToken is ERC20 {
    constructor() ERC20("AkaraToken", "AKARA"){}
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function transfer(address from, address to, uint256 value) external {
        _transfer(from, to, value);
    }
}