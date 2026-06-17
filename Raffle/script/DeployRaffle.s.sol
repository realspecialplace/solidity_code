// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";

contract DeployRaffle is Script {
    Raffle public raffle;
    function run() external returns (Raffle) {
        vm.startBroadcast();
        raffle = new Raffle(address(0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B), 20);
        vm.stopBroadcast();
        return raffle;
    }
}