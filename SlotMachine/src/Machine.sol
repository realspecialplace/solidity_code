// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { VRFConsumerBaseV2 } from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol"; // contract
import { VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol"; // library
import { MachineLibrary } from "./MachineLibrary.sol";

/**
* @author 0xgrindpa
* @title A 72 stop virtual reel strips slot machine contract
 */
contract SlotMachine is VRFConsumerBaseV2 {
    // == ERRORS == //
    error Machine__NotValidStop(uint256 index);
    error Machine__BelowMinDeposit(uint256 usdValue);

    // == SYNTACTIC SUGER == //
    using MachineLibrary for uint256;

    // == CUSTOME TYPES == //

    // == STATE VARIABLES == //
    uint256 public constant TOTAL_STOPS = 72;
    uint256 public constant TOTAL_PRICES = 8;
    uint256 public constant MIN_DEPOSIT = 15e18; // 15 dollars(value in stable) using 18 decimals
    address public immutable i_priceFeed;
    address public immutable i_admin;
    mapping(uint256 stop => string price) public sStopToPrice;
    mapping(address user => uint256 credits) public userToCreditBal; 

    // == EVENTS == //

    // == MODIFIERS == //
    modifier onlyValidStops(uint256 index) {
        if (index > TOTAL_STOPS || index == 0) revert Machine__NotValidStop(index);
        _;
    }

    // == SPECIAL FUNCTIONS == //
    constructor(address _vrfCoordinator, address _priceFeed) VRFConsumerBaseV2(_vrfCoordinator) {
        // assign contract admin
        i_admin = msg.sender;
        // assign pricefeed data
        i_priceFeed = _priceFeed;
        // configure price for each reel stop
        for (uint256 i=1; i<=TOTAL_STOPS; i++) {
            if (i <= 3) {
                sStopToPrice[i] = "empty";
            } else if (i == 4) {
                sStopToPrice[i] = "7";
            } else if (i >= 5 && i <= 9) {
                sStopToPrice[i] = "empty";
            } else if (i >= 10 && i <= 12) {
                sStopToPrice[i] = "One Bar";
            } else if (i >= 13 && i <= 19) {
                sStopToPrice[i] = "empty";
            } else if (i >= 20 && i <= 21) {
                sStopToPrice[i] = "Cherry";
            } else if (i >= 22 && i <= 26) {
                sStopToPrice[i] = "empty";
            } else if (i == 27) {
                sStopToPrice[i] = "Double Diamond";
            } else if (i >= 28 && i <= 32) {
                sStopToPrice[i] = "empty";
            } else if (i >= 33 && i <= 35) {
                sStopToPrice[i] = "One Bar";
            } else if (i >= 36 && i <= 39) {
                sStopToPrice[i] = "empty";
            } else if (i == 40) {
                sStopToPrice[i] = "Three Bar";
            } else if (i >= 41 && i <= 42) {
                sStopToPrice[i] = "empty";
            } else if (i == 43) {
                sStopToPrice[i] = "7";
            } else if (i >= 44 && i <= 51) {
                sStopToPrice[i] = "empty";
            } else if (i >= 52 && i <= 54) {
                sStopToPrice[i] = "One Bar";
            } else if (i >= 55 && i <= 59) {
                sStopToPrice[i] = "empty";
            } else if (i == 60) {
                sStopToPrice[i] = "Double Diamond";
            } else if (i >= 61 && i <= 65) {
                sStopToPrice[i] = "empty";
            } else if (i >= 66 && i <= 67) {
                sStopToPrice[i] = "Two Bar";
            } else if (i >= 68 && i <= 70) {
                sStopToPrice[i] = "empty";
            } else if (i >= 71 && i <= 72) {
                sStopToPrice[i] = "One Bar";
            }
        }
    }

    // == PUBLIC/EXTERNAL FUNCTIONS == //
    function getCredit() public payable returns (uint256){
        uint256 usdValue = uint256(msg.value).convertDepositToUsd(i_priceFeed);
        if (usdValue < MIN_DEPOSIT) revert Machine__BelowMinDeposit(usdValue/1e18);

        return usdValue;
    }

    function fulfillRandomWords(uint256 /* requestId */, uint256[] memory randomWords) internal override {

    }

    // == INTERNAL/PRIVATE FUNCTIONS == //

    // == GETTER FUNCTIONS == //
    function getPricePerStop(uint256 index) public view onlyValidStops(index) returns(string memory price) {
        price = sStopToPrice[index];
    }

    function getUsdPrice() public view returns (uint256 usdPrice) {
        usdPrice = MachineLibrary.getUsdPrice(i_priceFeed);
    }
}