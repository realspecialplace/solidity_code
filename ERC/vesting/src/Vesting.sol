// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { AkaraToken } from "./Akara.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Vest is ReentrancyGuard {
    // == ERRORS == //
    error Vesting__NotSupportedToken(address tokenCA);
    error Vest__NotAnInvestor();
    error Vest__AmountGreaterThanWithdrawable();
    error Vest__ComeBackInAFewMinutes();
    error Vest__WithdrawalNotSuccessfull();
    error Vest__CanNotDepositCheckBalance();
    error Vest__IncreaseDepositAmount();

    // == SYNTACTIC SUGER == //
    using SafeERC20 for AkaraToken;

    // == CUSTOM TYPES == //
    // == STATE VARIABLES == //
    uint256 public immutable i_vestPeriod; // in sec
    uint256 public immutable i_nextWithdrawTime; // in sec
    uint256 public immutable i_amountPerSection;
    uint256 public immutable i_minimumAmount;

    mapping(address allowedCa => uint256 state) public allowedTokenCAs;
    mapping(address investor => uint256 amountInvested) private investorInfo;
    mapping(address investor => mapping(uint256 withdrawableAmount => uint256 timeTillNextWithdraw)) private withdrawalTime;

    // == EVENTS == //
    event WithdrawalCompleted();

    // == SPECIAL FUNCTIONS == //
    constructor(uint256 _minAmount, uint256 vestPeriod, uint256 _nextWithdrawTime, uint256 _amountPerSection, address[] memory _allowedTokenCAs) {
        i_vestPeriod = vestPeriod;
        i_nextWithdrawTime = _nextWithdrawTime;
        i_amountPerSection = _amountPerSection;
        i_minimumAmount = _minAmount;

        for (uint256 i=0; i < _allowedTokenCAs.length; i++) {
            allowedTokenCAs[_allowedTokenCAs[i]] = 1;
        }
    }

    // == MODIFIERS == //
    modifier notAllowedToken(address tokenCA) {
        if (allowedTokenCAs[tokenCA] != 1) {
            revert Vesting__NotSupportedToken(tokenCA);
        }
        _;
    }
    modifier checkIfIsInvestor(address user) {
        if (investorInfo[user] == 0) revert Vest__NotAnInvestor();
        _;
    }

    // == PUBLIC/EXTERNAL FUNCTIONS == //
    function vestToken(uint256 akaraAmount, address tokenCA) external notAllowedToken(tokenCA) {
        if (akaraAmount < i_minimumAmount) revert Vest__IncreaseDepositAmount();
        bool success = AkaraToken(tokenCA).transferFrom(msg.sender, address(this), akaraAmount);
        if (!success) revert Vest__CanNotDepositCheckBalance();
        investorInfo[msg.sender] = akaraAmount;

        withdrawalTime[msg.sender][i_amountPerSection] = block.timestamp;
    }

    function withdraw(uint256 amount, address tokenCA) public notAllowedToken(tokenCA) checkIfIsInvestor(msg.sender) nonReentrant {
        if (amount > investorInfo[msg.sender] || amount > i_amountPerSection) revert Vest__AmountGreaterThanWithdrawable();
        bool dueTime = block.timestamp > (withdrawalTime[msg.sender][i_amountPerSection] + i_nextWithdrawTime);
        if (!dueTime) {
            revert Vest__ComeBackInAFewMinutes();
        }
        withdrawalTime[msg.sender][i_amountPerSection] = block.timestamp;
        investorInfo[msg.sender] -= amount;
        AkaraToken(tokenCA).safeTransfer(msg.sender, amount);
      
        emit WithdrawalCompleted();
    }

    // == GETTERS == //
    function getInvestorInfo(address investor) external view checkIfIsInvestor(investor) returns (uint256) {
        return investorInfo[investor];
    }
}