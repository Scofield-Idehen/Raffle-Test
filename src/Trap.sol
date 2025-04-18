// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";
import {raffleTicket} from "./raffle.sol";

contract RaffleStuckTrap is ITrap {
    raffleTicket public target = raffleTicket(0x307C59D0dB3124Cd1C9f935285226D5622289BCD);

    function collect() external view override returns (bytes memory) {
        address[] memory players = target.getParticipants();
        uint playerCount = players.length;
        uint8 currentState = uint8(target.getRaffleState());
        uint balance = address(target).balance;
        address winner = target.getWinner();

        return abi.encode(players, playerCount, currentState, balance, winner);
    }

    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        (
            ,
            uint playerCount,
            uint8 currentState,
            uint balance,
            address winner
        ) = abi.decode(data[0], (address[], uint, uint8, uint, address));

        bool stuckInCalculating = currentState == 1 && playerCount > 0 && balance > 0 && winner == address(0);

        return (stuckInCalculating, bytes(""));
    }
}
