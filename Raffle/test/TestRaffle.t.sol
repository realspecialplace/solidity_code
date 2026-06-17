// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../src/Raffle.sol";
import {DeployRaffle} from "../script/DeployRaffle.s.sol";

contract TestRaffle is Test {
    Raffle raffle;
    DeployRaffle deployer;
    address public user; 

    function setUp() external {
        deployer = new DeployRaffle();
        raffle = deployer.run();
        vm.deal(user, 5e18); // 5 ether
    }

    function testCheckUpkeep() public {
        vm.warp(block.timestamp + 22);
        vm.roll(block.number + 1); // mimicking real chain behaviour

        // create a loop that creates 5 addresses funding raffle with each of them
        uint160 addys = 5;
        for (uint160 i=1; i <= addys; i++) {
            address addy = address(i);
            hoax(addy, 2 ether);
            raffle.enterRaffle{value: 0.5 ether}();
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
    }
}