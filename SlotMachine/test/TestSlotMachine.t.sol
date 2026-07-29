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

    function testMinDepositValue() public {
        uint256 weiAmount = 0.0075e18;
        uint256 minDeposit = 15e18; // 15 dollars using 18 decimals

        vm.prank(user);
        uint256 usdEquivalent = machine.getCredit{value: weiAmount}();

        assert(usdEquivalent >= minDeposit);
    }

    function testGettingUsdPrice() public {
        vm.prank(user);
        uint256 usdPrice = machine.getUsdPrice();

        console.log("Eth USD Price: ", usdPrice);
    }

    function testgetCredit() public {
        uint256 weiAmount = 0.0075e18;

        vm.startPrank(user);
        uint256 USDPrice = machine.getUsdPrice();
        uint256 usdEquivalent = machine.getCredit{value: weiAmount}();
        vm.stopPrank();

        console.log("USD equivalence of %s wei: $%s @ $%s per eth", weiAmount, usdEquivalent/1e18, USDPrice/1e8);
    }
}