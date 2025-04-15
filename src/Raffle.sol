//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * @title Raffle
 * @dev Implements raffle draw
 * @author Scofield Idehen
 * @notice You can use this contract for raffle draws and other related activities.
 */

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract raffleTicket is VRFConsumerBaseV2{


    //state variables

    // @dev ticketPrice is the price of the ticket and must be called 
    uint private immutable i_ticketPrice;
    error Raffle__InsufficientETH();
    //we use the s_ beacuse there are stored in the storage
    address[] private s_participants;

    //events

    //error
    error Raffle__TrasferedFailed();
    error Raffle__NotOpenRaffle();
    error Raffle__upkeepNotneeded(uint currentBalance, uint numPlayers, uint raffleState);


    /** enum */

    enum RaffleState {
        OPEN,
        CALCULATING
    }



    //@dev interval is the time interval for the raffle draw
    //if set to 700 if the timestamp is 1200 - 500 = enough time has passed 
    uint private immutable i_interval;
    //the time stamp to be used for the raffle draw
    uint private s_timestamp;

    /**working with chainlink vrf */
    //this address is crucial for interacting with the Chainlink VRF service, which provides 
    //secure and verifiable random numbers on the blockchain.
    // private immutable i_vfrCordinator;

    VRFCoordinatorV2Interface private immutable i_vfrCordinator;

    //this is the key used to identify the randomness request
    bytes32 private immutable i_gaslane;
    //this is the subscription id
    uint64 private immutable i_subscriptionId;
    //this is the variable used to store the random number
    uint16 private constant REQUEST_VARABLE = 3;
    //this is the amount of gas to be used for the callback function
    uint32 private immutable i_callbackgas;
    //this is the number of words to be generated
    uint32 private constant NUM_WORD = 1; 
    address private s_winner;
    RaffleState private s_rafflestate;



    //events

    event RafflesEntered(address indexed player);
    event Pickedwinner(address indexed winner);

    //constructor
    constructor(uint ticketPrice, uint interval, address vfrCoordinator, bytes32 gasLane, uint64 subscriptionId, uint32 callbackgas)
    VRFConsumerBaseV2(vfrCoordinator)
    {
        i_ticketPrice = ticketPrice;
        i_interval = interval;
        s_timestamp = block.timestamp;
        //
        i_vfrCordinator = VRFCoordinatorV2Interface(vfrCoordinator);
        // we typecast the address to the VRFCoordinatorV2Interface
        //the i_vfrCordinator is the address of the VRFCoordinatorV2Interface
        i_gaslane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackgas = callbackgas;
        s_rafflestate = RaffleState.OPEN;

    }

    function enterdrew() external payable {
        // we stop using require because it will consume all the gas
        //require(msg.value >= i_ticketPrice, "Raffle: Insufficient amount");
        if (msg.value < i_ticketPrice) { // this saves gas
            revert Raffle__InsufficientETH();
        }
        if(s_rafflestate != RaffleState.OPEN){
            revert Raffle__NotOpenRaffle();
        }
        s_participants.push(payable(msg.sender));

        //this emit the sender address
        emit RafflesEntered(msg.sender);

    }

/**
 * the checkUpKeep functions is the one called to check the chainlink automation 
 * to call the automation function, three things must be true 
 * the time interval has passed between the last raffle draw and the current time
 * the raffle state must be open
 * the number of participants must be greater than 0
 */
    function checkUpKeep(bytes memory /*checkData*/) public view returns (bool upkeepNeeded, bytes memory /*performData*/) {
          bool timehasPassed = (block.timestamp - s_timestamp) >= i_interval;
          bool isOpen = RaffleState.OPEN == s_rafflestate;
          bool hasBalance = address(this).balance > 0;
          bool hasPlayers = s_participants.length > 0;
          upkeepNeeded = (timehasPassed && isOpen && hasBalance && hasPlayers);
          return (upkeepNeeded, "0x0");

    }
    //make it random
    
    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpKeep("");
        if (!upkeepNeeded){
            revert Raffle__upkeepNotneeded(address(this).balance, s_participants.length, uint(s_rafflestate));
        }
        //This code checks if the difference between the current block's timestamp and a stored timestamp 
        //(s_timestamp) is less than a specified interval (i_interval).
        if((block.timestamp - s_timestamp) < i_interval){
            revert();
        }
        // 
        s_rafflestate = RaffleState.CALCULATING;
        //this is the code that will be used to generate the random number
        //it was copied from the chainlink documentation
        //it has been modified to suit our purpose
        // forge install smartcontractkit/chainlink-brownie-contracts@0.6.1 --no-commit
        i_vfrCordinator.requestRandomWords(
            i_gaslane, // this is the key used to identify the randomness request
            i_subscriptionId, // this is the subscription id
            REQUEST_VARABLE, // this is the variable used to store the random number
            i_callbackgas, // this is the amount of gas to be used for the callback function
            NUM_WORD // this is the number of words to be generated

        );

    }

    function fulfillRandomWords(uint256 /*requestId*/,uint256[] memory randomWords) internal override {
        //this is the code that will be used to generate the random winner
        //we use the randomWords[0] because we are generating only one word
        uint indexWinner = randomWords[0] % s_participants.length;
        // the winner is the s_participants[indexWinner]
        address winner = s_participants[indexWinner];
        s_winner = winner;
        s_rafflestate = RaffleState.OPEN;
        s_participants = new address payable[](0);
        s_timestamp = block.timestamp;
        emit Pickedwinner(winner);
        // we use the call function to send the money to the winner
        (bool success, ) = winner.call{value: address(this).balance}("");
        if(!success){
            //we use the revert function to send the money back to the contract
            revert Raffle__TrasferedFailed();
        }
       
    }

    function raffleState() external view returns (RaffleState){
        return s_rafflestate;
    }

    function getplayers(uint indexPlayer) external view returns (address){
        return s_participants[indexPlayer];
    }

    function getWinner() external view returns (address) {
    return s_winner;
}

function getParticipants() external view returns (address[] memory) {
    return s_participants;
}


    /** Get entrance fee before entering */

}
