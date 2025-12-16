// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../base/Level.sol";
import {King} from "./King.sol";

contract King_Factory is Level {
	function createInstance(address _player) public payable override returns (address) {
		_player; // 消除警告
		
		instance = address(new King{value: msg.value}());
		
		return instance;
	}
	
	function validateInstance(address _player) public override returns (bool) {
		_player; // 消除警告
		King inst = King(payable(instance));
		(bool success,) = address(inst).call("");
		return (!success && inst._king() != address(this));
	}
	
	receive() external payable {}
}
