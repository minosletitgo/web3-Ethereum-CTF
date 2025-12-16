// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Telephone} from "../../src/ethernaut/04_Telephone/Telephone.sol";
import {Telephone_Factory} from "../../src/ethernaut/04_Telephone/Telephone_Factory.sol";
import {Telephone_Attacker} from "./04_Telephone_Attacker.sol";

contract Telephone_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");
	
	Telephone_Factory factory;
	Telephone instContract;
	
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
		
		factory = new Telephone_Factory();
		instContract = Telephone(payable(factory.createInstance(player)));
		
		vm.stopPrank();
		
		vm.deal(address(player), 101 ether);
	}
	
	function test__Solution_Telephone() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_Telephone -vv
	
		Telephone_Attacker attacker = new Telephone_Attacker(instContract);
		attacker.doAttack();
	}
}
