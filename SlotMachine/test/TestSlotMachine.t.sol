// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console, Vm} from "forge-std/Test.sol";
import {DeploySlotMachine} from "../script/DeploySlotMachine.s.sol";
import {SlotMachine} from "../src/Machine.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract TestSlotMachine is Test {
    SlotMachine machine;
    DeploySlotMachine deployer;
    uint256 public weiAmount = 0.008e18;
    // instanciate helper config, get network config
    HelperConfig helper = new HelperConfig();
    HelperConfig.NetworkConfig config = helper.getConfig(); // get config based on deployed chain

    address public owner = config.sender;

    address public user = makeAddr("user");

    event MoreCreditAdded(uint256 indexed credits);

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

    function testAddingCredit() public getCredit {
        vm.prank(user);
        uint256 currentCredit = machine.getCreditBalance(user);

        console.log("Credit Balance: ", currentCredit);
    }

    function testCheckingWrongUserbalance() public getCredit {
        address user2 = makeAddr("user2");

        vm.expectRevert(abi.encodeWithSelector(SlotMachine.Machine__NotValidUser.selector, user2));
        machine.getCreditBalance(user2);
    }

    function testGetCreditEventAndCheckEventLog() public {
        vm.startPrank(user);
        uint256 expectedCredit = machine.getCredit{value: weiAmount}();

        vm.expectEmit(true, false, false, false);
        emit MoreCreditAdded(expectedCredit);
        vm.recordLogs();
        machine.getCredit{value: weiAmount}();
        Vm.Log[] memory entries = vm.getRecordedLogs();
        vm.stopPrank();

        uint256 credit = uint256(entries[0].topics[1]);
        console.log("Credits in log: ", credit);
        assertEq(expectedCredit, credit);
    }

    function testCheckContractBalanceAfterDeposit() public getCredit {
        uint256 contractBal = address(machine).balance;

        console.log("Contract bal: %s wei", contractBal);
    }

    function testPullingHandleToPlay() public getCredit {
        uint256 creditAmount = 1600e18;

        vm.prank(user);
        uint256 requestId = machine.pullHandle(creditAmount);
        console.log("Reques ID: ", requestId);
    }

    function testGetSubId() public view {
        uint256 subId = machine.getSubscriptionId();

        console.log("Sub id: ", subId);
    }

    function testUsingAnyRequestIdToRetrieveRandomNumbers(uint256 requestId) public getCredit {
        if (block.chainid != 31337) return;

        requestId = bound(requestId, 1, 300);

        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(config.vrfCoordinator).fulfillRandomWords(requestId, address(machine));
        //console.log("Words: ", words);
    }

    function testCreditBalReduceAfterPlay() public getCredit {
        uint256 creditAmount = 500e18;
        uint256 initialBal = machine.getCreditBalance(user);

        vm.prank(user);
        uint256 id = machine.pullHandle(creditAmount);

        uint256 finalBal = machine.getCreditBalance(user);

        console.log("Starting Bal: ", initialBal/1e18);
        console.log("Final Bal: ", finalBal/1e18);
        assertEq(initialBal, finalBal+creditAmount);
    }

    function testUserCanNotPlayAgainImmediately() public getCredit {
        uint256 creditAmount = 500e18;

        vm.startPrank(user);
        uint256 requestId = machine.pullHandle(creditAmount);
        vm.expectRevert(SlotMachine.Machine__ProcessingPreviousPlay.selector);
        uint256 requestId2 = machine.pullHandle(creditAmount);
        vm.stopPrank();
    }






    modifier getCredit() {
        vm.prank(user);
        uint256 creditSize = machine.getCredit{value: weiAmount}();
        console.log("Received Credit: ", creditSize/1e18);
        _;
    }
}
