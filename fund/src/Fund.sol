// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract FundMe {
    // error
    error FundMe__NotEnoughFund();

    // custom datatypes
    mapping(address funder => uint256 amount) public funder_data;

    // state variables
    uint256 constant private MIN_VALUE = 50e18; // $50
    address payable[] private sFunders;
    AggregatorV3Interface immutable i_priceFeed;

    constructor(address priceFeed) {
        i_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() payable external {
        bool state = false;
        uint256 arrayLength = sFunders.length;
        if (convertEthToUsd(msg.value) < MIN_VALUE) revert FundMe__NotEnoughFund();
        funder_data[msg.sender] = msg.value;
        for (uint256 i=0; i < arrayLength; i++) {
            if (sFunders[i] == msg.sender) {
                state = true;
            }
        }
        if (!state) {
            sFunders.push(payable(msg.sender));
        }
    }

    function getEthPrice() public view returns (uint256) {
        (, int256 usdPrice,,,) = i_priceFeed.latestRoundData();
        
        uint256 price = (uint256(usdPrice) * 1e10);
        return price;
    }

    function convertEthToUsd(uint256 ethAmountInWei) public view returns (uint256) {
        uint256 price = getEthPrice();
        // price is returned with extra 18 decimals i.e 2000e18 for instance
        return price * (ethAmountInWei)/1e18;
    }

    // getters
    function getFunders() public view returns (address payable[] memory) {
        return sFunders;
    }
}