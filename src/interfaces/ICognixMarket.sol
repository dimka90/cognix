// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ICognixMarket {
    enum TaskStatus { Created, Assigned, Completed }
    struct Task {
        address employer;
        uint256 reward;
        TaskStatus status;
    }
    function createTask(string calldata _uri) external payable returns (uint256);
}
