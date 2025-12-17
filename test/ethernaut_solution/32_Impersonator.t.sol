// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Impersonator} from "../../src/ethernaut/32_Impersonator/Impersonator.sol";
import {Impersonator_Factory} from "../../src/ethernaut/32_Impersonator/Impersonator_Factory.sol";
import {Impersonator_Attacker} from "./32_Impersonator_Attacker.sol";

contract Impersonator_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	Impersonator_Factory factory;
	Impersonator instContract;
	
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
		
		factory = new Impersonator_Factory();
		instContract = Impersonator(payable(factory.createInstance(player)));
		
		vm.stopPrank();
		
		vm.deal(address(player), 101 ether);
	}
	
	function test__Solution_Impersonator() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_Impersonator -vv
	
		Impersonator_Attacker attacker = new Impersonator_Attacker(instContract);
		attacker.doAttack();
	}
}
