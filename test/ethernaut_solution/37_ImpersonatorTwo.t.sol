// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {ImpersonatorTwo} from "../../src/ethernaut/37_ImpersonatorTwo/ImpersonatorTwo.sol";
import {ImpersonatorTwo_Factory} from "../../src/ethernaut/37_ImpersonatorTwo/ImpersonatorTwo_Factory.sol";
import {ImpersonatorTwo_Attacker} from "./37_ImpersonatorTwo_Attacker.sol";

contract ImpersonatorTwo_Test is Test {
	address deployer = makeAddr("deployer");
	address player = 0xF16989b7A9970Ac3a117Ad45b5eCEa6CEF31f208; // makeAddr("player");

	ImpersonatorTwo_Factory factory;
	ImpersonatorTwo instContract;
	
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
		
		factory = new ImpersonatorTwo_Factory();
		instContract = ImpersonatorTwo(payable(factory.createInstance{value: 0.001 ether}(player)));
		
		vm.stopPrank();
	}
	
	function test__Solution_ImpersonatorTwo() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_ImpersonatorTwo -vv
		
		// 纯学习
		// 漏洞点：两个签名值，使用了相同的r值
		// 最终，可以破解出私钥....
		
		// Signatures generated with ImpersonatorTwo.py script
		bytes memory setAdminSig = abi.encodePacked(
			hex"e5648161e95dbf2bfc687b72b745269fa906031e2108118050aba59524a23c40", // r
			hex"701d59ccb1c72824452441d95444aa250ef592082f0f81957de7c9a7b5c14553", // s
			uint8(28) // v
		);
		bytes memory switchLockSig = abi.encodePacked(
			hex"e5648161e95dbf2bfc687b72b745269fa906031e2108118050aba59524a23c40", // r
			hex"2a04aa67c7760a7bec982fde4b387e1e62dc26ba69dd74444e68ffe28851375e", // s
			uint8(28) // v
		);
		
		instContract.setAdmin(setAdminSig, player);
		instContract.switchLock(switchLockSig);
		instContract.withdraw();
	}
}
