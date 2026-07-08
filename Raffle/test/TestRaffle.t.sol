// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../src/Raffle.sol";
import {DeployRaffle} from "../script/DeployRaffle.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {Vm} from "../lib/forge-std/src/Vm.sol";

contract TestRaffle is Test {
    Raffle raffle;
    DeployRaffle deployer;
    address public user;
    HelperConfig public helperConfig;
    uint256 public interval;
    address vrfCoordinator;

    function setUp() external {
        helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;

        deployer = new DeployRaffle();
        raffle = deployer.run();
        vm.deal(user, 5e18); // 5 ether
    }

    function testCheckUpkeep() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1); // mimicking real chain behaviour

        // create a loop that creates 5 addresses funding raffle with each of them
        uint160 addys = 5;
        for (uint160 i = 1; i <= addys; i++) {
            address addy = address(i);
            hoax(addy, 2 ether); //hoax == prank + deal
            raffle.enterRaffle{value: 1.1 ether}();
        }

        vm.startPrank(user);
        raffle.enterRaffle{value: 1 ether}();
        (bool upkeepNeeded, bool isOpen, bool moreThanZeroAddy, bool isTimeUp) = raffle.checkUpkeep("");
        uint256 nOfPlayers = raffle.getTotalPlayersInRaffle();
        vm.stopPrank();

        console.log(upkeepNeeded);
        console.log(isOpen);
        console.log(moreThanZeroAddy);
        console.log(isTimeUp);
        console.log("Total players: ", nOfPlayers);
        assertEq(upkeepNeeded, true);
    }

    function testEnterRaffleWhenInCalculatingState() public upkeepNeededIsTrue {
        vm.startPrank(user);
        raffle.performUpkeep("");
        vm.expectRevert(Raffle.Raffle__RaffleIsNotOpen.selector);
        raffle.enterRaffle{value: 1.1 ether}();
        vm.stopPrank();
    }

    /**
    * @notice this fuzz test tries to call fullfilRandomWords() function by passing an
    * invaid request id multiple times
     */
    function testCallWithoutValidRequestId(uint256 randomNumber) public upkeepNeededIsTrue {
        randomNumber = bound(randomNumber, 0, 500);

        vm.expectRevert();
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomNumber, address(raffle));
    }

    function testCallWithValidRequestId() public upkeepNeededIsTrue {
        //vm.startPrank(user);
        // get request id after calling perfomUpkeep()
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        // pass valid request id to fulfillRandomWords()
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));
        vm.prank(user);
        address lastWinner = raffle.getLastWinner();
        //vm.stopPrank();

        console.log("Request id: ", uint256(requestId));
        console.log("Last Winner", lastWinner);
    }

    modifier upkeepNeededIsTrue {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1); // mimicking real chain behaviour

        // create a loop that creates 5 addresses funding raffle with each of them
        uint160 addys = 5;
        for (uint160 i = 1; i <= addys; i++) {
            address addy = address(i);
            hoax(addy, 2 ether); //hoax == prank + deal
            raffle.enterRaffle{value: 1.1 ether}();
        }

        vm.startPrank(user);
        raffle.enterRaffle{value: 1 ether}();
        (bool upkeepNeeded, bool isOpen, bool moreThanZeroAddy, bool isTimeUp) = raffle.checkUpkeep("");
        uint256 nOfPlayers = raffle.getTotalPlayersInRaffle();
        vm.stopPrank();
        console.log(upkeepNeeded);
        _;
    }
}
