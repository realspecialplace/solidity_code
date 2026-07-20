// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Script } from "forge-std/Script.sol";
import { CityLight } from "../src/CityLight.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";

contract DeployCityLight is Script {
    CityLight cityLight;

    function run() external returns(CityLight) {
        string memory dayTimeImg = vm.readFile("./svgs/dayTime.svg");
        string memory nightTimeImg = vm.readFile("./svgs/nightTime.svg");
        
        string memory name = "City Light";
        string memory symbol = "CL";
        
        vm.startBroadcast();
        cityLight = new CityLight(name, symbol, getImgUri(dayTimeImg), getImgUri(nightTimeImg));
        vm.stopBroadcast();
        return cityLight;
    }

    /**
    * @dev This function converts a svg file to a image uri
     */
    function getImgUri(string memory svg) public pure returns(string memory) {
        string memory base64String = Base64.encode(abi.encodePacked(svg));

        // create the uri
        return string.concat(
            "data:image/svg+xml; base64,",base64String,""
        );
    }
}