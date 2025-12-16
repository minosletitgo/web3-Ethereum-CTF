// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Fallout} from "../../src/ethernaut/02_Fallout/Fallout.sol";
import {Fallout_Factory} from "../../src/ethernaut/02_Fallout/Fallout_Factory.sol";
import {Fallout_Attacker} from "./02_Fallout_Attacker.sol";

contract Fallout_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");
	
	Fallout_Factory factory;
	Fallout instContract;
	
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
		
		factory = new Fallout_Factory();
		instContract = Fallout(payable(factory.createInstance(player)));
		
		vm.stopPrank();
		
		vm.deal(address(player), 1 ether);
	}
	
	function test__Solution_Fallout() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_Fallout -vv
		
		instContract.Fal1out();
	}
}
