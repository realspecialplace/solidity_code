// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {SubscriptionCreator, SubscriptionFunder, ConsumerAdder} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    Raffle public raffle;
    address vrfCoordinator;
    uint256 interval;
    bytes32 keyHash;
    uint256 subId;
    uint32 callBackGasLimit;
    uint256 entranceFee;
    address linkToken;
    address sender;

    function run() external returns (Raffle) {
        // assign values to declared variables
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        vrfCoordinator = config.vrfCoordinator;
        interval = config.interval;
        keyHash = config.keyHash;
        subId = config.subId;
        callBackGasLimit = config.callBackGasLimit;
        entranceFee = config.entranceFee;
        linkToken = config.linkToken;
        sender = config.account;

        if (block.chainid == 31337) {
            SubscriptionCreator sub = new SubscriptionCreator();
            subId = sub.createSubscription(vrfCoordinator);
        }
        SubscriptionFunder funder = new SubscriptionFunder();
        funder.fundSubscription(vrfCoordinator, linkToken, subId);

        vm.startBroadcast(sender);
        raffle = new Raffle(vrfCoordinator, interval, keyHash, subId, callBackGasLimit, entranceFee);
        vm.stopBroadcast();

        // add deployed ca as consumer
        ConsumerAdder adder = new ConsumerAdder();
        adder.addConsumer(vrfCoordinator, subId, address(raffle));
        console.log("deployed subId: ", subId);
        return raffle;
    }
}
