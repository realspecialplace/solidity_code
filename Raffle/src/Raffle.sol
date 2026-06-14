// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Raffle is VRFConsumerBaseV2Plus {
    // == ERRORS == //
    error Raffle__UpkeepNeededisFalse();

    // == SYNTACTIC SUGER == //

    // == CUSTOME TYPES == //
    enum STATE {
        OPEN,
        CALCULATING
    }

    // == STATE VARIABLES == //
    uint16 public constant REQUEST_CONFIRMATIONS = 3;
    uint32 public constant NUM_WORDS = 1;

    bytes32 public immutable i_KEY_HASH;
    uint256 public immutable i_SUB_ID;
    uint32 public immutable i_CALL_BACK_GAS_LIMIT;
    uint256 public sLastTimeStamp;
    uint256 public immutable i_INTERVAL = 20;
    STATE public sState = STATE.OPEN;
    address payable[] public sPlayers;
    address payable public currentWinner;

    // == EVENTS == //

    // == MODIFIERS == //

    // == SPECIAL FUNCTIONS == //
    constructor(address _vrfcoordinator)VRFConsumerBaseV2Plus(_vrfcoordinator) {
        sLastTimeStamp = block.timestamp;
    }

    // == PUBLIC/EXTERNAL FUNCTIONS == //
    function checkUpkeep(bytes memory /**data */) public view returns (bool) {
        uint256 currentTime = block.timestamp;
        bool upkeepNeeded = false;
        // check truthy
        bool status = sState == STATE.OPEN;
        bool requiredNoOfAddress = sPlayers.length >= 5;
        bool timeUp = currentTime >= (sLastTimeStamp + i_INTERVAL);
        if (status && requiredNoOfAddress && timeUp) {
            upkeepNeeded = true;
        }
        return upkeepNeeded;
    }

    function performUpkeep(bytes memory /**data */) public {
        if (!checkUpkeep("")) {
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
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        
    }
}