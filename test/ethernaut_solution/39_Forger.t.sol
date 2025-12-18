// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Forger} from "../../src/ethernaut/39_Forger/Forger.sol";
import {Forger_Factory} from "../../src/ethernaut/39_Forger/Forger_Factory.sol";
import {Forger_Attacker} from "./39_Forger_Attacker.sol";

contract Forger_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	Forger_Factory factory;
	Forger instContract;
	
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
		
		factory = new Forger_Factory();
		instContract = Forger(payable(factory.createInstance(player)));
		
		vm.stopPrank();
	}
	
	function test__Solution_Forger() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_Forger -vv
		
		console.log("instContract.totalSupply()", instContract.totalSupply());
		
		Forger_Attacker attacker = new Forger_Attacker(instContract);
		attacker.doAttack();
	}
}
