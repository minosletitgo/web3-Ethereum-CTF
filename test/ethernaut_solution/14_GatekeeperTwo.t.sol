// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {GatekeeperTwo} from "../../src/ethernaut/14_GatekeeperTwo/GatekeeperTwo.sol";
import {GatekeeperTwo_Factory} from "../../src/ethernaut/14_GatekeeperTwo/GatekeeperTwo_Factory.sol";
import {GatekeeperTwo_Attacker} from "./14_GatekeeperTwo_Attacker.sol";

contract GatekeeperTwo_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	GatekeeperTwo_Factory factory;
	GatekeeperTwo instContract;
	
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
		
		factory = new GatekeeperTwo_Factory();
		instContract = GatekeeperTwo(payable(factory.createInstance(player)));
		
		vm.stopPrank();
		
		vm.deal(address(player), 101 ether);
	}
	
	function test__Solution_GatekeeperTwo() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_GatekeeperTwo -vv
		
		// 小结：
		// 如果 a ^ b = c
		// 那么 b = a ^ c
		// 同时 a = b ^ c
		
		GatekeeperTwo_Attacker attacker = new GatekeeperTwo_Attacker(instContract);
	}
}
