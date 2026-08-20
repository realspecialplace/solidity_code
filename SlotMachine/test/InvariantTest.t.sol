// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { StdInvariant } from "forge-std/StdInvariant.sol";
import {Test, console} from "forge-std/Test.sol";
import {DeploySlotMachine} from "../script/DeploySlotMachine.s.sol";
import {SlotMachine} from "../src/Machine.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {Handler} from "./Handler.t.sol";

contract InvariantTest is StdInvariant, Test {
    DeploySlotMachine deployer;
    SlotMachine machine;
    HelperConfig helper = new HelperConfig();
    HelperConfig.NetworkConfig config = helper.getConfig();
    Handler handler;

    function setUp() external {
        deployer = new DeploySlotMachine();
        machine = deployer.run();

        // instanciate handler
        handler = new Handler(machine);
        targetContract(address(handler));
    }

    /**
    * user must have credit before pulling the slot handle,
    * user must wait for outcome before pulling handle again
     */
    function invariant__checkIfContractIsSane() public {
        SlotMachine.State state = machine.sPlayerToState(address(config.sender));
        string memory stateString = (state == SlotMachine.State.BUSY)?"Busy":"User can play";

        console.log(string.concat("Current machine state: ",stateString,""));
    }
}