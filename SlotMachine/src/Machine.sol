// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol"; // contract
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol"; // library
import {MachineLibrary} from "./MachineLibrary.sol";

/**
 * @author 0xgrindpa
 * @title A 72 stop virtual reels strip slot machine contract
 */
contract SlotMachine is VRFConsumerBaseV2Plus {
    // == ERRORS == //
    error Machine__NotValidStop(uint256 index);
    error Machine__BelowMinDeposit(uint256 usdValue);
    error Machine__NotValidUser(address user);
    error Machine__BelowMinCreditToPlay(uint256 creditAmount);

    // == SYNTACTIC SUGER == //
    using MachineLibrary for uint256;

    // == CUSTOME TYPES == //

    // == STATE VARIABLES == //
    uint256 private constant TOTAL_STOPS = 72;
    uint256 private constant TOTAL_PRICES = 8;
    uint256 public constant MIN_DEPOSIT = 15e18; // 15 dollars(value in stable) using 18 decimals
    uint256 public constant CREDIT_PER_DOLLAR = 100; // 1 credit per cent
    uint256 public constant MIN_CREDIT_TO_PLAY = 10e18; // 10 credits since credits use 18 decimals
    uint32 public constant NUM_WORDS = 3;
    uint16 public constant CONFIRMATIONS = 3;

    address private immutable i_vrfCoordinator;
    address public immutable i_priceFeed;
    address public immutable i_admin;
    bytes32 public immutable i_keyHash;
    uint256 public immutable i_subId;
    uint32 public immutable i_callbackGasLimit;

    mapping(uint256 stop => string price) public sStopToPrice;
    mapping(address user => uint256 credits) public sUserToCreditBal; // credits has 18 decimals
    mapping(uint256 requestId => address user) private sRequestIdToUser;
    mapping(address player => string[] price) private sPlayerToPrice;

    // == EVENTS == //
    event MoreCreditAdded(uint256 indexed credits);

    // == MODIFIERS == //
    modifier onlyValidStops(uint256 index) {
        if (index > TOTAL_STOPS || index == 0) revert Machine__NotValidStop(index);
        _;
    }

    modifier onlyValidUsers(address user) {
        if (sUserToCreditBal[user] == 0) revert Machine__NotValidUser(user);
        _;
    }

    // == SPECIAL FUNCTIONS == //
    constructor(address _vrfCoordinator, address _priceFeed, bytes32 keyHash, uint256 subId, uint32 gasLimit)
        VRFConsumerBaseV2Plus(_vrfCoordinator)
    {
        // assign contract admin
        i_admin = msg.sender;
        // assign other immutable variables
        i_vrfCoordinator = _vrfCoordinator;
        i_priceFeed = _priceFeed;
        i_keyHash = keyHash;
        i_subId = subId;
        i_callbackGasLimit = gasLimit;
        // configure price for each reel stop
        for (uint256 i = 1; i <= TOTAL_STOPS; i++) {
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
    function getCredit() external payable returns (uint256) {
        uint256 usdValue = uint256(msg.value).convertDepositToUsd(i_priceFeed);
        // revert attempt if deposit is less than $15 in value
        if (usdValue < MIN_DEPOSIT) revert Machine__BelowMinDeposit(usdValue / 1e18);
        // convert deposit to credits (1 credit per cent)
        uint256 credits = CREDIT_PER_DOLLAR.convertDepositToCredit(usdValue);
        // update state
        sUserToCreditBal[msg.sender] += credits;
        // emit event
        emit MoreCreditAdded(credits);

        return credits;
    }

    function pullHandle(uint256 creditAmount) external onlyValidUsers(msg.sender) returns (bool) {
        if (creditAmount < MIN_CREDIT_TO_PLAY) revert Machine__BelowMinCreditToPlay(creditAmount);

        // implement a code that fetches 3 random numbers
        VRFV2PlusClient.RandomWordsRequest memory randomNumbersRequest = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subId,
            requestConfirmations: CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        });
        // pass random number request config to oracle
        uint256 requestId = s_vrfCoordinator.requestRandomWords(randomNumbersRequest);
        sRequestIdToUser[requestId] = msg.sender;

        return true;
    }

    // == INTERNAL/PRIVATE FUNCTIONS == //
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    )
        internal
        override
    {
        address player = sRequestIdToUser[requestId];

        string[] memory prices = new string[](3);
        // use modulus to reduce the random numbers to a random value that does not fit into the total stop value
        for (uint256 i=0; i < randomWords.length; i++) {
            uint256 randomNumber = randomWords[i] % TOTAL_STOPS;
            string memory price = sStopToPrice[randomNumber];
            prices[i] = price;
        }
        // add random price to declared map
        sPlayerToPrice[player] = prices;
    }

    // == GETTER FUNCTIONS == //
    function getPricePerStop(uint256 index) public view onlyValidStops(index) returns (string memory price) {
        price = sStopToPrice[index];
    }

    function getUsdPrice() public view returns (uint256 usdPrice) {
        usdPrice = MachineLibrary.getUsdPrice(i_priceFeed);
    }

    function getCreditBalance(address user) public view onlyValidUsers(user) returns (uint256 credits) {
        credits = sUserToCreditBal[user];
    }
}
