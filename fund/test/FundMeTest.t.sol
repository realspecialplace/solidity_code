// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Test, console } from "../lib/forge-std/src/Test.sol";
import { FundMe } from "../src/Fund.sol";
import { DeployFundMe } from "../script/FundMe.s.sol";

contract TestFundMe is Test {
    FundMe public fundMe;
    DeployFundMe public deployer;
    address public USER = makeAddr("user");

    function setUp() public {
        vm.deal(USER, 10e18);
        deployer = new DeployFundMe();
        fundMe = deployer.run();
    }

    function testRevertsWhenLowFundIsSent() public {
        vm.startPrank(USER);
        vm.expectRevert(FundMe.FundMe__NotEnoughFund.selector);
        fundMe.fund{value: 0.01e18}();
        vm.stopPrank();
    }

    function testFundingIsWorking() public {
        if (block.chainid == 11155111) {
            uint256 pk = vm.envUint("SEPOLIA_PK");
            USER = vm.rememberKey(pk);
        }
        vm.startPrank(USER);
        fundMe.fund{value: 0.025 ether}();
        uint256 nOfFunders = fundMe.getFunders().length;
        vm.stopPrank();

        assert(nOfFunders == 1);
    }

    function testPriceOfEth() public {
        if (block.chainid != 31337) {
            return;
        }
        vm.prank(USER);
        uint256 ethPrice = fundMe.getEthPrice();

        assert(ethPrice == 2000e18);
    }

    function testGetEthAmountInUsd() public {
        vm.prank(USER);
        uint256 ethAmount = 0.025 ether;
        uint256 usdValue = fundMe.convertEthToUsd(ethAmount);

        console.log("wei size:", ethAmount);
        console.log(usdValue);
    }
}