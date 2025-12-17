// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../base/Level.sol";
import {HigherOrder} from "./HigherOrder.sol";

contract HigherOrder_Factory is Level {
	function createInstance(address _player) public payable override returns (address) {
		_player; // 消除警告
		
		instance = address(new HigherOrder());
		
		return instance;
	}
	
	function validateInstance(address _player) public view override returns (bool) {
		_player; // 消除警告
		HigherOrder inst = HigherOrder(payable(instance));
		return (inst.commander() != address(_player));
	}
}
