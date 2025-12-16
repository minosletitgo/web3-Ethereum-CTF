// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Pelusa} from "../../src/eko2022/10_Pelusa/Pelusa.sol";
import {Pelusa_Factory} from "../../src/eko2022/10_Pelusa/Pelusa_Factory.sol";
import {Pelusa_Attacker} from "./10_Pelusa_Attacker.sol";

contract Pelusa_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	Pelusa_Factory factory;
	Pelusa instContract;
	
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
		
		factory = new Pelusa_Factory();
		instContract = Pelusa(factory.createInstance(player));
		
		vm.stopPrank();
	}
	
	function test__Solution_Pelusa() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_Pelusa -vv
	
		Pelusa_Attacker attacker = new Pelusa_Attacker(instContract, address(factory));
		attacker.doAttack();
	}
}
