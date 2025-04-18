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
        address(0x8975041f8fCB64FD903ab36e817F8b9660D63D52);
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
