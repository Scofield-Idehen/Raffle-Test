// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "../src/raffle.sol";

contract DeployRaffleTicket is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        uint256 ticketPrice = vm.envUint("TICKET_PRICE");
        uint256 interval = vm.envUint("INTERVAL");

        vm.startBroadcast(privateKey);

        raffleTicket raffle = new raffleTicket(ticketPrice, interval);

        console.log("Raffle deployed at:", address(raffle));

        vm.stopBroadcast();
    }
}