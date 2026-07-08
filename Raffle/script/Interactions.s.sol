// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {LinkToken} from "./mocks/MockLinkToken.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

contract SubscriptionCreator is Script {
    function createSubscriptionWithConfig() public returns (uint256 subId) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;

        subId = createSubscription(vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator) public returns (uint256) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getConfig();
        address sender = networkConfig.account;

        console.log("creating subscription...");
        vm.startBroadcast(sender);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        return subId;
    }

    function run() public {
        createSubscriptionWithConfig();
    }
}

// fund subscription
contract SubscriptionFunder is Script {
    uint256 constant FUND_AMOUNT = 3 ether;
    HelperConfig public helper = new HelperConfig();
    HelperConfig.NetworkConfig public config = helper.getConfig();
    address public linkToken = config.linkToken;
    uint256 public subId = config.subId;
    address public vrfCoordinator = config.vrfCoordinator;
    address public sender = config.account;

    function fundSubscriptionUsingConfig() public {
        console.log("funding subscription");
        fundSubscription(vrfCoordinator, linkToken, subId);
    }

    function fundSubscription(address vrfCoordinator, address linkToken, uint256 subId) public {

        if (block.chainid == 31337) {
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subId, FUND_AMOUNT);
        } else {
            vm.startBroadcast(sender);
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

// consumer adder
contract ConsumerAdder is Script {
    function addConsumer(address vrfCoordinator, uint256 subId, address consumerCA) public {
        HelperConfig helper = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helper.getConfig();
        address sender = config.account;
        // the .addConsumer() method will work for sepolia too or any other evm chain because
        // it runs thesame code as real network implementation
        console.log("Adding consumer: ", consumerCA);
        vm.startBroadcast(sender);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, consumerCA);
        vm.stopBroadcast();
    }

    function run() public {
        HelperConfig helper = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helper.getConfig();
        uint256 subId = config.subId;
        address vrfCoordinator = config.vrfCoordinator;
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        
        addConsumer(vrfCoordinator, subId, mostRecentlyDeployed);
    }
}
