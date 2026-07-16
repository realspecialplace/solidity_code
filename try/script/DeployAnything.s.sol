// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Script } from "forge-std/Script.sol";
import { Anything } from "../src/Anything.sol";

contract DeployAnything is Script {
    Anything anything;

    function run() external returns (Anything) {
        vm.startBroadcast();
        anything = new Anything();
        vm.stopBroadcast();

        return anything;
    }
}