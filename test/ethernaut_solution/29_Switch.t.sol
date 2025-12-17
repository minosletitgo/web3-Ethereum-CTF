// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Switch} from "../../src/ethernaut/29_Switch/Switch.sol";
import {Switch_Factory} from "../../src/ethernaut/29_Switch/Switch_Factory.sol";
import {Switch_Attacker} from "./29_Switch_Attacker.sol";

contract Switch_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	Switch_Factory factory;
	Switch instContract;
	
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
		
		factory = new Switch_Factory();
		instContract = Switch(payable(factory.createInstance(player)));
		
		vm.stopPrank();
		
		vm.deal(address(player), 101 ether);
	}
	
	function test__Solution_Switch() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_Switch -vv
	
		Switch_Attacker attacker = new Switch_Attacker(instContract);
		attacker.doAttack();
	}
}
