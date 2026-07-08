// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {LinkToken} from "./mocks/MockLinkToken.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract HelperConfig is Script {
    // errors
    error HelperConfig__NotImplementedChain(uint256 chain);

    // custom types
    struct NetworkConfig {
        uint256 entranceFee;
        address vrfCoordinator;
        uint256 interval;
        bytes32 keyHash;
        uint256 subId;
        uint32 callBackGasLimit;
        address linkToken;
        address account;
    }
    // state variables
    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint96 constant BASE_FEE = 0.25 ether;
    uint96 constant GAS_PRICE = 1e9;
    int256 constant WEI_PER_UNIT_LINK = 4e15;
    mapping(uint256 chainId => NetworkConfig config) public chainIdToConfigMap;

    NetworkConfig localConfig;

    constructor() {
        chainIdToConfigMap[SEPOLIA_CHAIN_ID] = getSepoliaNetworkConfig();
    }

    // config setters for implemented networks
    /**
     * @dev this function sets up config for sepolia chain
     */
    function getSepoliaNetworkConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 1 ether,
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B, // sepolia vrfCoordinator ca
            interval: 60, // 60 sec
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae, // 500 gwei
            subId: 2407566812293562361472652167316053808373346291930590006132696649086509256753,
            callBackGasLimit: 50000,
            linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account: 0xA1604a58dDB43831B77c2C82faBf6839153810a1
        });
    }

    /**
     * @dev this function sets up network config on anvil chain
     */
    function getAnvilConfig() public returns (NetworkConfig memory) {
        vm.startBroadcast();
        // deploy mock vrfcoordinator
        VRFCoordinatorV2_5Mock aVrfCoordinator = new VRFCoordinatorV2_5Mock(BASE_FEE, GAS_PRICE, WEI_PER_UNIT_LINK);
        // deploy mock link token
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();
        localConfig = NetworkConfig({
            entranceFee: 1 ether,
            vrfCoordinator: address(aVrfCoordinator),
            interval: 60, // 60 sec
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae, // 500 gwei
            subId: 0,
            callBackGasLimit: 50000,
            linkToken: address(linkToken),
            account: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
        });
        return localConfig;
    }

    function getConfigById(uint256 chainId) public returns (NetworkConfig memory) {
        if (chainId == SEPOLIA_CHAIN_ID) {
            return chainIdToConfigMap[SEPOLIA_CHAIN_ID];
        } else if (chainId == 31337) {
            return getAnvilConfig();
        } else {
            revert HelperConfig__NotImplementedChain(block.chainid);
        }
    }

    // auto pass chainid to get network config
    function getConfig() public returns (NetworkConfig memory) {
        return getConfigById(block.chainid);
    }
}
