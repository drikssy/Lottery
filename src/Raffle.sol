// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Pragma statements
// Import statements
// Events
// Errors
// Interfaces
// Libraries
// Contracts

/* Imports */
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/* Errors */
error Raffle__NotRightETHAmount();
error Raffle__NotOpen();
error Raffle__TransferETHToWinnerFailed();
error Raffle__HasNoPlayers();

contract Raffle is VRFConsumerBaseV2 {
    // Type declarations
    // State variables
    // Events
    // Errors
    // Modifiers
    // Functions

    /* Type declarations */
    enum RaffleState {
        Open,
        Closed
    }

    /* State variables */
    address private immutable i_manager;
    address[] private s_players;
    uint256 private immutable i_duration;
    uint256 private immutable i_participationAmount;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUMBER_OF_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    uint256 private s_startingTime;
    RaffleState private s_state;
    address private immutable i_coordinator;
    bytes32 private immutable i_gazMaxHash;
    uint64 private immutable i_subscriptionId;

    /* events */
    event Participated(address indexed player);

    constructor(
        uint256 participationAmount,
        uint256 duration,
        address coordinatorAddress,
        bytes32 gazMaxHash,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(coordinatorAddress) {
        i_manager = msg.sender;
        i_participationAmount = participationAmount;
        i_duration = duration;
        s_startingTime = block.timestamp;
        s_state = RaffleState.Open;
        i_coordinator = coordinatorAddress;
        i_gazMaxHash = gazMaxHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    function participate() public payable {
        if (msg.value != i_participationAmount)
            revert Raffle__NotRightETHAmount();
        if (s_state != RaffleState.Open) revert Raffle__NotOpen();
        s_players.push(msg.sender);
        emit Participated(msg.sender);
    }

    function requestRandomWords() external {
        if (block.timestamp - s_startingTime < i_duration)
            revert Raffle__NotOpen();
        if (s_players.length == 0) revert Raffle__NotOpen();
        if (s_state != RaffleState.Open) revert Raffle__HasNoPlayers();
        s_state = RaffleState.Closed;
        // Will revert if subscription is not set and funded.
        VRFCoordinatorV2Interface(i_coordinator).requestRandomWords(
            i_gazMaxHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUMBER_OF_WORDS
        );
    }

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory _randomWords
    ) internal override {
        // here we receive the random number from the chainlink node

        s_state = RaffleState.Open;
        s_players = new address[](0);
        address winner = s_players[_randomWords[0] % s_players.length];

        (bool success, ) = payable(winner).call{value: address(this).balance}(
            ""
        );
        if (!success) revert Raffle__TransferETHToWinnerFailed();
    }

    /* gettters */

    function getCoordinator() public view returns (address) {
        return i_coordinator;
    }

    function getSubscriptionId() public view returns (uint64) {
        return i_subscriptionId;
    }
}
