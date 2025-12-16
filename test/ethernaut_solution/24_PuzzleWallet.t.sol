// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {PuzzleWallet, PuzzleProxy} from "../../src/ethernaut/24_PuzzleWallet/PuzzleWallet.sol";
import {PuzzleWallet_Factory} from "../../src/ethernaut/24_PuzzleWallet/PuzzleWallet_Factory.sol";
import {PuzzleWallet_Attacker} from "./24_PuzzleWallet_Attacker.sol";

contract PuzzleWallet_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	PuzzleWallet_Factory factory;
	PuzzleWallet instContract;
	
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
		
		factory = new PuzzleWallet_Factory();
		instContract = PuzzleWallet(payable(factory.createInstance{value: 100 ether}(player)));
		
		vm.stopPrank();
		
		vm.deal(address(player), 101 ether);
	}
	
	function test__Solution_PuzzleWallet() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_PuzzleWallet -vv
		
		PuzzleWallet_Attacker puzzleWalletAttacker = new PuzzleWallet_Attacker{value: 100 ether}(PuzzleProxy(payable(address(instContract))));
		puzzleWalletAttacker.doAttack();
	}
}
