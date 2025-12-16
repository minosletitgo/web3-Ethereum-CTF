// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {InflaStore, Meal, Infla} from "../../src/eko2022/05_MetaverseSupermarket/MetaverseSupermarket.sol";
import {MetaverseSupermarket_Factory} from "../../src/eko2022/05_MetaverseSupermarket/MetaverseSupermarket_Factory.sol";
import {MetaverseSupermarket_Attacker} from "./05_MetaverseSupermarket_Attacker.sol";

contract MetaverseSupermarket_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	MetaverseSupermarket_Factory factory;
	InflaStore instContract;
	
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
		
		factory = new MetaverseSupermarket_Factory();
		instContract = InflaStore(factory.createInstance(deployer));
		
		vm.stopPrank();
	}
	
	/**
	 * CODE YOUR SOLUTION HERE
	 */
	function test__Solution_Metaverse_Supermarket() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_Metaverse_Supermarket -vv
	
		MetaverseSupermarket_Attacker attacker = new MetaverseSupermarket_Attacker(instContract);
		attacker.doAttack();
	}
}
