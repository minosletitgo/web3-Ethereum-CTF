// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {NotOptimisticPortal} from "../../src/ethernaut/40_NotOptimisticPortal/NotOptimisticPortal.sol";
import {NotOptimisticPortal_Factory} from "../../src/ethernaut/40_NotOptimisticPortal/NotOptimisticPortal_Factory.sol";
import {NotOptimisticPortal_Attacker} from "./40_NotOptimisticPortal_Attacker.sol";

contract NotOptimisticPortal_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	NotOptimisticPortal_Factory factory;
	NotOptimisticPortal instContract;
	
	modifier checkSolvedByPlayer() {
		vm.startPrank(player, player);
		_;
		vm.stopPrank();
		_isSolved();
	}
	
	/**
	 * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
	 */
	function _isSolved() private view {
		if (factory.validateInstance(player)) {
			console.log("\x1b[33m%s\x1b[0m", ">>>>>>>>>>>>>> Congratulations, you have successfully completed the challenge >>>>>>>>>>>>>>");
		} else {
			revert(">>>>>>>>>>>>>> Sorry, you failed the challenge >>>>>>>>>>>>>>");
		}
	}
	
	/**
	 * SETS UP CHALLENGE - DO NOT TOUCH
	 */
	function setUp() public {
		startHoax(deployer);
		
		factory = new NotOptimisticPortal_Factory();
		instContract = NotOptimisticPortal(payable(factory.createInstance(player)));
		
		vm.stopPrank();
	}
	
	function test__Solution_NotOptimisticPortal() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_NotOptimisticPortal -vv
		
		console.log("Hello World");
	}
}
