// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";

contract HelperConfig is Script {
    // == ERRORS == //
    error HelperConfig__NotImplementedChain(uint256 currentChain);

    // == CUSTOME TYPES == //
    struct NetworkConfig {
        address vrfCoordinator;
        address priceFeed;
        bytes32 keyHash;
        uint256 subId;
        uint32 callbackGasLimit;
    }

    // == STATE VARIABLES == //
    uint256 public ANVIL_CHAIN = 31337;
    uint256 public SEPOLIA_CHAIN = 11155111;
    uint8 public constant PRICE_DECIMAL = 8;
    int256 public constant MOCK_ETH_PRICE = 2000e8;

    mapping(uint256 chainId => NetworkConfig configs) public sNetworkConfigs;
    NetworkConfig public localNetworkConfig;

    // == SPECIAL FUNCTIONS == //
    constructor() {
        sNetworkConfigs[SEPOLIA_CHAIN] = getSepoliaConfig();
    }

    // == PUBLIC/EXTERNAL FUNCTIONS == //
    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subId: 2407566812293562361472652167316053808373346291930590006132696649086509256753,
            callbackGasLimit: 50000
        });
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }
        // deploy mock aggregatorV3Interface
        vm.startBroadcast();
        MockV3Aggregator _priceFeed = new MockV3Aggregator(PRICE_DECIMAL, MOCK_ETH_PRICE);
        vm.stopBroadcast();
        //console.log("Mock PriceFeed CA: ", address(_priceFeed));

        return NetworkConfig({
            vrfCoordinator: address(uint160(200)),
            priceFeed: address(_priceFeed),
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subId: 0,
            callbackGasLimit: 50000
        });
    }

    // getters
    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (chainId == ANVIL_CHAIN) {
            return getAnvilConfig();
        }
        if (sNetworkConfigs[chainId].vrfCoordinator == address(0)) {
            revert HelperConfig__NotImplementedChain(block.chainid);
        } else {
            return sNetworkConfigs[chainId];
        }
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }
}
