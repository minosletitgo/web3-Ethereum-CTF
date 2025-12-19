// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Forger} from "../../src/ethernaut/39_Forger/Forger.sol";
import {Forger_Factory} from "../../src/ethernaut/39_Forger/Forger_Factory.sol";
import {Forger_Attacker} from "./39_Forger_Attacker.sol";

contract Forger_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	Forger_Factory factory;
	Forger instContract;
	
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
		
		factory = new Forger_Factory();
		instContract = Forger(payable(factory.createInstance(player)));
		
		vm.stopPrank();
	}
	
	function test__Solution_Forger() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_Forger -vv
		
		// 本次挑战，无需关注椭圆曲线的原始算法（怪不得难度系数是●●●○○，而不是●●●●○，🥹）
		// 但是，需要非常敏锐的察觉到 "openzeppelin-contracts-v4.6.0/utils/cryptography/ECDSA.sol" 此时，容忍两种签名格式(即，65字节签名值 与 64字节签名值)
		// 该容忍会造成：同一套用户数据，表现出`2套签名值`。即，签名伪造。类似于`签名延展性的孪生兄弟`。
		// OpenZeppelin的官方仓库，修复此问题的具体时间是：Aug 11, 2022 | 4.8.0-rc.0 版本发布的前夕 | d693d89d99325f395182e4f547dbf5ff8e5c3c87
		
		console.log("instContract.totalSupply()", instContract.totalSupply());
		
		Forger_Attacker attacker = new Forger_Attacker(instContract);
		attacker.doAttack();
	}
}
