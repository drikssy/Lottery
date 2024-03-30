// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle, Raffle__NotRightETHAmount, Raffle__NotOpen, Raffle__TransferETHToWinnerFailed, Raffle__HasNoPlayers} from "../../src/Raffle.sol";

contract RaffleTest is Test {
    Raffle private raffle;
    address public PLAYER = makeAddr("player");
    uint256 private constant INITIAL_AMOUNT = 1 ether;
    uint256 private constant PARTICIPATION_AMOUNT = 0.01 ether;

    function setUp() public {
        raffle = (new DeployRaffle()).run();
        vm.deal(PLAYER, 1 ether);
    }

    function testRaffleRevertIfParticipateWithWrongAmount() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle__NotRightETHAmount.selector);
        raffle.participate{value: 0.5 ether}();
    }

    function testRaffleRevertIfStateIsNotOpen() public {
        vm.prank(PLAYER);
        raffle.participate{value: PARTICIPATION_AMOUNT}();
        vm.warp(raffle.getStartingTime() + raffle.getInterval());
        raffle.requestPickWinner();

        vm.prank(PLAYER);
        vm.expectRevert(Raffle__NotOpen.selector);
        raffle.participate{value: PARTICIPATION_AMOUNT}();
    }

    function testRafflePlayersArrayIsUpdatedAtParticipation() public {
        vm.prank(PLAYER);
        raffle.participate{value: PARTICIPATION_AMOUNT}();

        assertEq(raffle.getPlayerFromIndex(0), PLAYER);
    }
}
