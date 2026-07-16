// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Test, console } from "forge-std/Test.sol";
import { Anything } from "../src/Anything.sol";
import { DeployAnything } from "../script/DeployAnything.s.sol";

contract TestAnything is Test {
    Anything anything;
    DeployAnything deployer;
    address public user = makeAddr("user");
    // events
    event UserUpdated(string indexed name, string indexed job, uint256 age);

    function setUp() external {
        deployer = new DeployAnything();
        anything = deployer.run();
        // fund user addy
        vm.deal(user, 10e18);
    }

    function testUpdateUserData() public {
        vm.prank(user);
        (string memory status, Anything.User memory userData) = anything.updateUserDetails("John", "Lawyer", 28);
        string memory name = userData.name;
        string memory occupation = userData.occupation;
        uint256 age = userData.age;

        console.log("Status after update: ", status);
        console.log("Hey, my name is %s, I'm a %s years old %s", name, age, occupation);
    }

    function testCheckIndexedEventData() public {
        vm.prank(user);
        vm.expectEmit(true, true, false, false);
        emit UserUpdated("John", "Lawyer", 28);
        (string memory status,) = anything.updateUserDetails("John", "Lawyer", 28);

        assertEq(abi.encodePacked("user info updated"), abi.encodePacked(status));
    }
}