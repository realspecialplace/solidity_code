// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Script } from "forge-std/Script.sol";
import { Heros } from "../src/Heros.sol";

contract DeployHeros is Script {
    Heros heros;

    function run() external returns(Heros) {
        string memory name = "Heros United";
        string memory ticker = "HN";
        string memory tokenUri = "https://ipfs.io/ipfs/bafkreicykyvj5o73uvj7xve3ecoliqr3wzg5zhy64alszsrokp2sms2dc4";
        vm.startBroadcast();
        heros = new Heros(name, ticker, tokenUri);
        vm.stopBroadcast();

        return heros;
    }
}