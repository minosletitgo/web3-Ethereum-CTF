// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {BetHouse, Pool, PoolToken} from "../../src/ethernaut/34_BetHouse/BetHouse.sol";
import {BetHouse_Factory} from "../../src/ethernaut/34_BetHouse/BetHouse_Factory.sol";
import {BetHouse_Attacker} from "./34_BetHouse_Attacker.sol";

contract BetHouse_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	BetHouse_Factory factory;
	BetHouse instContract;
	
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
		
		factory = new BetHouse_Factory();
		instContract = BetHouse(payable(factory.createInstance(player)));
		
		vm.stopPrank();
		
		vm.deal(address(player), 0.001 ether);
	}
	
	function test__Solution_BetHouse() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_BetHouse -vv
		
		Pool pool = Pool(instContract.pool());
		PoolToken wrappedToken = PoolToken(pool.wrappedToken());
		PoolToken depositToken = PoolToken(pool.depositToken());
		
		BetHouse_Attacker attacker = new BetHouse_Attacker{value: 0.001 ether}(instContract);
		depositToken.transfer(address(attacker), depositToken.balanceOf(player));
		attacker.doAttack();
	}
}
