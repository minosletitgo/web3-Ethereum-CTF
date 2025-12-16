// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Denial} from "../../src/ethernaut/20_Denial/Denial.sol";
import {Denial_Factory} from "../../src/ethernaut/20_Denial/Denial_Factory.sol";
import {Denial_Attacker} from "./20_Denial_Attacker.sol";

contract Denial_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	Denial_Factory factory;
	Denial instContract;
	
	modifier checkSolvedByPlayer() {
		vm.startPrank(player, player);
		_;
		vm.stopPrank();
		_isSolved();
	}
	
	/**
	 * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
	 */
	function _isSolved() private {
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
		
		factory = new Denial_Factory();
		instContract = Denial(payable(factory.createInstance{value: 0.001 ether}(player)));
		
		vm.stopPrank();
	}
	
	function test__Solution_Denial() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_Denial -vv
	
		Denial_Attacker attacker = new Denial_Attacker(instContract);
	}
}
