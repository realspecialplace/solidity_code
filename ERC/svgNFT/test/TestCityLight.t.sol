// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Test, console } from "forge-std/Test.sol";
import { DeployCityLight } from "../script/DeployCityLight.s.sol";
import { CityLight } from "../src/CityLight.sol";

contract TestCityLight is Test {
    CityLight cityLight;
    DeployCityLight deployer;

    address public user = makeAddr("user");

    function setUp() external {
        deployer = new DeployCityLight();
        cityLight = deployer.run();
    
        vm.deal(user, 5e18);
    }

    function testMint() public {
        vm.prank(user);
        cityLight.mint();

        string memory tokenUri = cityLight.tokenURI(1);
        console.log("token uri: ", tokenUri);
    }
}