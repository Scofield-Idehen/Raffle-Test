// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";
import {raffleTicket} from "./raffle.sol";

contract RaffleGuardTrap is ITrap {
    raffleTicket public target = raffleTicket(0x4096cdC78dD7b8f74E7228dbD9214bD919dbbA3E);

    function collect() external view override returns (bytes memory) {
        address[] memory players = target.getParticipants();
        uint playerCount = players.length;
        uint8 currentState = uint8(target.raffleState());

        uint balance = address(target).balance;
        address winner = target.getWinner();

        return abi.encode(players, playerCount, currentState, balance, winner);
    }

    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
    // Decode the first input (only one in this case)
    (
        ,
        uint playerCount,
        uint8 currentState,
        ,
    ) = abi.decode(data[0], (address[], uint, uint8, uint, address));

    // Respond only if there are more than 5 players and raffle is OPEN (enum value 0)
    bool should = playerCount > 5 && currentState == 0;

    return (should, bytes("")); // you can return any extra payload if needed
}



}