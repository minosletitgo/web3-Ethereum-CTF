// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Valve} from "../../src/eko2022/11_GasValve/GasValve.sol";
import {GasValue_Factory} from "../../src/eko2022/11_GasValve/GasValue_Factory.sol";
import {GasValve_Attakcer} from "./11_GasValve_Attakcer.sol";

contract Gas_Valve_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");
	
	GasValue_Factory factory;
	Valve instContract;
	
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
		
		factory = new GasValue_Factory();
		instContract = Valve(factory.createInstance(player));
		
		vm.stopPrank();
	}
	
	function test__Solution_Gas_Valve() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_Gas_Valve -vv
	
		GasValve_Attakcer attakcer = new GasValve_Attakcer(instContract);
		attakcer.doAttack();
	}
}
