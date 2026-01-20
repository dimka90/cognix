// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract CognixMarket is Ownable {
    constructor() Ownable(msg.sender) {}
    function createTask(string calldata) external payable returns (uint256) {
        return 1;
    }
}
