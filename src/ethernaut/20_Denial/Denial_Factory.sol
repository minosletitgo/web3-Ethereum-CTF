// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../base/Level.sol";
import {Denial} from "./Denial.sol";

import {console} from "forge-std/console.sol";

contract Denial_Factory is Level {
	uint256 public initialDeposit = 0.001 ether;
	
	function createInstance(address _player) public payable override returns (address) {
		_player; // 消除警告
		
		require(msg.value >= initialDeposit);
		instance = address(new Denial());
		address(instance).call{value: initialDeposit}("");
		
		return instance;
	}
	
	function validateInstance(address _player) public override returns (bool) {
		_player; // 消除警告
		Denial inst = Denial(payable(instance));
		
		if (inst.contractBalance() == 0) {
			console.log("inst.contractBalance() == 0");
			return false;
		}
		
		uint256 startGas = gasleft();
		try inst.withdraw{gas: 1_000_000}() {
			// 如果执行到这里，说明没有回滚 → 挑战失败
			console.log("inst.withdraw{gas: 1_000_000}()");
			return false;
		} catch {
			// 正常回滚 → 挑战成功，不输出额外信息
			// 可以什么都不做，或者输出成功信息
			uint256 gasUsed = startGas - gasleft();
			console.log("gasUsed", gasUsed);
			return true;
		}
	}
}
