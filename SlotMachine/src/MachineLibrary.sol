// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library MachineLibrary {
    function getUsdPrice(address priceFeed) public view returns (uint256) {
        (, int256 usdPrice,,,) = AggregatorV3Interface(priceFeed).latestRoundData();
        return uint256(usdPrice);
    }

    /**
     * @param value Eth value passed as wei preferrably msg.value
     * @param priceFeed price feed aggregator contract address
     */
    function convertDepositToUsd(uint256 value, address priceFeed) external view returns (uint256) {
        uint256 usdPrice = getUsdPrice(priceFeed) / 1e8;
        uint256 valueInUsd = value * usdPrice;
        return valueInUsd;
    }

    /**
    * @param usdValue incoming usd value has 8 decimals
    * @dev usd value from getUsdPrice() has 8 decimals
    * @notice the 8 decimals on both values will cancel out
     */
    function convertUsdToEth(uint256 usdValue, address priceFeed) external view returns (uint256 valueInWei) {
        uint256 usdPrice = getUsdPrice(priceFeed);
        // give wei value 18 decimals
        valueInWei = (usdValue * 1e18)/usdPrice;
    }

    function convertDepositToCredit(uint256 perDollar, uint256 depositAmount) external pure returns (uint256 credits) {
        credits = perDollar * depositAmount;
    }

    function convertCreditToUsd(uint256 perDollar, uint256 creditAmount) external pure returns (uint256 dollarValue) {
        dollarValue = creditAmount/perDollar;
    }
}
