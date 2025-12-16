// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Mothership, SpaceShip, CleaningModule, RefuelModule, LeadershipModule} from "../../src/eko2022/02_HackTheMotherShip/HackTheMotherShip.sol";
import {HackTheMotherShip_Factory} from "../../src/eko2022/02_HackTheMotherShip/HackTheMotherShip_Factory.sol";
import {HackTheMotherShip_Attacker} from "./02_HackTheMotherShip_Attacker.sol";

contract Hack_The_MotherShip_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	HackTheMotherShip_Factory factory;
	Mothership instContract;
	
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
		
		factory = new HackTheMotherShip_Factory();
		instContract = Mothership(factory.createInstance(player));
		
		vm.stopPrank();
	}
	
	function test__Solution_HackTheMotherShip() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_HackTheMotherShip -vv
	
		HackTheMotherShip_Attacker attacker = new HackTheMotherShip_Attacker(instContract);
		attacker.doAttack();
	}
}
