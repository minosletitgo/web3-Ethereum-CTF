// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {HiddenKittyCat, House} from "../../src/eko2022/01_TheLostKitty/TheLostKitty.sol";
import {TheLostKitty_Factory} from "../../src/eko2022/01_TheLostKitty/TheLostKitty_Factory.sol";
import {TheLostKitty_Attacker} from "./01_TheLostKitty_Attacker.sol";

contract TheLostKitty_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	TheLostKitty_Factory factory;
	House instContract;
	
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
		
		factory = new TheLostKitty_Factory();
		instContract = House(factory.createInstance(player));
		
		vm.stopPrank();
		
		uint256 newBlockNumber = block.number + bound(uint256(123), uint256(1), uint256(1000));
		vm.roll(newBlockNumber);
	}
	
	function test__Solution_TheLostKitty() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_TheLostKitty -vv
		
		TheLostKitty_Attacker attacker = new TheLostKitty_Attacker(instContract);
		attacker.doAttack();
	}
}
