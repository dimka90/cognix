// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/CognixMarket.sol";
import "../src/CognixToken.sol";

contract IntegrationTest is Test {
    CognixMarket public market;
    CognixToken public token;
    
    address public employer;
    address public agent1;
    address public agent2;
    address public arbitrator = address(0x4);
    
    receive() external payable {}
    
    function setUp() public {
        employer = makeAddr("employer");
        agent1 = makeAddr("agent1");
        agent2 = makeAddr("agent2");
        
        token = new CognixToken("Cognix Token", "CGX", 1000000 * 1e18, address(this));
        market = new CognixMarket(address(token));
        
        // Setup accounts
        vm.deal(employer, 100 ether);
        vm.deal(agent1, 10 ether);
        vm.deal(agent2, 10 ether);
        
        token.transfer(employer, 10000 * 1e18);
        token.transfer(agent1, 1000 * 1e18);
        token.transfer(agent2, 1000 * 1e18);
        
        market.setTokenStatus(address(token), true);
        market.setArbitrator(arbitrator);
    }
    
    function testCompleteTaskWorkflow() public {
        // 1. Employer creates task
        vm.prank(employer);
        uint256 taskId = market.createTask{value: 5 ether}("ipfs://task-metadata");
        
        // 2. Multiple agents apply
        vm.startPrank(agent1);
        token.approve(address(market), 50 * 1e18);
        market.applyForTask(taskId, 50 * 1e18, "ipfs://proposal1");
        vm.stopPrank();
        
        vm.startPrank(agent2);
        token.approve(address(market), 30 * 1e18);
        market.applyForTask(taskId, 30 * 1e18, "ipfs://proposal2");
        vm.stopPrank();
        
        // 3. Employer assigns task to agent1
        vm.prank(employer);
        market.assignTask(taskId, agent1);
        
        // 4. Agent submits proof
        vm.prank(agent1);
        market.submitProof(taskId, "ipfs://proof");
        
        // 5. Employer completes task
        uint256 agent1BalanceBefore = agent1.balance;
        uint256 reputationBefore = market.agentReputation(agent1);
        
        vm.prank(employer);
        market.completeTask(taskId);
        
        // Verify final state
        (,,,,, ICognixMarket.TaskStatus status,,) = market.tasks(taskId);
        assertTrue(status == ICognixMarket.TaskStatus.Completed);
        // 5 ether - 2.5% fee (0.125) = 4.875
        assertEq(agent1.balance, agent1BalanceBefore + 4.875 ether);
        assertGt(market.agentReputation(agent1), reputationBefore);
    }
    
    function testDisputeWorkflow() public {
        // Setup task and assign
        vm.prank(employer);
        uint256 taskId = market.createTask{value: 2 ether}("ipfs://task-metadata");
        
        vm.prank(employer);
        market.assignTask(taskId, agent1);
        
        vm.prank(agent1);
        market.submitProof(taskId, "ipfs://proof");
        
        // Employer raises dispute
        vm.prank(employer);
        market.raiseDispute(taskId);
        
        // Arbitrator resolves in favor of agent
        uint256 agent1BalanceBefore = agent1.balance;
        
        vm.prank(arbitrator);
        market.resolveDispute(taskId, false); // favor agent
        
        assertEq(agent1.balance, agent1BalanceBefore + 1.98 ether);
    }
    
    function testEmergencyFunctions() public {
        // Test pause functionality
        market.pause();
        assertTrue(market.paused());
        
        vm.expectRevert();
        vm.prank(employer);
        market.createTask{value: 1 ether}("ipfs://metadata");
        
        // Test unpause
        market.unpause();
        assertFalse(market.paused());
        
        // Should work after unpause
        vm.prank(employer);
        market.createTask{value: 1 ether}("ipfs://metadata");
    }
}