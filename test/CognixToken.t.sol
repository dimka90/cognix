// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/CognixToken.sol";

/**
 * @title CognixTokenTest
 * @dev Test suite for CognixToken ERC20 implementation
 */
contract CognixTokenTest is Test {
    CognixToken public token;
    
    // Test accounts
    address public owner;
    address public alice;
    address public bob;
    address public charlie;
    
    // Test constants
    string constant TOKEN_NAME = "Cognix Token";
    string constant TOKEN_SYMBOL = "CGX";
    uint256 constant INITIAL_SUPPLY = 1000000 * 10**18; // 1 million tokens
    uint256 constant MAX_SUPPLY = 1000000000 * 10**18; // 1 billion tokens
    
    // Events for testing
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    function setUp() public {
        // Set up test accounts
        owner = makeAddr("owner");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");
        
        // Deploy token contract
        vm.prank(owner);
        token = new CognixToken(TOKEN_NAME, TOKEN_SYMBOL, INITIAL_SUPPLY, owner);
    }
    
    // Helper functions for testing
    
    function _mintTokens(address to, uint256 amount) internal {
        vm.prank(owner);
        token.mint(to, amount);
    }
    
    function _approveTokens(address from, address spender, uint256 amount) internal {
        vm.prank(from);
        token.approve(spender, amount);
    }
    
    function _transferTokens(address from, address to, uint256 amount) internal {
        vm.prank(from);
        token.transfer(to, amount);
    }
    
    function _transferFromTokens(address spender, address from, address to, uint256 amount) internal {
        vm.prank(spender);
        token.transferFrom(from, to, amount);
    }
    
    function _burnTokens(address from, uint256 amount) internal {
        vm.prank(from);
        token.burn(amount);
    }
    
    function _burnFromTokens(address spender, address from, uint256 amount) internal {
        vm.prank(spender);
        token.burnFrom(from, amount);
    }
    
    // Basic deployment and initialization tests
    
    function test_Deployment() public {
        assertEq(token.name(), TOKEN_NAME);
        assertEq(token.symbol(), TOKEN_SYMBOL);
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
        assertEq(token.owner(), owner);
        assertTrue(token.hasOwner());
    }
    
    function test_InitialState() public {
        assertEq(token.balanceOf(alice), 0);
        assertEq(token.balanceOf(bob), 0);
        assertEq(token.allowance(owner, alice), 0);
        assertEq(token.allowance(alice, bob), 0);
    }
}
    
    // Transfer function tests
    
    function test_Transfer_Success() public {
        uint256 transferAmount = 1000 * 10**18;
        
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, alice, transferAmount);
        
        _transferTokens(owner, alice, transferAmount);
        
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - transferAmount);
        assertEq(token.balanceOf(alice), transferAmount);
    }
    
    function test_Transfer_InsufficientBalance() public {
        uint256 transferAmount = INITIAL_SUPPLY + 1;
        
        vm.expectRevert(
            abi.encodeWithSelector(
                CognixToken.InsufficientBalance.selector,
                INITIAL_SUPPLY,
                transferAmount
            )
        );
        _transferTokens(owner, alice, transferAmount);
    }
    
    function test_Transfer_ToZeroAddress() public {
        uint256 transferAmount = 1000 * 10**18;
        
        vm.expectRevert(
            abi.encodeWithSelector(CognixToken.InvalidAddress.selector, address(0))
        );
        vm.prank(owner);
        token.transfer(address(0), transferAmount);
    }
    
    function test_Transfer_ZeroAmount() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, alice, 0);
        
        _transferTokens(owner, alice, 0);
        
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
        assertEq(token.balanceOf(alice), 0);
    }
    
    // Approval function tests
    
    function test_Approve_Success() public {
        uint256 approvalAmount = 5000 * 10**18;
        
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, alice, approvalAmount);
        
        _approveTokens(owner, alice, approvalAmount);
        
        assertEq(token.allowance(owner, alice), approvalAmount);
    }
    
    function test_Approve_ZeroAddress() public {
        uint256 approvalAmount = 5000 * 10**18;
        
        vm.expectRevert(
            abi.encodeWithSelector(CognixToken.InvalidAddress.selector, address(0))
        );
        vm.prank(owner);
        token.approve(address(0), approvalAmount);
    }
    
    function test_Approve_OverwriteExisting() public {
        uint256 firstApproval = 1000 * 10**18;
        uint256 secondApproval = 2000 * 10**18;
        
        _approveTokens(owner, alice, firstApproval);
        assertEq(token.allowance(owner, alice), firstApproval);
        
        _approveTokens(owner, alice, secondApproval);
        assertEq(token.allowance(owner, alice), secondApproval);
    }
    
    // TransferFrom function tests
    
    function test_TransferFrom_Success() public {
        uint256 approvalAmount = 5000 * 10**18;
        uint256 transferAmount = 3000 * 10**18;
        
        _approveTokens(owner, alice, approvalAmount);
        
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, bob, transferAmount);
        
        _transferFromTokens(alice, owner, bob, transferAmount);
        
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - transferAmount);
        assertEq(token.balanceOf(bob), transferAmount);
        assertEq(token.allowance(owner, alice), approvalAmount - transferAmount);
    }
    
    function test_TransferFrom_InsufficientAllowance() public {
        uint256 approvalAmount = 1000 * 10**18;
        uint256 transferAmount = 2000 * 10**18;
        
        _approveTokens(owner, alice, approvalAmount);
        
        vm.expectRevert(
            abi.encodeWithSelector(
                CognixToken.InsufficientAllowance.selector,
                approvalAmount,
                transferAmount
            )
        );
        _transferFromTokens(alice, owner, bob, transferAmount);
    }
    
    function test_TransferFrom_MaxAllowance() public {
        uint256 transferAmount = 1000 * 10**18;
        
        _approveTokens(owner, alice, type(uint256).max);
        _transferFromTokens(alice, owner, bob, transferAmount);
        
        // Max allowance should remain unchanged
        assertEq(token.allowance(owner, alice), type(uint256).max);
        assertEq(token.balanceOf(bob), transferAmount);
    }
    
    // Balance and allowance query tests
    
    function test_BalanceOf_MultipleAccounts() public {
        uint256 amount1 = 1000 * 10**18;
        uint256 amount2 = 2000 * 10**18;
        
        _transferTokens(owner, alice, amount1);
        _transferTokens(owner, bob, amount2);
        
        assertEq(token.balanceOf(alice), amount1);
        assertEq(token.balanceOf(bob), amount2);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - amount1 - amount2);
    }
    
    function test_Allowance_MultipleSpenders() public {
        uint256 allowance1 = 1000 * 10**18;
        uint256 allowance2 = 2000 * 10**18;
        
        _approveTokens(owner, alice, allowance1);
        _approveTokens(owner, bob, allowance2);
        
        assertEq(token.allowance(owner, alice), allowance1);
        assertEq(token.allowance(owner, bob), allowance2);
        assertEq(token.allowance(alice, bob), 0);
    }
    
    // Minting function tests
    
    function test_Mint_Success() public {
        uint256 mintAmount = 10000 * 10**18;
        uint256 initialSupply = token.totalSupply();
        
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), alice, mintAmount);
        
        _mintTokens(alice, mintAmount);
        
        assertEq(token.balanceOf(alice), mintAmount);
        assertEq(token.totalSupply(), initialSupply + mintAmount);
    }
    
    function test_Mint_OnlyOwner() public {
        uint256 mintAmount = 10000 * 10**18;
        
        vm.expectRevert(
            abi.encodeWithSelector(CognixToken.UnauthorizedAccess.selector, alice, owner)
        );
        vm.prank(alice);
        token.mint(bob, mintAmount);
    }
    
    function test_Mint_ToZeroAddress() public {
        uint256 mintAmount = 10000 * 10**18;
        
        vm.expectRevert(
            abi.encodeWithSelector(CognixToken.InvalidAddress.selector, address(0))
        );
        vm.prank(owner);
        token.mint(address(0), mintAmount);
    }
    
    function test_Mint_MaxSupplyExceeded() public {
        uint256 exceedingAmount = MAX_SUPPLY - INITIAL_SUPPLY + 1;
        
        vm.expectRevert(
            abi.encodeWithSelector(
                CognixToken.MaxSupplyExceeded.selector,
                INITIAL_SUPPLY + exceedingAmount,
                MAX_SUPPLY
            )
        );
        _mintTokens(alice, exceedingAmount);
    }
    
    function test_Mint_ZeroAmount() public {
        uint256 initialSupply = token.totalSupply();
        uint256 initialBalance = token.balanceOf(alice);
        
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), alice, 0);
        
        _mintTokens(alice, 0);
        
        assertEq(token.balanceOf(alice), initialBalance);
        assertEq(token.totalSupply(), initialSupply);
    }
    
    // Burning function tests
    
    function test_Burn_Success() public {
        uint256 burnAmount = 5000 * 10**18;
        uint256 initialSupply = token.totalSupply();
        
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, address(0), burnAmount);
        
        _burnTokens(owner, burnAmount);
        
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - burnAmount);
        assertEq(token.totalSupply(), initialSupply - burnAmount);
    }
    
    function test_Burn_InsufficientBalance() public {
        uint256 burnAmount = 1000 * 10**18;
        
        vm.expectRevert(
            abi.encodeWithSelector(CognixToken.InsufficientBalance.selector, 0, burnAmount)
        );
        _burnTokens(alice, burnAmount);
    }
    
    function test_Burn_ZeroAmount() public {
        uint256 initialSupply = token.totalSupply();
        uint256 initialBalance = token.balanceOf(owner);
        
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, address(0), 0);
        
        _burnTokens(owner, 0);
        
        assertEq(token.balanceOf(owner), initialBalance);
        assertEq(token.totalSupply(), initialSupply);
    }
    
    function test_BurnFrom_Success() public {
        uint256 approvalAmount = 10000 * 10**18;
        uint256 burnAmount = 5000 * 10**18;
        uint256 initialSupply = token.totalSupply();
        
        _approveTokens(owner, alice, approvalAmount);
        
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, address(0), burnAmount);
        
        _burnFromTokens(alice, owner, burnAmount);
        
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - burnAmount);
        assertEq(token.totalSupply(), initialSupply - burnAmount);
        assertEq(token.allowance(owner, alice), approvalAmount - burnAmount);
    }
    
    function test_BurnFrom_InsufficientAllowance() public {
        uint256 approvalAmount = 1000 * 10**18;
        uint256 burnAmount = 2000 * 10**18;
        
        _approveTokens(owner, alice, approvalAmount);
        
        vm.expectRevert(
            abi.encodeWithSelector(
                CognixToken.InsufficientAllowance.selector,
                approvalAmount,
                burnAmount
            )
        );
        _burnFromTokens(alice, owner, burnAmount);
    }
    
    // Ownership function tests
    
    function test_TransferOwnership_Success() public {
        vm.expectEmit(true, true, false, true);
        emit OwnershipTransferred(owner, alice);
        
        vm.prank(owner);
        token.transferOwnership(alice);
        
        assertEq(token.owner(), alice);
        assertTrue(token.hasOwner());
    }
    
    function test_TransferOwnership_OnlyOwner() public {
        vm.expectRevert(
            abi.encodeWithSelector(CognixToken.UnauthorizedAccess.selector, alice, owner)
        );
        vm.prank(alice);
        token.transferOwnership(bob);
    }
    
    function test_TransferOwnership_ToZeroAddress() public {
        vm.expectRevert(
            abi.encodeWithSelector(CognixToken.InvalidAddress.selector, address(0))
        );
        vm.prank(owner);
        token.transferOwnership(address(0));
    }
    
    function test_RenounceOwnership_Success() public {
        vm.expectEmit(true, true, false, true);
        emit OwnershipTransferred(owner, address(0));
        
        vm.prank(owner);
        token.renounceOwnership();
        
        assertEq(token.owner(), address(0));
        assertFalse(token.hasOwner());
    }
    
    function test_RenounceOwnership_OnlyOwner() public {
        vm.expectRevert(
            abi.encodeWithSelector(CognixToken.UnauthorizedAccess.selector, alice, owner)
        );
        vm.prank(alice);
        token.renounceOwnership();
    }
    
    function test_AdminFunctions_AfterRenounceOwnership() public {
        vm.prank(owner);
        token.renounceOwnership();
        
        vm.expectRevert(
            abi.encodeWithSelector(CognixToken.UnauthorizedAccess.selector, owner, address(0))
        );
        vm.prank(owner);
        token.mint(alice, 1000 * 10**18);
    }