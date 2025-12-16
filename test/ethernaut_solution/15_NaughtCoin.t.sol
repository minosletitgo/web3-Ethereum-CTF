// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {NaughtCoin} from "../../src/ethernaut/15_NaughtCoin/NaughtCoin.sol";
import {NaughtCoin_Factory} from "../../src/ethernaut/15_NaughtCoin/NaughtCoin_Factory.sol";
import {NaughtCoin_Attacker} from "./15_NaughtCoin_Attacker.sol";

contract NaughtCoin_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	NaughtCoin_Factory factory;
	NaughtCoin instContract;
	
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
		
		factory = new NaughtCoin_Factory();
		instContract = NaughtCoin(payable(factory.createInstance(player)));
		
		vm.stopPrank();
	}
	
	function test__Solution_NaughtCoin() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_NaughtCoin -vv
		
		NaughtCoin_Attacker attacker = new NaughtCoin_Attacker(instContract);
		instContract.approve(address(attacker), instContract.balanceOf(player));
		attacker.doAttack();
	}
}
