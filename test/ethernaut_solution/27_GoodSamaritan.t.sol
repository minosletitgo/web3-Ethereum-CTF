// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {GoodSamaritan} from "../../src/ethernaut/27_GoodSamaritan/GoodSamaritan.sol";
import {GoodSamaritan_Factory} from "../../src/ethernaut/27_GoodSamaritan/GoodSamaritan_Factory.sol";
import {GoodSamaritan_Attacker} from "./27_GoodSamaritan_Attacker.sol";

contract GoodSamaritan_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	GoodSamaritan_Factory factory;
	GoodSamaritan instContract;
	
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
		
		factory = new GoodSamaritan_Factory();
		instContract = GoodSamaritan(payable(factory.createInstance(player)));
		
		vm.stopPrank();
	}
	
	function test__Solution_GoodSamaritan() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_GoodSamaritan -vv
		
		// 难点：
		// 如果，只想着`执行攻击代码行后，写入攻击计数器`，那么，必定能够失败。
		// 因为，会全部回滚掉。
		GoodSamaritan_Attacker attacker = new GoodSamaritan_Attacker(instContract);
		attacker.doAttack();
	}
}
