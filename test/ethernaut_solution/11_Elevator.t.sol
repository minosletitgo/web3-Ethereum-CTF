// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Elevator} from "../../src/ethernaut/11_Elevator/Elevator.sol";
import {Elevator_Factory} from "../../src/ethernaut/11_Elevator/Elevator_Factory.sol";
import {Elevator_Attacker} from "./11_Elevator_Attacker.sol";

contract Elevator_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");
	
	Elevator_Factory factory;
	Elevator instContract;
	
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
		
		factory = new Elevator_Factory();
		instContract = Elevator(payable(factory.createInstance(player)));
		
		vm.stopPrank();
		
		vm.deal(address(player), 101 ether);
	}
	
	function test__Solution_Elevator() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_Elevator -vv
	
		Elevator_Attacker attacker = new Elevator_Attacker(instContract);
		attacker.doAttack();
	}
}
