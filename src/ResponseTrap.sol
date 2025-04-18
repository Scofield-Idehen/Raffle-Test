// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";

struct CollectOutput {
    uint256 balance;
    uint256 blockNumber;
    bool isTriggered;
}

interface IResponseProtocol {
    function getBalance() external view returns (uint256);
}

contract ResponseTrap is ITrap {
    // Deployed on Holesky
    address private responseProtocol =
        address(0x307C59D0dB3124Cd1C9f935285226D5622289BCD);
    uint256 private triggerAtBlockNumber = 0; // <---- Update this value to trigger the trap

    function collect() external view returns (bytes memory) {
        IResponseProtocol response = IResponseProtocol(responseProtocol);
        return
            abi.encode(
                CollectOutput({
                    isTriggered: block.number == triggerAtBlockNumber,
                    balance: response.getBalance(),
                    blockNumber: block.number
                })
            );
    }

    function shouldRespond(
        bytes[] calldata data
    ) external pure returns (bool, bytes memory) {
        CollectOutput memory output = abi.decode(data[0], (CollectOutput));

        if (output.isTriggered) {
            return (true, abi.encode(output.blockNumber));
        }

        return (false, bytes(""));
    }

    
}
