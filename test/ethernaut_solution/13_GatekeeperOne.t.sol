// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {GatekeeperOne} from "../../src/ethernaut/13_GatekeeperOne/GatekeeperOne.sol";
import {GatekeeperOne_Factory} from "../../src/ethernaut/13_GatekeeperOne/GatekeeperOne_Factory.sol";
import {GatekeeperOne_Attacker} from "./13_GatekeeperOne_Attacker.sol";

contract GatekeeperOne_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	GatekeeperOne_Factory factory;
	GatekeeperOne instContract;
	
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
		
		factory = new GatekeeperOne_Factory();
		instContract = GatekeeperOne(payable(factory.createInstance(player)));
		
		vm.stopPrank();
		
		vm.deal(address(player), 101 ether);
	}
	
	function test__Solution_GatekeeperOne() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_GatekeeperOne -vv
		
		// 如何解决`Gas取模对齐`：
		// 切记：console.log 会带来`不稳定的 gas 消耗`
		// .call{gas: gasLimit}();
		// gasLimit 是指定进入目标函数后，使用的最大gas量
		// gas_entry = (call gasLimit) - overhead
		// 攻击的目的是：gas_entry % 8191 == 0
		// 能够确定的是：overhead 是相对恒定值（进入逻辑链上，环境相对固定，所以，被认为是恒定值）
		// 故，gasLimit > 8191
		// 但是，难以理解的时：gasLimit 需要大于 8191，足够多。多到一个经验值 gasLimit = 8191 * N，N 在 3~10 区间都常用。
		// 此时，gasLimit = 8191 * N + offset(用于抵消 overhead)
		
		GatekeeperOne_Attacker attacker = new GatekeeperOne_Attacker(instContract);
		attacker.doAttack();
	}
}
