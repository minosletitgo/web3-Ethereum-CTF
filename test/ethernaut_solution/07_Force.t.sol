// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Force} from "../../src/ethernaut/07_Force/Force.sol";
import {Force_Factory} from "../../src/ethernaut/07_Force/Force_Factory.sol";
import {Force_Attacker} from "./07_Force_Attacker.sol";

contract Force_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");
	
	Force_Factory factory;
	Force instContract;
	
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
		
		factory = new Force_Factory();
		instContract = Force(payable(factory.createInstance(player)));
		
		vm.stopPrank();
		
		vm.deal(address(player), 0.1 ether);
	}
	
	function test__Solution_Force() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_Force -vv
	
		Force_Attacker attacker = new Force_Attacker{value: 0.1 ether}(instContract);
		attacker.doAttack();
	}
}
