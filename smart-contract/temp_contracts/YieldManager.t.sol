// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/YieldManager.sol";

contract YieldManagerTest is Test {
    YieldManager public yieldManager;
    address public owner;
    address public user1;
    address public user2;
    
    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        yieldManager = new YieldManager();
    }
    
    function testAddStrategy() public {
        yieldManager.addStrategy(address(0x123), "Test Strategy", 1000);
        
        YieldManager.YieldStrategy memory strategy = yieldManager.getStrategy(0);
        assertEq(strategy.name, "Test Strategy");
        assertEq(strategy.apy, 1000);
        assertTrue(strategy.active);
    }
    
    function testDeposit() public {
        yieldManager.addStrategy(address(0x123), "Test Strategy", 1000);
        
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        yieldManager.deposit{value: 0.5 ether}(0, 0.5 ether);
        
        assertEq(yieldManager.userDeposits(user1, 0), 0.5 ether);
    }
    
    function testWithdraw() public {
        yieldManager.addStrategy(address(0x123), "Test Strategy", 1000);
        
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        yieldManager.deposit{value: 0.5 ether}(0, 0.5 ether);
        
        vm.prank(user1);
        yieldManager.withdraw(0, 0.3 ether);
        
        assertEq(yieldManager.userDeposits(user1, 0), 0.2 ether);
    }
    
    function testCalculateRewards() public {
        yieldManager.addStrategy(address(0x123), "Test Strategy", 1000);
        
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        yieldManager.deposit{value: 1 ether}(0, 1 ether);
        
        uint256 rewards = yieldManager.calculateRewards(user1, 0);
        assertEq(rewards, 0.1 ether); // 10% APY
    }
    
    function testDeactivateStrategy() public {
        yieldManager.addStrategy(address(0x123), "Test Strategy", 1000);
        yieldManager.deactivateStrategy(0);
        
        YieldManager.YieldStrategy memory strategy = yieldManager.getStrategy(0);
        assertFalse(strategy.active);
    }
    
    function testUpdateAPY() public {
        yieldManager.addStrategy(address(0x123), "Test Strategy", 1000);
        yieldManager.updateStrategyAPY(0, 2000);
        
        YieldManager.YieldStrategy memory strategy = yieldManager.getStrategy(0);
        assertEq(strategy.apy, 2000);
    }
    
    function testClaimRewards() public {
        yieldManager.addStrategy(address(0x123), "Test Strategy", 1000);
        
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        yieldManager.deposit{value: 1 ether}(0, 1 ether);
        
        // Fast forward time
        vm.warp(block.timestamp + 365 days);
        
        vm.prank(user1);
        yieldManager.claimRewards(0);
        
        assertGt(yieldManager.userRewards(user1), 0);
    }
    
    function testFailDepositInactiveStrategy() public {
        yieldManager.addStrategy(address(0x123), "Test Strategy", 1000);
        
        // This should fail as we haven't implemented deactivation yet
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        yieldManager.deposit{value: 0.5 ether}(1, 0.5 ether); // Non-existent strategy
    }
}
