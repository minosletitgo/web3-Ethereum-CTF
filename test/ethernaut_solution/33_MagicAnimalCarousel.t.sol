// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {MagicAnimalCarousel} from "../../src/ethernaut/33_MagicAnimalCarousel/MagicAnimalCarousel.sol";
import {MagicAnimalCarousel_Factory} from "../../src/ethernaut/33_MagicAnimalCarousel/MagicAnimalCarousel_Factory.sol";
import {MagicAnimalCarousel_Attacker} from "./33_MagicAnimalCarousel_Attacker.sol";

contract MagicAnimalCarousel_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	MagicAnimalCarousel_Factory factory;
	MagicAnimalCarousel instContract;
	
	modifier checkSolvedByPlayer() {
		vm.startPrank(player, player);
		_;
		vm.stopPrank();
		_isSolved();
	}
	
	/**
	 * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
	 */
	function _isSolved() private {
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
		
		factory = new MagicAnimalCarousel_Factory();
		instContract = MagicAnimalCarousel(payable(factory.createInstance(player)));
		
		vm.stopPrank();
	}
	
	function test__Solution_MagicAnimalCarousel() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_MagicAnimalCarousel -vv
	
		MagicAnimalCarousel_Attacker attacker = new MagicAnimalCarousel_Attacker(instContract);
		attacker.doAttack();
	}
}
