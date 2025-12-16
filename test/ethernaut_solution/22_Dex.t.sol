// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Dex, SwappableToken} from "../../src/ethernaut/22_Dex/Dex.sol";
import {Dex_Factory} from "../../src/ethernaut/22_Dex/Dex_Factory.sol";
import {Dex_Attacker} from "./22_Dex_Attacker.sol";

contract Dex_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	Dex_Factory factory;
	Dex instContract;
	
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
		
		factory = new Dex_Factory();
		instContract = Dex(payable(factory.createInstance(player)));
		
		vm.stopPrank();
		
		vm.deal(address(player), 101 ether);
	}
	
	function test__Solution_Dex() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_Dex -vv
		
		Dex_Attacker attacker = new Dex_Attacker(instContract);
		SwappableToken(instContract.token1()).transfer(address(attacker), 10 ether);
		SwappableToken(instContract.token2()).transfer(address(attacker), 10 ether);
		attacker.doAttack();
	}
}
