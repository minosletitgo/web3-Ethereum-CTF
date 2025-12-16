// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {DexTwo, SwappableTokenTwo} from "../../src/ethernaut/23_DexTwo/DexTwo.sol";
import {DexTwo_Factory} from "../../src/ethernaut/23_DexTwo/DexTwo_Factory.sol";
import {DexTwo_Attacker} from "./23_DexTwo_Attacker.sol";

contract DexTwo_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	DexTwo_Factory factory;
	DexTwo instContract;
	
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
		
		factory = new DexTwo_Factory();
		instContract = DexTwo(payable(factory.createInstance(player)));
		
		vm.stopPrank();
		
		vm.deal(address(player), 101 ether);
	}
	
	function test__Solution_DexTwo() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_DexTwo -vv
	
		DexTwo_Attacker attacker = new DexTwo_Attacker(instContract);
		SwappableTokenTwo(instContract.token1()).transfer(address(attacker), 10 ether);
		SwappableTokenTwo(instContract.token2()).transfer(address(attacker), 10 ether);
		attacker.doAttack();
	}
}
