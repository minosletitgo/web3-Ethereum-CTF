// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Reentrance} from "../../src/ethernaut/10_Reentrance/Reentrance.sol";
import {Reentrance_Factory} from "../../src/ethernaut/10_Reentrance/Reentrance_Factory.sol";
import {Reentrance_Attacker} from "./10_Reentrance_Attacker.sol";

contract Reentrance_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");
	
	Reentrance_Factory factory;
	Reentrance instContract;
	
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
		
		factory = new Reentrance_Factory();
		instContract = Reentrance(payable(factory.createInstance{value: 100 ether}(player)));
		
		vm.stopPrank();
		
		vm.deal(address(player), 1 ether);
	}
	
	function test__Solution_Reentrance() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_Reentrance -vv
	
		Reentrance_Attacker attacker = new Reentrance_Attacker{value: 1 ether}(instContract);
		attacker.doAttack();
	}
}
