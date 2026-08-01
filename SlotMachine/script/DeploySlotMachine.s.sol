// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {SlotMachine} from "../src/Machine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {SubscriptionCreator, SubscriptionFunder, ConsumerAdder} from "./Interactions.s.sol";

contract DeploySlotMachine is Script {
    SlotMachine slotMachine;

    function run() external returns (SlotMachine) {
        HelperConfig helper = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helper.getConfig();

        // implement a logic that creates a subscription/funds subscription
        if (config.subId == 0) {
            SubscriptionCreator subCreator = new SubscriptionCreator();
            config.subId = subCreator.createSubscription(config.vrfCoordinator);
            console.log("Subscription Created");

            SubscriptionFunder funder = new SubscriptionFunder();
            funder.fundSubscription(config.subId, config.vrfCoordinator, config.linkToken);
            console.log("Subscription Funded");
        }

        vm.startBroadcast(config.sender);
        // deploy/instanciate slot machine contract
        slotMachine = new SlotMachine(
            config.vrfCoordinator, config.priceFeed, config.keyHash, config.subId, config.callbackGasLimit
        );
        vm.stopBroadcast();
        
         // call and run a function that adds deployed contract as vrf consumer
        ConsumerAdder adder = new ConsumerAdder();
        adder.addConsumer(config.subId, config.vrfCoordinator, address(slotMachine));
        console.log("Consumer Added");
        

        return slotMachine;
    }
}
