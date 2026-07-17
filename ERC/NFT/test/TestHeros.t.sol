// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Test, console } from "forge-std/Test.sol";
import { Heros } from "../src/Heros.sol";
import { DeployHeros } from "../script/DeployHero.s.sol";

contract TestHeros is Test {
    Heros heros;
    DeployHeros deployer;
    address public user = makeAddr("user");

    function setUp() external {
        deployer = new DeployHeros();
        heros = deployer.run();
        vm.deal(user, 2e18);
    }

    function testMint() public {
        vm.startPrank(user);
        heros.mintHero();
        string memory metadata = heros.tokenURI(1);
        vm.stopPrank();

        console.log("token metadata cid: ", metadata);
    }

    function testMoreThanFiveMints() public {
        uint256 totalMints = 6;

        for (uint256 i=1; i < totalMints; i++) {
            hoax(address(uint160(i)), 2e18);
            if (i == 5) {
                vm.expectRevert();
            }
            heros.mintHero();
        }
    }

    function testGetTotalNFTs() public {
        uint256 totalMints = 5;

        for (uint256 i=1; i < totalMints; i++) {
            hoax(address(uint160(i)), 2e18);
            heros.mintHero();
        }

        uint256 totalMinted = heros.getTotalMinted();
        console.log("total minted: %s Heros", totalMinted);
    }
}