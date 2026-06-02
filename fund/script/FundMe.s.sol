// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Script } from "../lib/forge-std/src/Script.sol";
import { FundMe } from "../src/Fund.sol";
import { HelperConfig } from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    FundMe public fundMe;
    HelperConfig config;

    function run() external returns(FundMe) {
        vm.startBroadcast();
        config = new HelperConfig();

        // activenetworkConfig is returned as a single address since the struct
        // returns just one data attribute
        fundMe = new FundMe(config.activeNetworkConfig());
        vm.stopBroadcast();
        return fundMe;
    }
}