// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {King} from "../../src/ethernaut/09_King/King.sol";
import {King_Factory} from "../../src/ethernaut/09_King/King_Factory.sol";
import {King_Attacker} from "./09_King_Attacker.sol";

contract King_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");
	
	King_Factory factory;
	King instContract;
	
	modifier checkSolvedByPlayer() {
		vm.startPrank(player, player);
		_;
		vm.stopPrank();
		_isSolved();
	}
	
	/**
	 * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
	 */
	function _isSolved() private{
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
		
		factory = new King_Factory();
		instContract = King(payable(factory.createInstance{value: 0.1 ether}(player)));
		
		vm.stopPrank();
		
		vm.deal(address(player), 0.11 ether);
	}
	
	function test__Solution_King() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_King -vv
	
		King_Attacker attacker = new King_Attacker{value: 0.11 ether}(instContract);
		attacker.doAttack();
	}
}
