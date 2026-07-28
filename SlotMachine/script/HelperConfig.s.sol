// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Script } from "forge-std/Script.sol";

contract HelperConfig is Script {
    // == ERRORS == //
    error HelperConfig__NotImplementedChain(uint256 currentChain);

    // == CUSTOME TYPES == //
    struct NetworkConfig {
        address vrfCoordinator;
    }

    // == STATE VARIABLES == //
    uint256 public ANVIL_CHAIN = 31337;
    uint256 public SEPOLIA_CHAIN = 11155111;
    mapping(uint256 chainId => NetworkConfig configs) public sNetworkConfigs;
    NetworkConfig public networkConfig;

    // == SPECIAL FUNCTIONS == //
    constructor() {
       sNetworkConfigs[SEPOLIA_CHAIN] = getSepoliaConfig();
    }

    // == PUBLIC/EXTERNAL FUNCTIONS == //
    function getSepoliaConfig() public returns(NetworkConfig memory) {
        return networkConfig = NetworkConfig({
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B
        });
    }

    function getAnvilConfig() public view returns(NetworkConfig memory) {
        if (networkConfig.vrfCoordinator != address(0)) {
            return networkConfig;
        }
        return NetworkConfig({
            vrfCoordinator: address(uint160(200))
        });
    }

    // getters
    function getConfigByChainId(uint256 chainId) public view returns (NetworkConfig memory) {
        if (chainId == ANVIL_CHAIN) {
            return getAnvilConfig();
        } 
        if (sNetworkConfigs[chainId].vrfCoordinator == address(0)) {
            revert HelperConfig__NotImplementedChain(block.chainid);
        }
        else {
            return sNetworkConfigs[chainId];
        }
    }

    function getConfig() public view returns(NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }
}