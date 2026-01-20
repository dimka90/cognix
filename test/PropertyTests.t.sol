// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/CognixMarket.sol";
import "../src/CognixToken.sol";

contract PropertyTests is Test {
    CognixMarket public market;
    CognixToken public token;
    
    address public employer = address(0x1);
    address public agent = address(0x2);
    
    function setUp() public {
        token = new CognixToken("Cognix Token", "CGX", 1000000 * 1e18, address(this));
        market = new CognixMarket(address(token));
        
        vm.deal(employer, 100 ether);
        vm.deal(agent, 100 ether);
        token.transfer(employer, 10000 * 1e18);
        token.transfer(agent, 10000 * 1e18);
        
        market.setTokenStatus(address(token), true);
    }
    
    /**
     * **Feature: cognix-market-improvements, Property 4: ETH task creation validation**
     * For any task creation attempt with ETH, the system should only succeed when msg.value is greater than zero
     */
    function testFuzz_ETHTaskCreationValidation(uint256 value) public {
        vm.assume(value <= 50 ether); // Reasonable upper bound
        vm.startPrank(employer);
        
        if (value == 0) {
            vm.expectRevert("Reward must be > 0");
            market.createTask{value: value}("ipfs://metadata");
        } else {
            uint256 taskId = market.createTask{value: value}("ipfs://metadata");
            (,,,, uint256 reward,,,) = market.tasks(taskId);
            assertEq(reward, value);
        }
        vm.stopPrank();
    }
    
    /**
     * **Feature: cognix-market-improvements, Property 6: Task counter and event consistency**
     * For any successful task creation, the task counter should increment by exactly one
     */
    function testFuzz_TaskCounterIncrement(uint256 value) public {
        vm.assume(value > 0 && value <= 10 ether);
        vm.startPrank(employer);
        
        uint256 initialCount = market.getTaskCount();
        market.createTask{value: value}("ipfs://metadata");
        uint256 finalCount = market.getTaskCount();
        
        assertEq(finalCount, initialCount + 1);
        vm.stopPrank();
    }
    
    /**
     * **Feature: cognix-market-improvements, Property 9: Task application validation**
     * For any task application attempt, the system should only succeed if the task exists and is in Created status
     */
    function testFuzz_TaskApplicationValidation(uint256 taskId, uint256 stakeAmount) public {
        vm.assume(stakeAmount <= 1000 * 1e18);
        vm.startPrank(agent);
        
        if (stakeAmount > 0) {
            token.approve(address(market), stakeAmount);
        }
        
        if (taskId == 0 || taskId > market.getTaskCount()) {
            vm.expectRevert("Invalid task ID");
            market.applyForTask(taskId, stakeAmount, "ipfs://proposal");
        } else {
            // Create a valid task first
            vm.stopPrank();
            vm.prank(employer);
            uint256 validTaskId = market.createTask{value: 1 ether}("ipfs://metadata");
            
            vm.startPrank(agent);
            if (stakeAmount > 0) {
                token.approve(address(market), stakeAmount);
            }
            market.applyForTask(validTaskId, stakeAmount, "ipfs://proposal");
            
            ICognixMarket.Application[] memory apps = market.getTaskApplications(validTaskId);
            assertEq(apps.length, 1);
            assertEq(apps[0].stakedAmount, stakeAmount);
        }
        vm.stopPrank();
    }
}