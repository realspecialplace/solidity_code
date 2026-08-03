// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract MagicNumbers {
    uint256 public constant ANVIL_CHAIN = 31337;
    uint256 public constant SEPOLIA_CHAIN = 11155111;
    uint256 public constant FUNDING = 20e18;

    HelperConfig helper = new HelperConfig();
    HelperConfig.NetworkConfig config = helper.getConfig();
}

contract SubscriptionCreator is MagicNumbers, Script {
    error SubscriptionCreator__NotImplementedChain(uint256 chainId);

    function createSubscription (address vrfCoordinator) external returns (uint256 subId) {
        if (block.chainid == ANVIL_CHAIN) {
            console.log("Creating Subscription...");
            vm.startBroadcast(config.sender);
            subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
            vm.stopBroadcast();
        } else {
            revert SubscriptionCreator__NotImplementedChain(block.chainid);
        }
    }
}

contract SubscriptionFunder is MagicNumbers, Script {

    function fundSubscription(uint256 subId, address vrfCoordinator, address linkToken) external {
        if (block.chainid == ANVIL_CHAIN) {
            console.log("Funding subscription...");
            vm.startBroadcast(config.sender);
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subId, FUNDING);
            vm.stopBroadcast();
            return;
        } 
        console.log("Funding subscription...");
        vm.startBroadcast(config.sender);
        LinkTokenInterface(linkToken).transferAndCall(vrfCoordinator, FUNDING, abi.encode(subId));
        vm.stopBroadcast();
    }
}

contract ConsumerAdder is MagicNumbers, Script {

    function addConsumer(uint256 subId, address vrfCoordinator, address consumer) external {
        console.log("Adding Consumer...");
        if (block.chainid == ANVIL_CHAIN) {
            vm.startBroadcast(config.sender);
            VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, consumer);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(config.sender);
            IVRFCoordinatorV2Plus(vrfCoordinator).addConsumer(subId, consumer);
            vm.stopBroadcast();
        }
    }
}