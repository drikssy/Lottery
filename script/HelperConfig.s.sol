// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkTokenMock} from "../src/mocks/LinkTokenMock.sol";

contract HelperConfig is Script {
    struct Config {
        uint256 participationAmount;
        uint256 duration;
        address coordinatorAddress;
        bytes32 gazMaxHash;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        address linkTokenAddress;
    }

    Config private activeConfig;

    constructor() {
        if (block.chainid == 1) {
            activeConfig = getMainnetETHConfig();
        } else if (block.chainid == 11155111) {
            activeConfig = getSepoliaETHConfig();
        } else {
            activeConfig = getOrCreateAnvilConfig();
        }
    }

    function getSepoliaETHConfig() public pure returns (Config memory) {
        return
            Config({
                participationAmount: 0.01 ether,
                duration: 1 minutes,
                coordinatorAddress: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
                gazMaxHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subscriptionId: 0,
                callbackGasLimit: 500000,
                linkTokenAddress: 0x779877A7B0D9E8603169DdbD7836e478b4624789
            });
    }

    function getMainnetETHConfig() public pure returns (Config memory) {
        return
            Config({
                participationAmount: 0.01 ether,
                duration: 1 minutes,
                coordinatorAddress: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909,
                gazMaxHash: 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef,
                subscriptionId: 0,
                callbackGasLimit: 500000,
                linkTokenAddress: 0x514910771AF9Ca656af840dff83E8264EcF986CA
            });
    }

    function getOrCreateAnvilConfig() public returns (Config memory) {
        // we need the VRFCoordinator Mock here
        if (activeConfig.coordinatorAddress != address(0)) {
            return activeConfig;
        }
        // create the VRFCoordinator Mock
        uint96 baseFee = 0.25 ether; // 0.25 LINK
        uint96 gasPriceLink = 1e9; // 1 gwei
        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinator = new VRFCoordinatorV2Mock(
            baseFee,
            gasPriceLink
        );
        LinkTokenMock linkToken = new LinkTokenMock();

        vm.stopBroadcast();

        return
            Config({
                participationAmount: 0.01 ether,
                duration: 1 minutes,
                coordinatorAddress: address(vrfCoordinator),
                gazMaxHash: 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef,
                subscriptionId: 0,
                callbackGasLimit: 500000,
                linkTokenAddress: address(linkToken)
            });
    }

    function getActiveConfig() public view returns (Config memory) {
        return activeConfig;
    }
}
