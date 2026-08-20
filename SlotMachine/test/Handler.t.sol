// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DeploySlotMachine} from "../script/DeploySlotMachine.s.sol";
import {SlotMachine} from "../src/Machine.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract Handler is Test {
    SlotMachine machine;
    HelperConfig helper;
    HelperConfig.NetworkConfig config;
    
    uint256 public constant MIN_CREDIT_TO_PLAY = 500e18;

    constructor(SlotMachine ca) {
        machine = ca;

        helper = new HelperConfig();
        config = helper.getConfig();
        // fund sender with eth
        vm.deal(config.sender, 200e18);
    }

    function getCreditToPlay(uint256 ethAmount) public {
        vm.startPrank(config.sender);
        // bound eth amount to 100 eth
        ethAmount = bound(ethAmount, 1e18, 50e18);
        // top eth
        vm.deal(config.sender, ethAmount);
        // make deposit and get credit
        machine.getCredit{value: ethAmount}();
        vm.stopPrank();
    }

    function pullMachineToPlay(uint256 creditAmount) public {
        // susequent calls of pullHandle() will keep reverting since State is now Busy after first call
        // hence
        if (machine.sPlayerToState(config.sender) == SlotMachine.State.BUSY) return;
        
        uint256 creditBal = machine.getCreditBalance(config.sender);
        if (creditBal < MIN_CREDIT_TO_PLAY) {
            getCreditToPlay(100e18);
            // update credit bal after getting credit
            creditBal = machine.getCreditBalance(config.sender);
        }
        // bound credit amount to user credit bal
        creditAmount = bound(creditAmount, MIN_CREDIT_TO_PLAY, creditBal);
        // play if conditions are met
        vm.prank(config.sender);
        machine.pullHandle(creditAmount);
    }
}