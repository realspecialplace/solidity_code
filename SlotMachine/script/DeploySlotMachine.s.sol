// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {SlotMachine} from "../src/Machine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeploySlotMachine is Script {
    SlotMachine slotMachine;

    function run() external returns (SlotMachine) {
        HelperConfig helper = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helper.getConfig();

        vm.startBroadcast();
        slotMachine = new SlotMachine(
            config.vrfCoordinator, config.priceFeed, config.keyHash, config.subId, config.callbackGasLimit
        );
        vm.stopBroadcast();

        return slotMachine;
    }
}
