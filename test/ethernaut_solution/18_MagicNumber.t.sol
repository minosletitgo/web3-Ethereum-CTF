// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {MagicNum} from "../../src/ethernaut/18_MagicNumber/MagicNumber.sol";
import {MagicNumber_Factory} from "../../src/ethernaut/18_MagicNumber/MagicNumber_Factory.sol";
import {MagicNumber_Attacker} from "./18_MagicNumber_Attacker.sol";

contract MagicNumber_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	MagicNumber_Factory factory;
	MagicNum instContract;
	
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
		
		factory = new MagicNumber_Factory();
		instContract = MagicNum(payable(factory.createInstance(player)));
		
		vm.stopPrank();
	}
	
	function test__Solution_MagicNumber() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_MagicNumber -vv
		
		// 在真实的挑战环境下，如果无法理解`whatIsTheMeaningOfLife`的意义，就无法返回正确的值。
		// 请阅读文章 -> 18_MagicNumber_Puzzle.md
		// 获悉了 调用 whatIsTheMeaningOfLife 返回值 必须是 42(十六进制：0x2a)
		// 即，0x000000000000000000000000000000000000000000000000000000000000002a
		
		bytes memory code = hex"600a600c600039600a6000f3602a60005260206000f3";
		address solver;
		assembly {
			solver := create(0, add(code, 0x20), mload(code))
		}
		
		instContract.setSolver(solver);
	}
}
