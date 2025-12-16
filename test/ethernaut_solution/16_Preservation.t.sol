// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Preservation} from "../../src/ethernaut/16_Preservation/Preservation.sol";
import {Preservation_Factory} from "../../src/ethernaut/16_Preservation/Preservation_Factory.sol";
import {Preservation_Attacker} from "./16_Preservation_Attacker.sol";

contract Preservation_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	Preservation_Factory factory;
	Preservation instContract;
	
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
		
		factory = new Preservation_Factory();
		instContract = Preservation(payable(factory.createInstance(player)));
		
		vm.stopPrank();
	}
	
	function test__Solution_Preservation() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_Preservation -vv
	
		Preservation_Attacker attacker = new Preservation_Attacker(instContract);
		attacker.doAttack();
		instContract.setFirstTime(123);
	}
}
