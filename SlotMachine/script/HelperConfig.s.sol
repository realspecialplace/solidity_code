// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {MockLinkToken} from "@chainlink/contracts/src/v0.8/mocks/MockLinkToken.sol";

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
        address linkToken;
        address sender;
    }

    // == STATE VARIABLES == //
    uint256 public ANVIL_CHAIN = 31337;
    uint256 public SEPOLIA_CHAIN = 11155111;
    uint8 public constant PRICE_DECIMAL = 8;
    int256 public constant MOCK_ETH_PRICE = 2000e8;
    uint96 public constant MOCK_BASE_FEE = 0.25e18;
    uint96 public constant MOCK_GAS_PRICE = 1e9;
    int256 public constant MOCK_WEI_PER_LINK = 4e15;

    mapping(uint256 chainId => NetworkConfig configs) public sNetworkConfigs;
    NetworkConfig public localNetworkConfig;

    // == SPECIAL FUNCTIONS == //
    constructor() {
        sNetworkConfigs[SEPOLIA_CHAIN] = getSepoliaConfig();
    }

    // == PUBLIC/EXTERNAL FUNCTIONS == //
    function getSepoliaConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subId: 2407566812293562361472652167316053808373346291930590006132696649086509256753,
            callbackGasLimit: 50000,
            linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            sender: vm.envAddress("SENDER")
        });
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }
        // deploy mock aggregatorV3Interface
        vm.startBroadcast();
        // instanciate mock vrfCoordinator
        MockV3Aggregator _priceFeed = new MockV3Aggregator(PRICE_DECIMAL, MOCK_ETH_PRICE);
        // instanciate vrfCoordinator mock
        VRFCoordinatorV2_5Mock vrfCoordinator = new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE, MOCK_WEI_PER_LINK);
        // instanciate link token mock
        MockLinkToken _linkToken = new MockLinkToken();
        vm.stopBroadcast();
        //console.log("Mock PriceFeed CA: ", address(_priceFeed));

        return NetworkConfig({
            vrfCoordinator: address(vrfCoordinator),
            priceFeed: address(_priceFeed),
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subId: 0,
            callbackGasLimit: 50000,
            linkToken: address(_linkToken),
            sender: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
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
