// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {CreateSubscription} from "./Interactions.s.sol";
import {AddFundsToSubscription} from "./Interactions.s.sol";
import {AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    Raffle private raffle;

    function run() public returns (Raffle) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.Config memory config = helperConfig.getActiveConfig();
        uint256 participationAmount = config.participationAmount;
        uint256 duration = config.duration;
        address coordinatorAddress = config.coordinatorAddress;
        bytes32 gazMaxHash = config.gazMaxHash;
        uint64 subscriptionId = config.subscriptionId;
        uint32 callbackGasLimit = config.callbackGasLimit;
        address linkTokenAddress = config.linkTokenAddress;

        // Create a subscription if it doesn't exist
        if (subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(
                coordinatorAddress
            );
            AddFundsToSubscription addFundsToSubscription = new AddFundsToSubscription();
            addFundsToSubscription.addFundsToSubscription(
                coordinatorAddress,
                subscriptionId,
                linkTokenAddress
            );
        }

        raffle = new Raffle(
            participationAmount,
            duration,
            coordinatorAddress,
            gazMaxHash,
            subscriptionId,
            callbackGasLimit
        );

        // after the raffle is created, we need to add it as the consumer
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.run(raffle);

        return raffle;
    }
}
