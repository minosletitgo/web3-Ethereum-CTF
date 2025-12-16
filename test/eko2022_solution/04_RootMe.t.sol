// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {RootMe} from "../../src/eko2022/04_RootMe/RootMe.sol";
import {RootMe_Factory} from "../../src/eko2022/04_RootMe/RootMe_Factory.sol";
import {RootMe_Attacker} from "./04_RootMe_Attacker.sol";

contract RootMe_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	RootMe_Factory factory;
	RootMe instContract;
	
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
		
		factory = new RootMe_Factory();
		instContract = RootMe(factory.createInstance(player));
		
		vm.stopPrank();
	}
	
	function test__Solution_RootMe() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_RootMe -vv
	
		RootMe_Attacker attacker = new RootMe_Attacker(instContract);
		attacker.doAttack();
	}
}
