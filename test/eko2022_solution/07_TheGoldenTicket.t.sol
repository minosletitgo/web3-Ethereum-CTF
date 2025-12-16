// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {GoldenTicket} from "../../src/eko2022/07_TheGoldenTicket/TheGoldenTicket.sol";
import {TheGoldenTicket_Factory} from "../../src/eko2022/07_TheGoldenTicket/TheGoldenTicket_Factory.sol";
import {TheGoldenTicket_Attacker} from "./07_TheGoldenTicket_Attacker.sol";

contract TheGoldenTicket_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	TheGoldenTicket_Factory factory;
	GoldenTicket instContract;
	
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
		
		factory = new TheGoldenTicket_Factory();
		instContract = GoldenTicket(factory.createInstance(player));
		
		vm.stopPrank();
	}
	
	/**
	 * CODE YOUR SOLUTION HERE
	 */
	function test__Solution_TheGoldenTicket() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_TheGoldenTicket -vv
	
		TheGoldenTicket_Attacker attakcer = new TheGoldenTicket_Attacker(instContract);
		attakcer.doAttack();
	}
}
