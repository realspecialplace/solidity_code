// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Script } from "../lib/forge-std/src/Script.sol";
import {MockV3Aggregator} from "./MockV3Aggregator.s.sol";

contract HelperConfig is Script {
    error HelperConfig__NotImplementedChain(uint256 chainId);

    struct NetworkConfig {
        address aggregator;
    }

    uint8 constant DECIMALS = 8;
    int256 constant INITIAL_PRICE = 2000e8;

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 31337) {
            activeNetworkConfig = getAnvilNetworkConfig();
        } else if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaNetworkConfig();
        } else {
            revert HelperConfig__NotImplementedChain(block.chainid);
        }
    }

    function getSepoliaNetworkConfig() public returns (NetworkConfig memory) {
        return NetworkConfig({
            aggregator: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
    }

    function getAnvilNetworkConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.aggregator != address(0)) {
            return activeNetworkConfig;
        }
        MockV3Aggregator priceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        return NetworkConfig({
            aggregator: address(priceFeed)
        });
    }
}