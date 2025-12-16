// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {SmartHorrocrux} from "../../src/eko2022/06_SmartHorrocrux/SmartHorrocrux.sol";
import {SmartHorrocrux_Factory} from "../../src/eko2022/06_SmartHorrocrux/SmartHorrocrux_Factory.sol";
import {SmartHorrocrux_Attacker} from "./06_SmartHorrocrux_Attacker.sol";

contract Smart_Horrocrux_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	SmartHorrocrux_Factory factory;
	SmartHorrocrux smartHorrocrux;
	
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
		vm.deal(player, 2);
		
		startHoax(deployer);
		
		factory = new SmartHorrocrux_Factory();
		smartHorrocrux = SmartHorrocrux(factory.createInstance{value: 2}(player));
		
		vm.stopPrank();
	}
	
	/**
	 * CODE YOUR SOLUTION HERE
	 */
	function test__Solution_SmartHorrocrux() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_SmartHorrocrux -vv
	
		SmartHorrocrux_Attacker attacker = new SmartHorrocrux_Attacker{value: 2}(smartHorrocrux);
		attacker.doAttack();
	}
}

