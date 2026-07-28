// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Test, console } from "forge-std/Test.sol";
import { DeploySlotMachine } from "../script/DeploySlotMachine.s.sol";
import { SlotMachine } from "../src/Machine.sol";

contract TestSlotMachine is Test {
    SlotMachine machine;
    DeploySlotMachine deployer;

    address public user = makeAddr("user");

    function setUp() external {
        deployer = new DeploySlotMachine();
        machine = deployer.run();

        // fund user
        vm.deal(user, 5e18);
    }

    function testPricePerStop() public {
        uint256 stopIndex = 40;

        vm.prank(user);
        string memory price = machine.getPricePerStop(stopIndex);

        console.log("Stop %s has a value of '%s'", stopIndex, price);
    }
}