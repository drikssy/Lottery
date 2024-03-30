// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {LinkTokenMock} from "../src/mocks/LinkTokenMock.sol";
import {VRFCoordinatorV2Mock} from "chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract CreateSubscription is Script {
    function createSubscription(
        address coordinator
    ) public returns (uint64 subscriptionId) {
        vm.startBroadcast();
        subscriptionId = VRFCoordinatorV2Interface(coordinator)
            .createSubscription();
        vm.stopBroadcast();
    }

    function run() public returns (uint64) {
        HelperConfig hc = new HelperConfig();
        address coordinator = hc.getActiveConfig().coordinatorAddress;
        return createSubscription(coordinator);
    }
}

contract AddFundsToSubscription is Script {
    uint96 public constant ADD_FUND_AMOUNT = 5 ether; // 5 LINK

    function addFundsToSubscription(
        address coordinator,
        uint64 subscriptionId,
        address linkTokenAddress
    ) public {
        vm.startBroadcast();

        if (block.chainid == 31337) {
            VRFCoordinatorV2Mock(coordinator).fundSubscription(
                subscriptionId,
                ADD_FUND_AMOUNT
            );
        } else {
            LinkTokenMock(linkTokenAddress).transferAndCall(
                address(coordinator),
                ADD_FUND_AMOUNT,
                abi.encode(subscriptionId)
            );
        }
        vm.stopBroadcast();
    }

    function run() public {
        HelperConfig hc = new HelperConfig();
        address coordinator = hc.getActiveConfig().coordinatorAddress;
        uint64 subscriptionId = hc.getActiveConfig().subscriptionId;
        address linkTokenAddress = hc.getActiveConfig().linkTokenAddress;
        addFundsToSubscription(coordinator, subscriptionId, linkTokenAddress);
    }
}

contract AddConsumer is Script {
    function addConsumer(
        address raffleAddress,
        address coordinator,
        uint64 subscriptionId
    ) public {
        vm.startBroadcast();
        VRFCoordinatorV2Interface(coordinator).addConsumer(
            subscriptionId,
            raffleAddress
        );
        vm.stopBroadcast();
    }

    function run(Raffle raffle) public {
        address raffleAddress = address(raffle);
        address coordinator = raffle.getCoordinator();
        uint64 subscriptionId = raffle.getSubscriptionId();
        addConsumer(raffleAddress, coordinator, subscriptionId);
    }
}
