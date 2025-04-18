// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title Raffle
 * @dev Implements raffle draw without Chainlink randomness
 * @author Scofield Idehen
 * @notice You can use this contract for raffle draws and other related activities.
 */

contract raffleTicket {
    // State variables
    uint private immutable i_ticketPrice;
    uint private immutable i_interval;
    uint private s_timestamp;

    address payable[] private s_participants;
    address private s_winner;

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    RaffleState private s_rafflestate;

    // Errors
    error Raffle__InsufficientETH();
    error Raffle__TransferFailed();
    error Raffle__NotOpenRaffle();
    error Raffle__UpkeepNotNeeded(uint currentBalance, uint numPlayers, uint raffleState);

    // Events
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    // Constructor
    constructor(uint ticketPrice, uint interval) {
        i_ticketPrice = ticketPrice;
        i_interval = interval;
        s_timestamp = block.timestamp;
        s_rafflestate = RaffleState.OPEN;
    }

    // Enter raffle
    function enterRaffle() external payable {
        if (msg.value < i_ticketPrice) revert Raffle__InsufficientETH();
        if (s_rafflestate != RaffleState.OPEN) revert Raffle__NotOpenRaffle();

        s_participants.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    // Check if upkeep is needed
    function checkUpkeep(bytes memory) public view returns (bool upkeepNeeded, bytes memory) {
        bool timePassed = (block.timestamp - s_timestamp) >= i_interval;
        bool isOpen = s_rafflestate == RaffleState.OPEN;
        bool hasPlayers = s_participants.length > 0;
        bool hasBalance = address(this).balance > 0;

        upkeepNeeded = timePassed && isOpen && hasPlayers && hasBalance;
        return (upkeepNeeded, "0x0");
    }

    // Perform upkeep — pick winner pseudo-randomly
    function performUpkeep(bytes calldata) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_participants.length, uint(s_rafflestate));
        }

        s_rafflestate = RaffleState.CALCULATING;

        // Pseudo-random index selection (not secure for production)
        uint index = uint(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, s_participants.length))) % s_participants.length;
        address payable winner = s_participants[index];
        s_winner = winner; // 

        s_rafflestate = RaffleState.OPEN;
        //s_participants = new address payable;
        s_timestamp = block.timestamp;

        emit WinnerPicked(winner);

        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) revert Raffle__TransferFailed();
    }

    // View functions
    function getRaffleState() external view returns (RaffleState) {
        return s_rafflestate;
    }

    function getPlayer(uint index) external view returns (address) {
        return s_participants[index];
    }

    function getParticipants() external view returns (address[] memory) {
    address[] memory participants = new address[](s_participants.length);
    for (uint i = 0; i < s_participants.length; i++) {
        participants[i] = s_participants[i];
    }
    return participants;
}

    function getWinner() external view returns (address) {
        return s_winner;
    }

    function getTicketPrice() external view returns (uint) {
        return i_ticketPrice;
    }
}
