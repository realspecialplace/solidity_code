// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Script } from "forge-std/Script.sol";
import { DevOpsTools } from "../lib/foundry-devops/src/DevOpsTools.sol";
import { Heros } from "../src/Heros.sol";

contract MintHero is Script {
    function mintHero(address deployedAddy) public {
        Heros(deployedAddy).mintHero();
    }

    function run() external {
        address deployed = DevOpsTools.get_most_recent_deployment("Heros", block.chainid);
        mintHero(deployed);
    }
}

//deployed anvil ca: 0x5FbDB2315678afecb367f032d93F642f64180aa3
// deployed sepolia ca: 0x89aDdde211AFF45418CC06C347080460a624665b