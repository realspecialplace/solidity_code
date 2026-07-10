// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Vest } from "../src/Vesting.sol";
import { AkaraToken } from "../src/Akara.sol";
import { Script } from "forge-std/Script.sol";

contract DeployVest is Script {
    Vest vest;
    AkaraToken akara;
    address[] tokens;

    function run() external returns (AkaraToken, Vest) {
        uint256 initialSupply = 999999e18;
        uint256 vestingPeriod = 3600; // 1hr
        uint256 nextWithdrawTime = 60; // 1min
        uint256 chunkPerSection = 5e18; // 5 tokens
        uint256 minAmount = 100e18;
        akara = new AkaraToken();
        akara.mint(address(akara), initialSupply);
        
        tokens.push(address(akara));

        vm.startBroadcast();
        vest = new Vest(minAmount, vestingPeriod, nextWithdrawTime, chunkPerSection, tokens);
        vm.stopBroadcast();

        return (akara, vest);
    }
}