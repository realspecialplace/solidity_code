// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { DeployVest } from "../script/DeployVest.s.sol";
import { Vest } from "../src/Vesting.sol";
import { AkaraToken } from "../src/Akara.sol";
import { Test, console } from "forge-std/Test.sol";

contract TestVest is Test {
    Vest vest;
    AkaraToken akara;
    DeployVest deployer;
    // declare user
    address public user = makeAddr("user");
    // declare invariants
    uint256 public akaraAmount = 125e18;

    function setUp() external {
        deployer = new DeployVest();
        (akara, vest) = deployer.run();
        // fund user with eth and akara
        vm.deal(user, 2e18); // fund 2 ether
        akara.transfer(address(akara), user, 200e18); // fund 200 akara
    }

    function testAkaraTokenTotalSupply() public {
        vm.prank(user);
        uint256 supply = akara.totalSupply();
        uint256 expectedSupply = 999999e18;

        console.log("Total supply: %s Akara", supply/1e18);

        assert(supply == expectedSupply);
    }

    function testUserHasEnoughAkara() public {
        vm.prank(user);
        uint256 userAkaraBal = akara.balanceOf(user);

        console.log("User's Akara bal: %s Akara", userAkaraBal/1e18);
    }

    function testSendAkaraToVestVault() public invest {
        // check vest contract akara bal
        uint256 vestCaBal = akara.balanceOf(address(vest));
        assertEq(akaraAmount, vestCaBal);
    }

    function testUseNonAllwedTokenCa() public {
        address randomCa = address(uint160(1));
        vm.startPrank(user);
        akara.approve(address(vest), akaraAmount);
        vm.expectRevert(abi.encodeWithSelector(Vest.Vesting__NotSupportedToken.selector, randomCa));
        vest.vestToken(akaraAmount, randomCa);
        vm.stopPrank();
    }

    function testGetInvestor() public invest {
        vm.prank(user);
        uint256 invested = vest.getInvestorInfo(user);

        console.log("amount invested %s Akara", invested/1e18);
    }

    function testWithdrawal() public invest {
        vm.warp(block.timestamp + 61);
        vm.roll(block.number + 2);
        uint256 withdrawAmount = 5e18; // 5 tokens

        vm.startPrank(user);
        uint256 initialBal = vest.getInvestorInfo(user);
        console.log("Initial bal: %s Akara", initialBal/1e18);

        vest.withdraw(withdrawAmount, address(akara));
        uint256 currentBal = vest.getInvestorInfo(user);
        console.log("current bal: %s Akara", currentBal/1e18);
        vm.stopPrank();
        
        assert(initialBal == (currentBal + withdrawAmount));
    }













    // == modifiers == //
    modifier invest {
        vm.startPrank(user);
        // approve vest contract to pull akara funds from user bal
        akara.approve(address(vest), akaraAmount);
        // initiate vest txn
        vest.vestToken(akaraAmount, address(akara));
        vm.stopPrank();
        _;
    }
}