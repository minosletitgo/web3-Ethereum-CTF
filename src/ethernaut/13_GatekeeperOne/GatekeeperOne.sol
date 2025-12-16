// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract GatekeeperOne {
	address public entrant;
	
	modifier gateOne() {
		require(msg.sender != tx.origin, "msg.sender != tx.origin");
		_;
	}
	
	modifier gateTwo() {
		// 切记，以下日志一旦打开，gas消耗将会发什么不可预测的波动。
		// console.log("gateTwo : gasleft()", gasleft());
		// console.log("gateTwo : gasleft() % 8191 =", gasleft() % 8191);
		require(gasleft() % 8191 == 0, "gasleft() % 8191 == 0");
		_;
	}
	
	modifier gateThree(bytes8 _gateKey) {
		require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
		require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
		require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "GatekeeperOne: invalid gateThree part three");
		_;
	}
	
	function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
		entrant = tx.origin;
		return true;
	}
}
