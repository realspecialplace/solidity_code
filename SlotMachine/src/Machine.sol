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
    error Machine__AmountIsGreaterThanCreditBal(uint256 creditAmount);
    error Machine__UserIsNotAdmin(address user);
    error Machine__RangeCanNotBeBelowTen(uint256 newRange);
    error Machine__ProcessingPreviousPlay();
    error Machine_TotalFreeSpinIsBelowThree(uint256 newTotal);

    // == SYNTACTIC SUGER == //
    using MachineLibrary for uint256;

    // == CUSTOME TYPES == //
    enum State {
        PLAY,
        BUSY
    }

    // == STATE VARIABLES == //
    uint256 private constant TOTAL_STOPS = 72;
    uint256 private constant TOTAL_PRICES = 8;
    uint256 public constant MIN_DEPOSIT = 15e18; // 15 dollars(value in stable) using 18 decimals
    uint256 public constant CREDIT_PER_DOLLAR = 100; // 1 credit per cent
    uint256 public constant MIN_CREDIT_TO_PLAY = 500e18; // 500($5) credits since credits use 18 decimals
    uint32 public constant NUM_WORDS = 4;
    uint16 public constant CONFIRMATIONS = 3;
    uint256 public constant FREE_SPIN_LUCKY_NUMBER = 7;
    uint256 public sFreeSpinNumberRange = 10;
    uint256 private sTotalFreeSpins = 5;
    address payable[] public sAllPlayers;

    address private immutable i_vrfCoordinator;
    address public immutable i_priceFeed;
    address public immutable i_admin;
    bytes32 public immutable i_keyHash;
    uint256 private immutable i_subId;
    uint32 public immutable i_callbackGasLimit;

    mapping(uint256 stop => string price) public sStopToPrice;
    mapping(address user => uint256 credits) public sUserToCreditBal; // credits has 18 decimals
    mapping(uint256 requestId => address user) private sRequestIdToUser;
    mapping(address player => string[] price) private sPlayerToPrice;
    mapping(address player => uint256 nOfFreeSpins) public sPlayerToFreeSpin;
    mapping(address player => State state) public sPlayerToState;
    mapping(address player => uint256 lastCreditPlayedWith) public sPlayerToLastPlayed;

    // == EVENTS == //
    event MoreCreditAdded(uint256 indexed credits);
    event RequestIdGenerated(uint256 indexed requestId);
    event RetrievedPricesSuccessfully(uint256 indexed requestId, string[] indexed price);
    event FreeSpinObtained(address indexed player);

    // == MODIFIERS == //
    modifier onlyValidStops(uint256 index) {
        if (index > TOTAL_STOPS || index == 0) revert Machine__NotValidStop(index);
        _;
    }

    modifier onlyValidUsers(address user) {
        if (sUserToCreditBal[user] == 0) revert Machine__NotValidUser(user);
        _;
    }

    modifier onlyAdmin {
        if (msg.sender != i_admin) revert Machine__UserIsNotAdmin(msg.sender);
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
    function changeFreeSpinRange(uint256 newRange) public onlyAdmin {
        if (newRange < 10) revert Machine__RangeCanNotBeBelowTen(newRange);
        sFreeSpinNumberRange = newRange;
    }
    function changeTotalFreeSpins(uint256 newTotal) public onlyAdmin {
        if (newTotal < 3) revert Machine_TotalFreeSpinIsBelowThree(newTotal);
        sTotalFreeSpins = newTotal;
    }

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

    /**
    * @dev This function checks if user is eligible for freeSpin
    * @notice eligible users are given a free spin worth min credit value
     */
    function freePlay() external returns (uint256 requestId) {

    }
    

    function pullHandle(uint256 creditAmount) external onlyValidUsers(msg.sender) returns (uint256 requestId) {
        if (creditAmount < MIN_CREDIT_TO_PLAY) revert Machine__BelowMinCreditToPlay(creditAmount);
        if (creditAmount > sUserToCreditBal[msg.sender]) revert Machine__AmountIsGreaterThanCreditBal(creditAmount);

        // check if user is done with last round and can play again
        if (sPlayerToState[msg.sender] == State.BUSY) revert Machine__ProcessingPreviousPlay();

        // implement a code that fetches 4 random numbers
        VRFV2PlusClient.RandomWordsRequest memory randomNumbersRequest = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subId,
            requestConfirmations: CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        });
        // pass random number request struct config to oracle
        requestId = s_vrfCoordinator.requestRandomWords(randomNumbersRequest);
        sRequestIdToUser[requestId] = msg.sender;
        // add player to players
        sAllPlayers.push(payable(msg.sender));
        // store used credit
        sPlayerToLastPlayed[msg.sender] = creditAmount;
        // update total credits
        sUserToCreditBal[msg.sender] -= creditAmount;
        // change state to busy
        sPlayerToState[msg.sender] = State.BUSY;

        // emit requestId
        emit RequestIdGenerated(requestId);
    }

    // == INTERNAL/PRIVATE FUNCTIONS == //
    /**
    * @param randomWords While the first 3 numbers are used to get random prices,
    * the 4th random number determines if user will win free spin
     */
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        address player = sRequestIdToUser[requestId];
        uint256 totalPrice = 0;

        string[] memory prices = new string[](3);
        // use modulus to reduce the random numbers to a random value that does fits into the total stop value
        for (uint256 i=0; i < randomWords.length; i++) {
            if (i == 3) {
                uint256 spinFree = randomWords[i] % sFreeSpinNumberRange;
                if (spinFree == FREE_SPIN_LUCKY_NUMBER) {
                    // 5 total free spins at once
                    if (sPlayerToFreeSpin[msg.sender] == sTotalFreeSpins) break;

                    sPlayerToFreeSpin[msg.sender] += 1;
                    emit FreeSpinObtained(msg.sender);
                }
                break;
            }
            uint256 randomNumber = randomWords[i] % TOTAL_STOPS;
            string memory price = sStopToPrice[randomNumber];
            prices[i] = price;
        }
        // payout math after getting prices
        bytes32 firstPrice = keccak256(abi.encodePacked(prices[0]));
        bytes32 secondPrice = keccak256(abi.encodePacked(prices[1]));
        bytes32 thirdPrice = keccak256(abi.encodePacked(prices[2]));
        
        // handle logic for all matching pairs
        if (firstPrice == secondPrice && secondPrice == thirdPrice) {
                if (firstPrice == keccak256(abi.encodePacked("One Bar"))) {
                    totalPrice = sPlayerToLastPlayed[player] * 10;
                } else if (firstPrice == keccak256(abi.encodePacked("Two Bar"))) {
                    totalPrice = sPlayerToLastPlayed[player] * 20;
                } else if (firstPrice == keccak256(abi.encodePacked("Three Bar"))) {
                    totalPrice = sPlayerToLastPlayed[player] * 40;
                } else if (firstPrice == keccak256(abi.encodePacked("Double Diamond"))) {
                    totalPrice = sPlayerToLastPlayed[player] * 900;
                } else if (firstPrice == keccak256(abi.encodePacked("Cherry"))) {
                    totalPrice = sPlayerToLastPlayed[player]/2;
                }
        }
        // handle semi matchng pairs
        else if (firstPrice == secondPrice || secondPrice == thirdPrice || firstPrice == thirdPrice) {
                if (firstPrice == keccak256(abi.encodePacked("One Bar")) || thirdPrice == keccak256(abi.encodePacked("One Bar"))) {
                    totalPrice = sPlayerToLastPlayed[player]/2;
                } else if (firstPrice == keccak256(abi.encodePacked("Two Bar")) || thirdPrice == keccak256(abi.encodePacked("Two Bar"))) {
                    totalPrice = sPlayerToLastPlayed[player];
                } else if (firstPrice == keccak256(abi.encodePacked("Three Bar")) || thirdPrice == keccak256(abi.encodePacked("Three Bar"))) {
                   totalPrice = sPlayerToLastPlayed[player] * 3; 
                } else if (firstPrice == keccak256(abi.encodePacked("Double Diamond")) || thirdPrice == keccak256(abi.encodePacked("Double Diamond"))) {
                    totalPrice = sPlayerToLastPlayed[player] * 10;
                }
            }

        // update credit bal
        sUserToCreditBal[player] += totalPrice; // totalPrice is 0 if no conditions above meet
        
        // change state
        sPlayerToState[player] = State.PLAY;

        // add random price to declared map
        sPlayerToPrice[player] = prices;
        // emit event
        emit RetrievedPricesSuccessfully(requestId, sPlayerToPrice[player]);
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

    function getSubscriptionId() public view onlyAdmin returns (uint256) {
        return i_subId;
    }
}
