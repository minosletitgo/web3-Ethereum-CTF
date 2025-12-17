// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Forta, CryptoVault, LegacyToken, DoubleEntryPoint, DelegateERC20, IDetectionBot, IForta} from "../../src/ethernaut/26_DoubleEntryPoint/DoubleEntryPoint.sol";
import {DoubleEntryPoint_Factory} from "../../src/ethernaut/26_DoubleEntryPoint/DoubleEntryPoint_Factory.sol";
import {DoubleEntryPoint_Attacker} from "./26_DoubleEntryPoint_Attacker.sol";

contract DoubleEntryPoint_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	DoubleEntryPoint_Factory factory;
	DoubleEntryPoint instContract;
	
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
		
		factory = new DoubleEntryPoint_Factory();
		instContract = DoubleEntryPoint(payable(factory.createInstance(player)));
		
		vm.stopPrank();
		
		vm.deal(address(player), 101 ether);
	}
	
	function test__Solution_DoubleEntryPoint() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_DoubleEntryPoint -vv
	
		DoubleEntryPoint_Attacker attacker = new DoubleEntryPoint_Attacker(factory.cryptoVault(), factory.forta());
		factory.forta().setDetectionBot(address(attacker));
	}
}
