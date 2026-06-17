// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Raffle is VRFConsumerBaseV2Plus {
    // == ERRORS == //
    error Raffle__UpkeepNeededisFalse();
    error Raffle__FailedToRewardWinner();
    error Raffle__NoRegisteredPlayers();
    error Raffle__AmountMustBeAboveZero();
    error Raffle__NotEnoughToJoin();

    // == SYNTACTIC SUGER == //

    // == CUSTOME TYPES == //
    enum STATE {
        OPEN,
        CALCULATING
    }

    // == STATE VARIABLES == //
    uint16 public constant REQUEST_CONFIRMATIONS = 3;
    uint32 public constant NUM_WORDS = 1;
    uint256 public constant MIN_AMNT = 0.1 ether;

    bytes32 public immutable i_KEY_HASH;
    uint256 public immutable i_SUB_ID;
    uint32 public immutable i_CALL_BACK_GAS_LIMIT; // conventionally 50,000 gas
    uint256 public immutable i_INTERVAL;

    STATE public sState = STATE.OPEN;
    address payable[] public sPlayers;
    address payable public sCurrentWinner;
    uint256 public sLastTimeStamp;

    // == EVENTS == //
    event RewardsSentToWinner(address indexed winnerAddy);

    // == MODIFIERS == //
    modifier checkAmount {
        if (msg.value == 0) {
            revert Raffle__AmountMustBeAboveZero();
        }
        _;
    }

    // == SPECIAL FUNCTIONS == //
    constructor(address _vrfcoordinator, uint256 _interval)VRFConsumerBaseV2Plus(_vrfcoordinator) {
        sLastTimeStamp = block.timestamp;
        i_INTERVAL = _interval;
    }

    fallback() external {
        enterRaffle();
    }

    receive() external payable {
        enterRaffle();
    }

    // == PUBLIC/EXTERNAL FUNCTIONS == //
    function enterRaffle() public payable checkAmount returns (string memory) {
        if (msg.value < MIN_AMNT) {
            revert Raffle__NotEnoughToJoin();
        }
        sPlayers.push(payable(msg.sender));
        return "Raffle joined successfully";
    }

    function checkUpkeep(bytes memory /**data */) public view returns (bool, bool, bool, bool) {
        uint256 currentTime = block.timestamp;
        bool upkeepNeeded = false;
        // check truthy
        bool status = sState == STATE.OPEN;
        bool requiredNoOfAddress = sPlayers.length >= 5;
        bool timeUp = currentTime >= (sLastTimeStamp + i_INTERVAL);
        if (status && requiredNoOfAddress && timeUp) {
            upkeepNeeded = true;
        }
        return (upkeepNeeded, status, requiredNoOfAddress, timeUp);
    }

    function performUpkeep(bytes memory /**data */) public {
        (bool upkeepNeeded,,,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNeededisFalse();
        }
        sState = STATE.CALCULATING;
        // setup the randomWordsRequest struct
        VRFV2PlusClient.RandomWordsRequest memory randomWordsRequest = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_KEY_HASH,
            subId: i_SUB_ID,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_CALL_BACK_GAS_LIMIT,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        });
        // request random words
        s_vrfCoordinator.requestRandomWords(randomWordsRequest);
    }

    function fulfillRandomWords(uint256 /*requestId*/, uint256[] calldata randomWords) internal override {
        if (sPlayers.length == 0) revert Raffle__NoRegisteredPlayers();
        
        uint256 winnerIndex = randomWords[0] % sPlayers.length;
        sCurrentWinner = sPlayers[winnerIndex];
        // change contract state
        sPlayers = new address payable[](0);
        sLastTimeStamp = block.timestamp;
        sState = STATE.OPEN;

        // send tokens to winner
        (bool success,) = sCurrentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__FailedToRewardWinner();
        }
        emit RewardsSentToWinner(sCurrentWinner);
    }

    // GETTERS
    function getTotalPlayersInRaffle() public view returns (uint256) {
        return sPlayers.length;
    }
}