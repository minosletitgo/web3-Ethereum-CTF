// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Shop} from "../../src/ethernaut/21_Shop/Shop.sol";
import {Shop_Factory} from "../../src/ethernaut/21_Shop/Shop_Factory.sol";
import {Shop_Attacker} from "./21_Shop_Attacker.sol";

contract Shop_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	Shop_Factory factory;
	Shop instContract;
	
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
		
		factory = new Shop_Factory();
		instContract = Shop(payable(factory.createInstance(player)));
		
		vm.stopPrank();
		
		vm.deal(address(player), 101 ether);
	}
	
	function test__Solution_Shop() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_Shop -vv
	
		Shop_Attacker attacker = new Shop_Attacker(instContract);
		attacker.doAttack();
	}
}
